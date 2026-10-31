from datetime import datetime
from pydantic import BaseModel


class PriorityQueueItem(BaseModel):
    sos_id: int
    sos_code: str
    household_code: str | None = None
    rank: int
    priority_score: float
    priority_level: str | None = "MEDIUM"
    breakdown: dict[str, float] | None = None
    severity: str
    severity_component: float
    vulnerability_component: float
    risk_component: float
    isolation_component: float
    latitude: float
    longitude: float
    emergency_type: str
    status: str
    elderly_count: int = 0
    disabled_count: int = 0
    medical_needs: str | None = None
    source_type: str | None = "MOBILE"
    via_mesh: str | None = "FALSE"
    hops_count: int | None = 0
    notes: str | None = None
    created_at: datetime


PriorityItem = PriorityQueueItem


class PriorityQueueResponse(BaseModel):
    total_active_sos: int
    queue: list[PriorityQueueItem]
