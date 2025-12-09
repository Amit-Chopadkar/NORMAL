"""
Behavioral Analysis Module for TourGuard ML Engine

Analyzes tourist behavioral patterns to detect anomalies,
assess distress probability, and support investigation.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from collections import defaultdict

import numpy as np
from haversine import haversine, Unit

from .schemas import Observation
from .config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class BehavioralAnalyzer:
    """Analyzes tourist behavior patterns for anomaly detection."""
    
    def __init__(self):
        # Store behavioral baselines per tourist
        self._baselines: Dict[str, Dict] = {}
        # Store recent observation history
        self._history: Dict[str, List[Observation]] = defaultdict(list)
        # Maximum history to keep (24 hours of observations)
        self._max_history_hours = 24
    
    def add_observation(self, obs: Observation) -> None:
        """Add observation to history for pattern analysis."""
        key = f"{obs.tourist_id}::{obs.trip_id}"
        
        # Add to history
        self._history[key].append(obs)
        
        # Prune old observations (keep last 24 hours)
        cutoff = obs.timestamp - timedelta(hours=self._max_history_hours)
        self._history[key] = [
            o for o in self._history[key]
            if o.timestamp >= cutoff
        ]
    
    def get_observation_history(
        self,
        tourist_id: str,
        trip_id: str,
        hours: int = 24
    ) -> List[Observation]:
        """Get observation history for a tourist."""
        key = f"{tourist_id}::{trip_id}"
        history = self._history.get(key, [])
        
        if not history:
            return []
        
        # Filter by time window
        latest = history[-1].timestamp
        cutoff = latest - timedelta(hours=hours)
        return [obs for obs in history if obs.timestamp >= cutoff]
    
    def detect_location_dropoff(
        self,
        obs: Observation,
        history: Optional[List[Observation]] = None
    ) -> Optional[Dict]:
        """
        Detect sudden GPS signal loss or location jumps.
        
        Returns:
            Dict with anomaly details if detected, None otherwise
        """
        if history is None:
            history = self.get_observation_history(obs.tourist_id, obs.trip_id, hours=1)
        
        if len(history) < 2:
            return None
        
        prev_obs = history[-1]
        
        # Check 1: Sudden accuracy degradation
        if obs.accuracy_m > 100 and prev_obs.accuracy_m < 30:
            return {
                'type': 'accuracy_degradation',
                'severity': 'medium',
                'previous_accuracy': prev_obs.accuracy_m,
                'current_accuracy': obs.accuracy_m,
                'message': f'GPS accuracy degraded from {prev_obs.accuracy_m:.0f}m to {obs.accuracy_m:.0f}m'
            }
        
        # Check 2: Location jump (teleportation)
        time_diff = (obs.timestamp - prev_obs.timestamp).total_seconds()
        if time_diff > 0:
            distance_km = haversine(
                (prev_obs.lat, prev_obs.lng),
                (obs.lat, obs.lng),
                unit=Unit.KILOMETERS
            )
            distance_m = distance_km * 1000
            
            # If moved >500m in <30 seconds, flag it
            if time_diff < 30 and distance_m > 500:
                speed_kmh = (distance_km / time_diff) * 3600
                return {
                    'type': 'location_jump',
                    'severity': 'high',
                    'distance_m': distance_m,
                    'time_sec': time_diff,
                    'implied_speed_kmh': speed_kmh,
                    'message': f'Location jumped {distance_m:.0f}m in {time_diff:.0f}s (impossible speed: {speed_kmh:.0f} km/h)'
                }
        
        # Check 3: Signal loss (implemented at storage level)
        # This would be detected by lack of observations
        
        return None
    
    def analyze_movement_pattern(
        self,
        obs: Observation,
        history: Optional[List[Observation]] = None
    ) -> Optional[Dict]:
        """
        Analyze movement patterns for anomalies.
        
        Detects: erratic movement, unusual speeds, backtracking, circling
        """
        if history is None:
            history = self.get_observation_history(obs.tourist_id, obs.trip_id, hours=2)
        
        if len(history) < 5:
            return None  # Need at least 5 points for pattern analysis
        
        recent = history[-5:]  # Last 5 observations
        
        # Calculate movement metrics
        speeds = []
        directions = []
        distances = []
        
        for i in range(1, len(recent)):
            prev = recent[i-1]
            curr = recent[i]
            
            time_diff = (curr.timestamp - prev.timestamp).total_seconds()
            if time_diff > 0:
                dist_km = haversine(
                    (prev.lat, prev.lng),
                    (curr.lat, curr.lng),
                    unit=Unit.KILOMETERS
                )
                speed_kmh = (dist_km / time_diff) * 3600
                speeds.append(speed_kmh)
                distances.append(dist_km * 1000)  # meters
                
                # Calculate direction change
                if i > 1:
                    # Simple direction estimate based on lat/lng changes
                    dx1 = recent[i-1].lng - recent[i-2].lng
                    dy1 = recent[i-1].lat - recent[i-2].lat
                    dx2 = curr.lng - prev.lng
                    dy2 = curr.lat - prev.lat
                    
                    # Angle between vectors (simplified)
                    if dx1 != 0 or dy1 != 0:
                        directions.append((dx2 - dx1, dy2 - dy1))
        
        if not speeds:
            return None
        
        # Anomaly 1: Erratic speed changes
        speed_variance = np.var(speeds) if len(speeds) > 1 else 0
        avg_speed = np.mean(speeds)
        
        if speed_variance > 100 and avg_speed > 5:  # High variance, not stationary
            return {
                'type': 'erratic_movement',
                'severity': 'low',
                'avg_speed_kmh': avg_speed,
                'speed_variance': speed_variance,
                'message': f'Erratic movement detected (speed variance: {speed_variance:.1f}, avg: {avg_speed:.1f} km/h)'
            }
        
        # Anomaly 2: Unusually high speed
        max_speed = max(speeds)
        if max_speed > 60:  # Unrealistic for tourist on foot/vehicle in these areas
            return {
                'type': 'high_speed',
                'severity': 'medium',
                'max_speed_kmh': max_speed,
                'message': f'Unusually high speed detected: {max_speed:.1f} km/h'
            }
        
        # Anomaly 3: Backtracking pattern
        total_distance = sum(distances)
        straight_line_dist = haversine(
            (recent[0].lat, recent[0].lng),
            (recent[-1].lat, recent[-1].lng),
            unit=Unit.METERS
        )
        
        if total_distance > 0:
            efficiency = straight_line_dist / total_distance
            if efficiency < 0.3 and total_distance > 200:  # Very inefficient path
                return {
                    'type': 'backtracking',
                    'severity': 'low',
                    'efficiency': efficiency,
                    'total_distance_m': total_distance,
                    'straight_line_m': straight_line_dist,
                    'message': f'Backtracking detected (path efficiency: {efficiency:.1%})'
                }
        
        return None
    
    def assess_distress_signals(
        self,
        obs: Observation,
        alerts: List[Dict],
        history: Optional[List[Observation]] = None
    ) -> Tuple[float, str, List[str]]:
        """
        Assess distress probability based on multiple signals.
        
        Returns:
            Tuple of (probability 0-100, risk_level, signal_list)
        """
        if history is None:
            history = self.get_observation_history(obs.tourist_id, obs.trip_id, hours=2)
        
        signals = []
        score = 0.0
        
        # Signal 1: Time of day (night = higher risk)
        hour = obs.timestamp.hour
        if 22 <= hour or hour <= 5:
            signals.append("Night time travel (10 PM - 5 AM)")
            score += 15
        
        # Signal 2: Active alerts
        if alerts:
            alert_types = {a.get('type', a.get('alert_type', '')) for a in alerts}
            
            if 'danger_zone' in alert_types:
                signals.append("Currently in danger zone")
                score += 25
            
            if 'route_deviation' in alert_types:
                signals.append("Deviated from planned route")
                score += 15
            
            if 'long_inactivity' in alert_types:
                signals.append("Prolonged inactivity detected")
                score += 20
            
            if 'location_jump' in alert_types or 'accuracy_degradation' in alert_types:
                signals.append("GPS signal issues")
                score += 10
        
        # Signal 3: Battery level
        if obs.battery_pct and obs.battery_pct < 20:
            signals.append(f"Low battery ({obs.battery_pct:.0f}%)")
            score += 10
        
        # Signal 4: Rapid battery drain (if we have history)
        if len(history) >= 3:
            # Check battery drop over last hour
            hour_ago_obs = [o for o in history if (obs.timestamp - o.timestamp).total_seconds() < 3600]
            if hour_ago_obs and hour_ago_obs[0].battery_pct:
                battery_drop = hour_ago_obs[0].battery_pct - (obs.battery_pct or 0)
                if battery_drop > 30:
                    signals.append(f"Rapid battery drain ({battery_drop:.0f}% in 1 hour)")
                    score += 15
        
        # Signal 5: Remote location with poor GPS
        if obs.accuracy_m > 50:
            signals.append(f"Poor GPS accuracy ({obs.accuracy_m:.0f}m)")
            score += 5
        
        # Signal 6: Unusual speed (very slow or very fast)
        if obs.speed_mps < 0.1:  # Nearly stationary
            signals.append("No movement detected")
            score += 5
        elif obs.speed_mps > 15:  # >54 km/h
            signals.append(f"Very high speed ({obs.speed_mps * 3.6:.0f} km/h)")
            score += 10
        
        # Calculate risk level
        if score >= 60:
            risk_level = "high"
        elif score >= 30:
            risk_level = "medium"
        else:
            risk_level = "low"
        
        return (min(score, 100), risk_level, signals)
    
    def get_behavioral_baseline(self, tourist_id: str, trip_id: str) -> Dict:
        """Get or create behavioral baseline for a tourist."""
        key = f"{tourist_id}::{trip_id}"
        
        if key in self._baselines:
            return self._baselines[key]
        
        # Create new baseline from history
        history = self.get_observation_history(tourist_id, trip_id, hours=24)
        
        if not history:
            # Default baseline
            baseline = {
                'avg_speed_kmh': 4.0,
                'typical_hours': list(range(8, 22)),  # 8 AM - 10 PM
                'max_inactivity_min': 30,
                'created_at': datetime.now()
            }
        else:
            # Calculate from history
            speeds = []
            hours = set()
            
            for obs in history:
                if obs.speed_mps > 0:
                    speeds.append(obs.speed_mps * 3.6)  # Convert to km/h
                hours.add(obs.timestamp.hour)
            
            baseline = {
                'avg_speed_kmh': np.mean(speeds) if speeds else 4.0,
                'typical_hours': sorted(hours),
                'max_inactivity_min': 30,
                'created_at': datetime.now()
            }
        
        self._baselines[key] = baseline
        return baseline


# Singleton instance
_analyzer: Optional[BehavioralAnalyzer] = None


def get_behavioral_analyzer() -> BehavioralAnalyzer:
    """Get or create behavioral analyzer singleton."""
    global _analyzer
    if _analyzer is None:
        _analyzer = BehavioralAnalyzer()
    return _analyzer
