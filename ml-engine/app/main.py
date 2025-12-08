from __future__ import annotations

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from .alerts import dispatcher
from .detection import engine
from .schemas import (
    AlertHistoryResponse,
    GeofenceStatus,
    Observation,
    RoutePlan,
    TrainRequest,
    TrainResponse,
)
from .storage import store
from .training import handle_training_request
from .blockchain_routes import router as blockchain_router

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

