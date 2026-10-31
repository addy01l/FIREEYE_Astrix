from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.core.permissions import UserRole, require_roles
from app.database import get_db
from app.models.audit_event import AuditEvent
from app.schemas.audit import AuditEventResponse

router = APIRouter()


@router.get("/events", response_model=list[AuditEventResponse])
def get_audit_events(
    limit: int = Query(default=100, le=500),
    action: Optional[str] = None,
    actor: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """Retrieve system audit trail records (Admin / Oversight)."""
    query = db.query(AuditEvent)
    if action:
        query = query.filter(AuditEvent.action == action)
    if actor:
        query = query.filter(AuditEvent.actor_username == actor)
    return query.order_by(AuditEvent.timestamp.desc()).limit(limit).all()

