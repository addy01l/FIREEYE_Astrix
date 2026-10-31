from typing import Any
from pydantic import BaseModel


class LandslidePredictRequest(BaseModel):
    # Support both fireeye-ai-final schema and legacy names
    rainfall_mm: float | None = None
    slope_degrees: float | None = None
    elevation_m: float | None = None
    soil_type: str | None = "Clay"

    rainfall_24h: float | None = None
    cumulative_rainfall_7d: float | None = None
    slope: float | None = None
    elevation: float | None = None
    historical_disasters: int | None = 1


class LandslidePredictResponse(BaseModel):
    risk_level: str
    risk_score: float
    model_used: str
    landslide_probability: float | None = None
    risk_category: str | None = None
    class_probabilities: dict[str, float] | None = None
    features_used: Any | None = None
    disclaimer: str | None = None


class RiskZoneResponse(BaseModel):
    zone_code: str
    name: str
    risk_level: str
    risk_score: float
    rainfall_24h: float
    slope: float
    elevation: float
    population: int
    vulnerable_population: int
    center_lat: float
    center_lng: float
    polygon_geojson: str | None = None


class IntelligencePipelineRequest(BaseModel):
    environmental_data: dict[str, Any]
    sos_requests: list[dict[str, Any]]
    road_network: dict[str, dict[str, float]]
    rescue_base: str
    destination: str
    blocked_roads: list[list[str]] | None = None


class IntelligencePipelineResponse(BaseModel):
    risk_assessment: dict[str, Any]
    risk_score_used_for_priority: float
    ranked_rescue_requests: list[dict[str, Any]]
    route_plan: dict[str, Any]
