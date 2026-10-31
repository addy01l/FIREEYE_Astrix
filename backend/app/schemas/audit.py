from datetime import datetime
from pydantic import BaseModel


class AuditEventCreate(BaseModel):
    actor_username: str | None = None
    actor_role: str | None = None
    action: str
    resource_type: str | None = None
    resource_id: str | None = None
    details: str | None = None
    status: str = "SUCCESS"


class AuditEventResponse(BaseModel):
    id: int
    actor_username: str | None = None
    actor_role: str | None = None
    action: str
    resource_type: str | None = None
    resource_id: str | None = None
    details: str | None = None
    status: str
    timestamp: datetime

    class Config:
        from_attributes = True

