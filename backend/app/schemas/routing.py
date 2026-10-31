from pydantic import BaseModel


class LatLng(BaseModel):
    lat: float
    lng: float


class RouteRequest(BaseModel):
    origin: LatLng
    destination: LatLng | None = None
    target_shelter_code: str | None = None
    avoid_high_risk: bool = True


class RouteStep(BaseModel):
    instruction: str
    distance_m: float
    safety_status: str


class RouteResponse(BaseModel):
    origin: LatLng
    destination: LatLng
    destination_name: str
    distance_km: float
    duration_minutes: int
    hazard_status: str
    bypassed_hazard_zones: list[str]
    path: list[list[float]]
    steps: list[RouteStep]
