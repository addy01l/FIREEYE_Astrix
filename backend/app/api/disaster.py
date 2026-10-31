from app.database import get_db
from app.models.risk_zone import RiskZone
from app.schemas.risk import (
    LandslidePredictRequest,
    LandslidePredictResponse,
    RiskZoneResponse,
)
from app.services.ml_service import get_landslide_prediction
from app.services.websocket_manager import publish_event
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

router = APIRouter()


@router.get("/zones", response_model=list[RiskZoneResponse])
def get_risk_zones(db: Session = Depends(get_db)):
    zones = db.query(RiskZone).all()
    return zones


@router.post("/predict/landslide", response_model=LandslidePredictResponse)
async def predict_landslide(
    request: LandslidePredictRequest, db: Session = Depends(get_db)
):
    prediction = get_landslide_prediction(
        rainfall_24h=request.rainfall_24h,
        cumulative_rainfall_7d=request.cumulative_rainfall_7d
        or request.rainfall_24h * 2.2,
        slope=request.slope,
        elevation=request.elevation,
        historical_landslides=request.historical_disasters or 1,
    )


    zone = db.query(RiskZone).filter(RiskZone.zone_code == "ZONE-04-NORTH").first()
    if zone:
        old_level = zone.risk_level
        zone.risk_level = prediction["risk_level"]
        zone.risk_score = prediction["risk_score"]
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
