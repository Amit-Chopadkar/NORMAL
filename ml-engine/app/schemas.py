from datetime import datetime
from typing import Dict, List, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, computed_field


RiskLevel = Literal["low", "medium", "high"]


class RoutePoint(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    eta_utc: Optional[datetime] = None


class RoutePlan(BaseModel):
    tourist_id: str
    trip_id: str
    points: List[RoutePoint]
    allowable_deviation_m: Optional[float] = None


class ObservationContext(BaseModel):
    manual_check_in: bool = False
    on_route: Optional[bool] = None
    notes: Optional[str] = None


class Observation(BaseModel):
    tourist_id: str
    trip_id: str
    timestamp: datetime
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    speed_mps: float = Field(ge=0)
    accuracy_m: float = Field(ge=0)
    battery_pct: Optional[float] = Field(default=None, ge=0, le=100)
    heading_deg: Optional[float] = Field(default=None, ge=0, le=360)
    context: ObservationContext = Field(default_factory=ObservationContext)


class DangerZone(BaseModel):
    name: str
    risk_level: RiskLevel
    advisory: Optional[str] = None
    polygon: List[List[float]]


class AlertPayload(BaseModel):
    tourist_id: str
    trip_id: str
    timestamp: datetime
    alert_type: Literal["route_deviation", "long_inactivity", "danger_zone", "anomaly"]
    severity: RiskLevel
    message: str
    metadata: Dict[str, str] = Field(default_factory=dict)

    @computed_field
    def recipients(self) -> List[str]:
        return ["tourist", "admin_panel", "family"]


class TrainRequest(BaseModel):
    retrain_with_new_data: bool = True
    persist_model: bool = True


class TrainResponse(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    trained_on_rows: int
    model_path: Optional[str]
    feature_importances: Optional[Dict[str, float]] = None


class AlertHistoryResponse(BaseModel):
    trip_id: str
    alerts: List[AlertPayload]


class GeofenceStatus(BaseModel):
    tourist_id: str
    trip_id: str
    inside_zone: bool
    zone_name: Optional[str] = None
    risk_level: Optional[RiskLevel] = None
    advisory: Optional[str] = None
    lat: float
    lng: float
    last_updated: datetime


# Safe Route Planning Models

class RoutePreferences(BaseModel):
    """User preferences for safe route calculation."""
    avoid_danger_zones: bool = True
    max_detour_pct: float = Field(default=30.0, ge=0, le=100)
    time_of_travel: Optional[datetime] = None


class DangerZoneCrossing(BaseModel):
    """Information about a danger zone crossed by a route."""
    name: str
    risk_level: RiskLevel
    advisory: Optional[str] = None


class RouteSegment(BaseModel):
    """A calculated route with safety metadata."""
    coordinates: List[RoutePoint]
    safety_score: float = Field(ge=0, le=100)
    danger_zones_crossed: List[DangerZoneCrossing]
    estimated_duration_min: float = Field(ge=0)
    distance_km: float = Field(ge=0)
    high_risk_zones: int = Field(default=0, ge=0)
    medium_risk_zones: int = Field(default=0, ge=0)
    low_risk_zones: int = Field(default=0, ge=0)


class SafeRouteRequest(BaseModel):
    """Request for safe route calculation."""
    origin: RoutePoint
    destination: RoutePoint
    tourist_id: str
    trip_id: str
    preferences: Optional[RoutePreferences] = Field(default_factory=RoutePreferences)


class SafeRouteResponse(BaseModel):
    """Response containing multiple route options with safety scores."""
    routes: List[RouteSegment]
    recommended_route_index: int = Field(ge=0)
    calculation_timestamp: datetime = Field(default_factory=datetime.now)


# LLM-Related Models

class LocationInfo(BaseModel):
    """Location information for context."""
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    name: Optional[str] = None


class ChatRequest(BaseModel):
    """Request for LLM chat interaction."""
    message: str
    tourist_id: Optional[str] = None
    trip_id: Optional[str] = None
    location: Optional[LocationInfo] = None
    context: Dict[str, str] = Field(default_factory=dict)


class ChatResponse(BaseModel):
    """Response from LLM chat."""
    response: str
    suggested_actions: List[str] = Field(default_factory=list)
    safety_score: Optional[float] = Field(default=None, ge=0, le=100)
    metadata: Dict[str, str] = Field(default_factory=dict)


class SafetyAdvisoryRequest(BaseModel):
    """Request for generating safety advisory."""
    location: LocationInfo
    time_of_day: Optional[str] = None
    user_profile: Dict[str, bool] = Field(default_factory=dict)
    current_risk_level: Optional[RiskLevel] = None


class SafetyAdvisoryResponse(BaseModel):
    """Generated safety advisory."""
    advisory_text: str
    risk_assessment: RiskLevel
    recommendations: List[str]
    danger_zones_nearby: List[str] = Field(default_factory=list)


class ItineraryRequest(BaseModel):
    """Request for itinerary suggestions."""
    destinations: List[str]
    duration_days: int = Field(ge=1, le=30)
    preferences: Dict[str, str] = Field(default_factory=dict)
    current_location: Optional[LocationInfo] = None


class ItineraryResponse(BaseModel):
    """Generated itinerary with safety considerations."""
    itinerary_text: str
    daily_plan: List[Dict[str, str]]
    overall_safety_score: float = Field(ge=0, le=100)
    safety_notes: List[str] = Field(default_factory=list)


class LLMHealthResponse(BaseModel):
    """LLM service health status."""
    status: str
    model: str
    ollama_available: bool
    error: Optional[str] = None


# Enhanced Anomaly Detection Models

class AnomalyExplanationRequest(BaseModel):
    """Request for anomaly explanation."""
    anomaly_type: str
    anomaly_data: Dict[str, str]
    observation: Optional[Dict[str, str]] = None
    context: Dict[str, str] = Field(default_factory=dict)


class AnomalyExplanationResponse(BaseModel):
    """LLM-generated anomaly explanation."""
    explanation: str
    severity: RiskLevel
    recommended_actions: List[str] = Field(default_factory=list)


class DistressAssessmentRequest(BaseModel):
    """Request for distress probability assessment."""
    tourist_id: str
    trip_id: str
    current_observation: Dict[str, str]
    recent_alerts: List[Dict[str, str]] = Field(default_factory=list)


class DistressAssessmentResponse(BaseModel):
    """Distress probability assessment."""
    distress_score: float = Field(ge=0, le=100)
    risk_level: RiskLevel
    warning_signals: List[str]
    assessment_text: str
    recommended_actions: List[str]
    priority: str  # CRITICAL, HIGH, MEDIUM, LOW


class InvestigationRequest(BaseModel):
    """Request for investigation report."""
    tourist_id: str
    trip_id: str
    incident_type: str = "anomaly"
    hours_of_history: int = Field(default=24, ge=1, le=168)


class InvestigationReportResponse(BaseModel):
    """Generated investigation report."""
    full_report: str
    sections: Dict[str, str]
    tourist_id: str
    trip_id: str
    incident_type: str
    generated_at: str


class BehavioralPatternResponse(BaseModel):
    """Behavioral pattern analysis."""
    tourist_id: str
    trip_id: str
    baseline: Dict[str, str]
    recent_patterns: List[Dict[str, str]]
    anomalies_detected: List[str]
    risk_assessment: RiskLevel

