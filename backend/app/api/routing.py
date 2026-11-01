from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.routing import (
    NetworkRouteRequest,
    NetworkRouteResponse,
    RouteRequest,
    RouteResponse,
)
from app.services.routing_engine import (
    generate_safe_evacuation_route,
    shortest_route,
)

router = APIRouter()


@router.post("/safe-route", response_model=RouteResponse)
def get_safe_route(route_req: RouteRequest, db: Session = Depends(get_db)):
    """
    Generate an evacuation road route avoiding high-risk hazard zones.
    If the routing service is unavailable, provides an explicit degraded fallback.
    """
    try:
        return generate_safe_evacuation_route(
            db=db,
            origin_lat=route_req.origin.lat,
            origin_lng=route_req.origin.lng,
            dest_lat=route_req.destination.lat if route_req.destination else None,
            dest_lng=route_req.destination.lng if route_req.destination else None,
            target_shelter_code=route_req.target_shelter_code,
            avoid_high_risk=route_req.avoid_high_risk,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc


@router.post("/network-route", response_model=NetworkRouteResponse)
def get_network_route(req: NetworkRouteRequest):
    """
    Topological route optimizer using Dijkstra's shortest path algorithm
    on a designated road network graph with blocked hazard road segment avoidance.
    """
    try:
        blocked = [tuple(r) for r in req.blocked_roads] if req.blocked_roads else None
        return shortest_route(
            graph=req.graph,
            start=req.start,
            destination=req.destination,
            blocked_roads=blocked,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
