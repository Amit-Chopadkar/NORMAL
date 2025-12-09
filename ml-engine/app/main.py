from __future__ import annotations

import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from .alerts import dispatcher
from .detection import engine
from .schemas import (
    AlertHistoryResponse,
    GeofenceStatus,
    Observation,
    RoutePlan,
    SafeRouteRequest,
    SafeRouteResponse,
    RouteSegment,
    DangerZoneCrossing,
    TrainRequest,
    TrainResponse,
    # LLM Schemas
    ChatRequest,
    ChatResponse,
    SafetyAdvisoryRequest,
    SafetyAdvisoryResponse,
    ItineraryRequest,
    ItineraryResponse,
    LLMHealthResponse,
    # Anomaly Detection Schemas
    AnomalyExplanationRequest,
    AnomalyExplanationResponse,
    DistressAssessmentRequest,
    DistressAssessmentResponse,
    InvestigationRequest,
    InvestigationReportResponse,
    BehavioralPatternResponse,
)
from .storage import store
from .training import handle_training_request
from .blockchain_routes import router as blockchain_router
from . import route_scoring
from .llm_service import get_llm_service
from .behavioral_analyzer import get_behavioral_analyzer

app = FastAPI(title="TourGuard ML Engine", version="1.1.0")

# Add CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include blockchain router
app.include_router(blockchain_router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/routes", status_code=201)
def register_route(plan: RoutePlan) -> dict[str, str]:
    if len(plan.points) < 2:
        raise HTTPException(status_code=400, detail="Route requires at least two points.")
    store.add_route(plan)
    return {"message": "Route stored"}


@app.post("/observations")
def ingest_observation(obs: Observation) -> dict[str, str]:
    store.add_observation(obs)
    alerts = engine.process_observation(obs)
    for alert in alerts:
        dispatcher.dispatch(alert)
    return {"message": "Observation ingested", "alerts_triggered": str(len(alerts))}


@app.post("/train", response_model=TrainResponse)
def retrain_model(payload: TrainRequest) -> TrainResponse:
    return handle_training_request(payload.retrain_with_new_data, payload.persist_model)


@app.get("/alerts/{trip_id}", response_model=AlertHistoryResponse)
def fetch_alerts(trip_id: str) -> AlertHistoryResponse:
    alerts = dispatcher.history(trip_id)
    return AlertHistoryResponse(trip_id=trip_id, alerts=alerts)


@app.get("/geofence-status", response_model=list[GeofenceStatus])
def geofence_status() -> list[GeofenceStatus]:
    return store.list_geofence_status()


@app.post("/routes/safe-route", response_model=SafeRouteResponse)
def calculate_safe_route(request: SafeRouteRequest) -> SafeRouteResponse:
    """Calculate safe route options with safety scores.
    
    This endpoint accepts origin and destination coordinates and returns
    multiple route alternatives scored for safety based on danger zones,
time of day, and historical incidents.
    
    For now, this is a simplified implementation that returns a single
    direct route with safety scoring. Future versions will integrate with
    external routing APIs (ORS/OSRM) for multiple route alternatives.
    """
    from datetime import datetime
    
    # Build simple direct route (single segment)
    # In production, this would call ORS/OSRM API for multiple alternatives
    direct_route_points = [request.origin, request.destination]
    
    # Calculate safety score for the direct route
    timestamp = request.preferences.time_of_travel if request.preferences else datetime.now()
    safety_score, metadata = route_scoring.calculate_overall_route_score(
        direct_route_points,
        timestamp
    )
    
    # Get danger zone crossings
    impact = route_scoring.get_route_safety_impact(direct_route_points)
    
    # Convert to DangerZoneCrossing objects
    crossings = [
        DangerZoneCrossing(
            name=zone["name"],
            risk_level=zone["risk_level"],  # type: ignore[arg-type]
            advisory=zone.get("advisory"),
        )
        for zone in impact["zones_crossed"]
    ]
    
    # Build route segment
    # Calculate approximate distance (simple haversine)
    from haversine import haversine, Unit
    distance_km = haversine(
        (request.origin.lat, request.origin.lng),
        (request.destination.lat, request.destination.lng),
        unit=Unit.KILOMETERS
    )
    
    # Estimate duration (assume 40 km/h average speed)
    duration_min = (distance_km / 40.0) * 60
    
    route_segment = RouteSegment(
        coordinates=direct_route_points,
        safety_score=safety_score,
        danger_zones_crossed=crossings,
        estimated_duration_min=duration_min,
        distance_km=distance_km,
        high_risk_zones=impact["high_risk_count"],
        medium_risk_zones=impact["medium_risk_count"],
        low_risk_zones=impact["low_risk_count"],
    )
    
    return SafeRouteResponse(
        routes=[route_segment],
        recommended_route_index=0,
        calculation_timestamp=datetime.now(),
    )


# ============================================================================
# LLM-Powered AI Features
# ============================================================================

@app.get("/llm/health", response_model=LLMHealthResponse)
def llm_health() -> LLMHealthResponse:
    """Check if LLM service is available and operational."""
    llm = get_llm_service()
    
    if llm.is_available():
        return LLMHealthResponse(
            status="ok",
            model=llm.model,
            ollama_available=True,
            error=None
        )
    else:
        return LLMHealthResponse(
            status="unavailable",
            model=llm.model,
            ollama_available=False,
            error="LLM service is disabled or Ollama is not running"
        )


@app.post("/llm/chat", response_model=ChatResponse)
def chat_with_assistant(request: ChatRequest) -> ChatResponse:
    """
    Conversational travel assistant for tourist queries.
    
    Provides intelligent responses about:
    - Destinations and attractions
    - Safety recommendations
    - Travel tips and local insights
    - Cultural information
    """
    llm = get_llm_service()
    
    if not llm.is_available():
        return ChatResponse(
            response="I'm currently unavailable. Please try again later.",
            suggested_actions=[],
            safety_score=None,
            metadata={"error": "LLM service unavailable"}
        )
    
    # Build context from location and other data
    location_dict = None
    if request.location:
        location_dict = {
            'lat': request.location.lat,
            'lng': request.location.lng,
            'name': request.location.name
        }
    
    # Get response from LLM
    response_text, actions, safety_score = llm.chat_travel_assistant(
        message=request.message,
        location=location_dict,
        context=request.context
    )
    
    return ChatResponse(
        response=response_text,
        suggested_actions=actions,
        safety_score=safety_score,
        metadata={
            "model": llm.model,
            "tourist_id": request.tourist_id or "anonymous"
        }
    )


@app.post("/llm/safety-advisory", response_model=SafetyAdvisoryResponse)
def generate_safety_advisory(request: SafetyAdvisoryRequest) -> SafetyAdvisoryResponse:
    """
    Generate contextual safety advisory for a specific location.
    
    Considers:
    - Current risk level of the area
    - Time of day
    - User profile (solo/group, local/foreign)
    - Nearby danger zones
    """
    llm = get_llm_service()
    
    if not llm.is_available():
        return SafetyAdvisoryResponse(
            advisory_text="Safety advisory service is currently unavailable. Please check back later.",
            risk_assessment=request.current_risk_level or "medium",
            recommendations=["Stay aware of your surroundings", "Keep emergency contacts handy"],
            danger_zones_nearby=[]
        )
    
    # Generate advisory
    advisory_text, risk_assessment, recommendations = llm.generate_safety_advisory(
        location_name=request.location.name or f"Location ({request.location.lat}, {request.location.lng})",
        risk_level=request.current_risk_level,
        time_of_day=request.time_of_day,
        user_profile=request.user_profile
    )
    
    # Check for nearby danger zones
    from .detection import engine
    nearby_zones = []
    for polygon, name, risk, advisory in engine._danger_polygons:
        from shapely.geometry import Point
        point = Point(request.location.lng, request.location.lat)
        # Check if within 1km buffer (approximate)
        if polygon.buffer(0.01).contains(point):
            nearby_zones.append(name)
    
    return SafetyAdvisoryResponse(
        advisory_text=advisory_text,
        risk_assessment=risk_assessment,
        recommendations=recommendations,
        danger_zones_nearby=nearby_zones
    )


@app.post("/llm/suggest-itinerary", response_model=ItineraryResponse)
def suggest_safe_itinerary(request: ItineraryRequest) -> ItineraryResponse:
    """
    Generate safe travel itinerary based on destinations and preferences.
    
    Creates day-by-day plans that balance:
    - Tourist interests
    - Safety considerations
    - Realistic travel times
    - Local insights
    """
    llm = get_llm_service()
    
    if not llm.is_available():
        return ItineraryResponse(
            itinerary_text="Itinerary service is currently unavailable. Please try again later.",
            daily_plan=[],
            overall_safety_score=70.0,
            safety_notes=["Service temporarily unavailable"]
        )
    
    # TODO: In the future, calculate actual safety scores for each destination
    # For now, use a default moderate-high score
    safety_scores = {dest: 75.0 for dest in request.destinations}
    
    # Generate itinerary
    itinerary_text, daily_plan, overall_safety, safety_notes = llm.suggest_itinerary(
        destinations=request.destinations,
        duration_days=request.duration_days,
        preferences=request.preferences,
        safety_scores=safety_scores
    )
    
    return ItineraryResponse(
        itinerary_text=itinerary_text,
        daily_plan=daily_plan,
        overall_safety_score=overall_safety,
        safety_notes=safety_notes
    )


# ============================================================================
# Enhanced Anomaly Detection & Investigation
# ============================================================================

@app.post("/anomaly/explain", response_model=AnomalyExplanationResponse)
def explain_anomaly(request: AnomalyExplanationRequest) -> AnomalyExplanationResponse:
    """
    Get LLM-generated explanation for detected anomalies.
    
    Provides human-readable explanations of what was detected,
    why it's concerning, possible causes, and recommended actions.
    """
    llm = get_llm_service()
    
    explanation = llm.explain_anomaly(
        anomaly_type=request.anomaly_type,
        anomaly_data=request.anomaly_data,
        observation=request.observation,
        context=request.context
    )
    
    # Determine severity from anomaly data
    severity = request.anomaly_data.get('severity', 'medium')
    if severity not in ['low', 'medium', 'high']:
        severity = 'medium'
    
    # Extract actions from explanation (simple parsing)
    actions = []
    for line in explanation.split('\n'):
        line = line.strip()
        if any(word in line.lower() for word in ['recommend', 'should', 'action', 'contact', 'alert']):
            if line.startswith('-') or line.startswith('•') or any(line.startswith(f"{i}.") for i in range(1, 10)):
                action = line.lstrip('-•0123456789. ').strip()
                if action and len(action) > 10:
                    actions.append(action)
    
    return AnomalyExplanationResponse(
        explanation=explanation,
        severity=severity,  # type: ignore
        recommended_actions=actions[:5]
    )


@app.post("/anomaly/assess-distress", response_model=DistressAssessmentResponse)
def assess_distress(request: DistressAssessmentRequest) -> DistressAssessmentResponse:
    """
    Assess distress probability based on multiple warning signals.
    
    Combines behavioral analysis, location context, and alert history
    to calculate distress probability and provide intervention recommendations.
    """
    llm = get_llm_service()
    analyzer = get_behavioral_analyzer()
    
    # Get observation history
    history = analyzer.get_observation_history(
        request.tourist_id,
        request.trip_id,
        hours=2
    )
    
    # Convert string dict to Observation-like dict for assessment
    obs_dict = {
        'lat': float(request.current_observation.get('lat', 0)),
        'lng': float(request.current_observation.get('lng', 0)),
        'timestamp': request.current_observation.get('timestamp', ''),
        'speed_mps': float(request.current_observation.get('speed_mps', 0)),
        'battery_pct': float(request.current_observation.get('battery_pct', 50)),
        'accuracy_m': float(request.current_observation.get('accuracy_m', 10)),
    }
    
    # Create mock Observation for distress assessment
    from .schemas import Observation as ObsModel, ObservationContext
    from datetime import datetime
    
    try:
        mock_obs = ObsModel(
            tourist_id=request.tourist_id,
            trip_id=request.trip_id,
            timestamp=datetime.fromisoformat(obs_dict['timestamp']) if obs_dict['timestamp'] else datetime.now(),
            lat=obs_dict['lat'],
            lng=obs_dict['lng'],
            speed_mps=obs_dict['speed_mps'],
            accuracy_m=obs_dict['accuracy_m'],
            battery_pct=obs_dict['battery_pct'],
            context=ObservationContext()
        )
        
        # Calculate distress score
        distress_score, risk_level, signals = analyzer.assess_distress_signals(
            mock_obs,
            request.recent_alerts,
            history
        )
        
        # Get LLM assessment
        assessment_text, actions, priority = llm.assess_distress_probability(
            signals=signals,
            distress_score=distress_score,
            observation=obs_dict,
            history_summary={'observations_count': len(history)} if history else None
        )
        
        return DistressAssessmentResponse(
            distress_score=distress_score,
            risk_level=risk_level,  # type: ignore
            warning_signals=signals,
            assessment_text=assessment_text,
            recommended_actions=actions,
            priority=priority
        )
        
    except Exception as e:
        # Fallback response
        return DistressAssessmentResponse(
            distress_score=50.0,
            risk_level="medium",
            warning_signals=["Error processing distress assessment"],
            assessment_text=f"Unable to complete full assessment: {str(e)}. Manual review recommended.",
            recommended_actions=["Contact tourist", "Review data manually", "Alert supervisor"],
            priority="MEDIUM"
        )


@app.post("/investigation/analyze", response_model=InvestigationReportResponse)
def generate_investigation_report(request: InvestigationRequest) -> InvestigationReportResponse:
    """
    Generate comprehensive AI-powered investigation report.
    
    Creates detailed timeline reconstruction, behavioral analysis,
    scenario assessment, and actionable recommendations for investigators.
    """
    llm = get_llm_service()
    analyzer = get_behavioral_analyzer()
    
    # Get observation history
    history = analyzer.get_observation_history(
        request.tourist_id,
        request.trip_id,
        hours=request.hours_of_history
    )
    
    # Convert observations to dicts
    obs_dicts = []
    for obs in history:
        obs_dicts.append({
            'timestamp': obs.timestamp.isoformat() if hasattr(obs.timestamp, 'isoformat') else str(obs.timestamp),
            'lat': obs.lat,
            'lng': obs.lng,
            'speed_mps': obs.speed_mps,
            'battery_pct': obs.battery_pct,
            'accuracy_m': obs.accuracy_m
        })
    
    # Get alerts from history
    alerts_response = dispatcher.history(request.trip_id)
    alert_dicts = []
    for alert in alerts_response:
        alert_dicts.append({
            'timestamp': alert.timestamp.isoformat() if hasattr(alert.timestamp, 'isoformat') else str(alert.timestamp),
            'alert_type': alert.alert_type,
            'message': alert.message,
            'severity': alert.severity
        })
    
    # Generate report
    report = llm.generate_investigation_report(
        tourist_id=request.tourist_id,
        trip_id=request.trip_id,
        observations=obs_dicts,
        alerts=alert_dicts,
        incident_type=request.incident_type
    )
    
    return InvestigationReportResponse(**report)


@app.get("/observations/{tourist_id}/{trip_id}/patterns", response_model=BehavioralPatternResponse)
def get_behavioral_patterns(tourist_id: str, trip_id: str) -> BehavioralPatternResponse:
    """
    Retrieve behavioral pattern analysis for a tourist.
    
    Returns baseline behavior, recent patterns, detected anomalies,
    and overall risk assessment.
    """
    analyzer = get_behavioral_analyzer()
    
    # Get baseline
    baseline = analyzer.get_behavioral_baseline(tourist_id, trip_id)
    
    # Get recent history
    history = analyzer.get_observation_history(tourist_id, trip_id, hours=6)
    
    # Analyze patterns
    anomalies = []
    patterns = []
    
    if history:
        # Check for various anomalies
        latest_obs = history[-1]
        
        # Location dropoff
        dropoff = analyzer.detect_location_dropoff(latest_obs, history)
        if dropoff:
            anomalies.append(f"{dropoff['type']}: {dropoff['message']}")
        
        # Movement pattern
        movement = analyzer.analyze_movement_pattern(latest_obs, history)
        if movement:
            anomalies.append(f"{movement['type']}: {movement['message']}")
        
        # Build pattern summary
        speeds = [obs.speed_mps * 3.6 for obs in history if obs.speed_mps > 0]
        if speeds:
            patterns.append({
                'type': 'speed_pattern',
                'average_kmh': str(np.mean(speeds)),
                'max_kmh': str(max(speeds)),
                'observations': str(len(history))
            })
        
        # Assess distress
        distress_score, risk_level, _ = analyzer.assess_distress_signals(latest_obs, [], history)
    else:
        risk_level = 'low'
    
    return BehavioralPatternResponse(
        tourist_id=tourist_id,
        trip_id=trip_id,
        baseline={k: str(v) for k, v in baseline.items()},
        recent_patterns=patterns,
        anomalies_detected=anomalies,
        risk_assessment=risk_level  # type: ignore
    )

