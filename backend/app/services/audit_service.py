import logging
from sqlalchemy.orm import Session
from app.models.audit_event import AuditEvent

logger = logging.getLogger("fire-eye.audit")


def record_audit_event(
    db: Session,
    action: str,
    actor_username: str | None = None,
    actor_role: str | None = None,
    resource_type: str | None = None,
    resource_id: str | None = None,
    details: str | None = None,
    status: str = "SUCCESS",
) -> AuditEvent:
    """Record an audit trail event in the database."""
    try:
        event = AuditEvent(
            actor_username=actor_username or "SYSTEM",
            actor_role=actor_role or "SYSTEM",
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details,
            status=status,
        )
        db.add(event)
        db.commit()
        db.refresh(event)
        return event
    except Exception as e:
        logger.error(f"Failed to record audit event: {e}")
        db.rollback()
        return None

