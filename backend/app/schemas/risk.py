from typing import Any
from pydantic import BaseModel


class LandslidePredictRequest(BaseModel):
    rainfall_24h: float
    cumulative_rainfall_7d: float | None = None
    slope: float = 35.0
    elevation: float = 1200.0
    soil_type: str | None = "clay_loam"
    historical_disasters: int | None = 1


class LandslidePredictResponse(BaseModel):
    risk_level: str
    risk_score: float
    model_used: str
    landslide_probability: float | None = None
    risk_category: str | None = None
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
