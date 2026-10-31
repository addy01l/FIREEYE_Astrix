from datetime import datetime
from pydantic import BaseModel


class RescueAssignmentCreate(BaseModel):
    sos_id: int
    sos_code: str
    responder_id: int | None = None
    responder_username: str | None = None
    team_name: str
    notes: str | None = None


class RescueAssignmentUpdate(BaseModel):
    status: str  # ASSIGNED, EN_ROUTE, ON_SCENE, COMPLETED, CANCELLED
    notes: str | None = None


class RescueAssignmentResponse(BaseModel):
    id: int
    sos_id: int
    sos_code: str
    responder_id: int | None = None
    responder_username: str | None = None
    team_name: str | None = None
    status: str
    assigned_at: datetime
    completed_at: datetime | None = None
    notes: str | None = None

    class Config:
        from_attributes = True

