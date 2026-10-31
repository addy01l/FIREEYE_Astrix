from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.risk_zone import RiskZone
from app.schemas.risk import (
    IntelligencePipelineRequest,
    IntelligencePipelineResponse,
    LandslidePredictRequest,
    LandslidePredictResponse,
    RiskZoneResponse,
)
from app.services.intelligence_pipeline import run_intelligence_pipeline
from app.services.ml_service import get_landslide_prediction
from app.services.websocket_manager import publish_event

router = APIRouter()


@router.get("/zones", response_model=list[RiskZoneResponse])
def get_risk_zones(db: Session = Depends(get_db)):
    """Retrieve all monitored disaster zones and their current hazard status."""
    return db.query(RiskZone).all()


@router.post("/predict/landslide", response_model=LandslidePredictResponse)
async def predict_landslide(
    request: LandslidePredictRequest, db: Session = Depends(get_db)
):
    """
    Run Random Forest model inference for landslide risk prediction.
    Supports both fireeye-ai-final features (rainfall_mm, slope_degrees, elevation_m, soil_type)
    and legacy parameters with calibrated class probabilities.
    """
    prediction = get_landslide_prediction(
        rainfall_mm=request.rainfall_mm,
        slope_degrees=request.slope_degrees,
        elevation_m=request.elevation_m,
        soil_type=request.soil_type,
        rainfall_24h=request.rainfall_24h,
        slope=request.slope,
        elevation=request.elevation,
        cumulative_rainfall_7d=request.cumulative_rainfall_7d,
        historical_disasters=request.historical_disasters,
    )

    # Automatically synchronize active demo zone risk status
    zone = db.query(RiskZone).filter(RiskZone.zone_code == "ZONE-04-NORTH").first()
    if zone:
        old_level = zone.risk_level
        zone.risk_level = prediction["risk_level"]
        zone.risk_score = prediction["risk_score"]
        if request.rainfall_mm is not None:
            zone.rainfall_24h = request.rainfall_mm
        elif request.rainfall_24h is not None:
            zone.rainfall_24h = request.rainfall_24h
        db.commit()

        if old_level != zone.risk_level:
            publish_event(
                "ZONE_RISK_UPDATED",
                {
                    "zone_code": zone.zone_code,
                    "new_level": zone.risk_level,
                    "risk_score": zone.risk_score,
                },
            )

    return prediction


@router.post("/pipeline", response_model=IntelligencePipelineResponse)
def execute_intelligence_pipeline(req: IntelligencePipelineRequest):
    """
    Executes the FIRE-EYE Unified Intelligence Pipeline:
    1. Predicts environmental hazard risk from geological data
    2. Dynamically injects risk score into active SOS requests
    3. Computes multi-factor priority triage ordering
    4. Evaluates shortest safe road route avoiding blocked sectors
    """
    try:
        blocked = [tuple(r) for r in req.blocked_roads] if req.blocked_roads else None
        result = run_intelligence_pipeline(
            environmental_data=req.environmental_data,
            sos_requests=req.sos_requests,
            road_network=req.road_network,
            rescue_base=req.rescue_base,
            destination=req.destination,
            blocked_roads=blocked,
        )
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
