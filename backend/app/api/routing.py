from app.database import get_db
from app.schemas.routing import RouteRequest, RouteResponse
from app.services.routing_engine import generate_safe_evacuation_route
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

router = APIRouter()


@router.post("/safe-route", response_model=RouteResponse)
def get_safe_route(route_req: RouteRequest, db: Session = Depends(get_db)):
    return generate_safe_evacuation_route(
        db=db,
        origin_lat=route_req.origin.lat,
        origin_lng=route_req.origin.lng,
        dest_lat=route_req.destination.lat if route_req.destination else None,
        dest_lng=route_req.destination.lng if route_req.destination else None,
        target_shelter_code=route_req.target_shelter_code,
        avoid_high_risk=route_req.avoid_high_risk,
    )
