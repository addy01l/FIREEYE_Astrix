from datetime import datetime
from pydantic import BaseModel


class SOSCreate(BaseModel):
    household_code: str | None = None
    sender_device_id: str | None = "MOBILE-CLIENT"
    latitude: float
    longitude: float
    emergency_type: str = "LANDSLIDE_TRAPPED"
    severity: str = "HIGH"  # CRITICAL, HIGH, MEDIUM, LOW
    notes: str | None = None
    via_mesh: str | None = "FALSE"
    idempotency_key: str | None = None


class SOSStatusUpdate(BaseModel):
    status: str  # PENDING, ASSIGNED, DISPATCHED, RESCUED, CANCELLED
    assigned_team_id: str | None = None
    assigned_shelter_id: str | None = None
    notes: str | None = None


class SOSAssignRequest(BaseModel):
    team_name: str
    responder_id: int | None = None
    responder_username: str | None = None
    notes: str | None = None


class SOSResponse(BaseModel):
    id: int
    sos_code: str
    idempotency_key: str | None = None
    user_id: int | None = None
    household_code: str | None = None
    sender_device_id: str | None = None
    latitude: float
    longitude: float
    emergency_type: str
    severity: str
    status: str
    priority_score: float
    notes: str | None = None
    assigned_team_id: str | None = None
    assigned_shelter_id: str | None = None
    via_mesh: str | None = "FALSE"
    hops_count: int | None = 0
    created_at: datetime
    resolved_at: datetime | None = None

    class Config:
        from_attributes = True
