from __future__ import annotations

from datetime import datetime, timedelta
from typing import List, Optional, Tuple

from haversine import Unit, haversine
from shapely import geometry
from shapely.geometry import Point, shape
import joblib
import numpy as np

from .config import get_settings
from .schemas import AlertPayload, GeofenceStatus, Observation, RoutePlan
from .storage import store
from .training import ModelBundle, load_or_train_model


settings = get_settings()


def distance_m(a: Tuple[float, float], b: Tuple[float, float]) -> float:
    return haversine(a, b, unit=Unit.METERS)


def min_distance_to_route(obs: Observation, plan: RoutePlan) -> float:
    observed = (obs.lat, obs.lng)
    coords = [(p.lat, p.lng) for p in plan.points]
    if len(coords) < 2:
        return distance_m(observed, coords[0])
    return min(distance_m(observed, pt) for pt in coords)


class DetectionEngine:
    def __init__(self) -> None:
        self.model_bundle: ModelBundle = load_or_train_model()
        self._danger_polygons = self._load_danger_zones()
        self._last_motion: dict[str, datetime] = {}

    def _load_danger_zones(self) -> List[Tuple[geometry.Polygon, str, str, str]]:
        danger_features: List[Tuple[geometry.Polygon, str, str, str]] = []
        path = settings.danger_zones_path
        if not path.exists():
            return danger_features

        import json

        with path.open() as f:
            data = json.load(f)
            for feature in data.get("features", []):
                geom = shape(feature["geometry"])
                props = feature.get("properties", {})
                danger_features.append(
                    (
                        geom,
                        props.get("name", "Danger Zone"),
                        props.get("risk_level", "medium"),
                        props.get("advisory", ""),
                    )
                )
        return danger_features

    def process_observation(self, obs: Observation) -> List[AlertPayload]:
        alerts: List[AlertPayload] = []
        route = store.get_route(obs.tourist_id, obs.trip_id)
        deviation_threshold = (
            route.allowable_deviation_m
            if route and route.allowable_deviation_m is not None
            else settings.route_deviation_threshold_m
        )

        # Import and use behavioral analyzer
        from .behavioral_analyzer import get_behavioral_analyzer
        analyzer = get_behavioral_analyzer()
        
        # Add observation to behavioral history
        analyzer.add_observation(obs)
        history = analyzer.get_observation_history(obs.tourist_id, obs.trip_id, hours=2)

        # Check 1: Route deviation (existing)
        if route:
            deviation_m = min_distance_to_route(obs, route)
            if deviation_m > deviation_threshold:
                alerts.append(
                    self._build_alert(
                        obs,
                        "route_deviation",
                        "medium",
                        f"Off planned route by {int(deviation_m)} m.",
                        {"route_threshold_m": str(deviation_threshold)},
                    )
                )

        # Check 2: Inactivity (existing)
        inactivity_alert = self._check_inactivity(obs)
        if inactivity_alert:
            alerts.append(inactivity_alert)

        # Check 3: Danger zone (existing)
        danger_alert = self._check_danger_zone(obs)
        if danger_alert:
            alerts.append(danger_alert)

        # Check 4: Basic anomaly (existing Isolation Forest)
        anomaly_alert = self._anomaly_score(obs)
        if anomaly_alert:
            alerts.append(anomaly_alert)

        # NEW Check 5: Location dropoff detection
        dropoff = analyzer.detect_location_dropoff(obs, history)
        if dropoff:
            alerts.append(
                self._build_alert(
                    obs,
                    dropoff['type'],
                    dropoff['severity'],
                    dropoff['message'],
                    {k: str(v) for k, v in dropoff.items() if k not in ['type', 'severity', 'message']},
                )
            )

        # NEW Check 6: Movement pattern analysis
        movement_anomaly = analyzer.analyze_movement_pattern(obs, history)
        if movement_anomaly:
            alerts.append(
                self._build_alert(
                    obs,
                    movement_anomaly['type'],
                    movement_anomaly['severity'],
                    movement_anomaly['message'],
                    {k: str(v) for k, v in movement_anomaly.items() if k not in ['type', 'severity', 'message']},
                )
            )

        # Record alerts and return
        dispatched = []
        for alert in alerts:
            if store.record_alert(alert):
                dispatched.append(alert)
        return dispatched

    def _check_inactivity(self, obs: Observation) -> Optional[AlertPayload]:
        key = f"{obs.tourist_id}::{obs.trip_id}"
        last_motion = self._last_motion.get(key, obs.timestamp)
        if obs.speed_mps > 0.4:
            self._last_motion[key] = obs.timestamp
            return None

        threshold = timedelta(minutes=settings.inactivity_threshold_minutes)
        if obs.timestamp - last_motion > threshold:
            return self._build_alert(
                obs,
                "long_inactivity",
                "medium",
                f"No movement detected for {settings.inactivity_threshold_minutes}+ minutes.",
                {},
            )
        return None

    def _check_danger_zone(self, obs: Observation) -> Optional[AlertPayload]:
        zone = self._detect_zone(obs)
        status = GeofenceStatus(
            tourist_id=obs.tourist_id,
            trip_id=obs.trip_id,
            inside_zone=zone is not None,
            zone_name=zone["name"] if zone else None,
            risk_level=zone["risk"] if zone else None,
            advisory=zone["advisory"] if zone else None,
            lat=obs.lat,
            lng=obs.lng,
            last_updated=obs.timestamp,
        )
        store.update_geofence_status(status)

        if zone:
            return self._build_alert(
                obs,
                "danger_zone",
                zone["risk"],  # type: ignore[arg-type]
                f"Entered {zone['name']}. {zone['advisory']}",
                {"zone": zone["name"]},
            )
        return None

    def _detect_zone(self, obs: Observation) -> Optional[dict[str, str]]:
        point = Point(obs.lng, obs.lat)
        for polygon, name, risk, advisory in self._danger_polygons:
            if polygon.contains(point):
                return {"name": name, "risk": risk, "advisory": advisory}
        return None

    def _anomaly_score(self, obs: Observation) -> Optional[AlertPayload]:
        features = np.array(
            [
                [
                    obs.speed_mps,
                    obs.accuracy_m,
                    obs.battery_pct or 50,
                ]
            ]
        )
        model = self.model_bundle.model
        score = model.decision_function(features)[0]
        if score < -0.1:
            return self._build_alert(
                obs,
                "anomaly",
                "low",
                f"Unexpected motion pattern score={score:.2f}",
                {},
            )
        return None

    @staticmethod
    def _build_alert(
        obs: Observation,
        alert_type: str,
        severity: str,
        message: str,
        metadata: dict[str, str],
    ) -> AlertPayload:
        return AlertPayload(
            tourist_id=obs.tourist_id,
            trip_id=obs.trip_id,
            timestamp=obs.timestamp,
            alert_type=alert_type,  # type: ignore[arg-type]
            severity=severity,  # type: ignore[arg-type]
            message=message,
            metadata=metadata,
        )


engine = DetectionEngine()

