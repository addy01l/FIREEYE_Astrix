from datetime import datetime
from app.database import Base
from sqlalchemy import Column, DateTime, Integer, String, Text


class AuditEvent(Base):
    __tablename__ = "audit_events"

    id = Column(Integer, primary_key=True, index=True)
    actor_username = Column(String(50), nullable=True, index=True)
    actor_role = Column(String(30), nullable=True)
    action = Column(String(100), nullable=False, index=True)
    resource_type = Column(String(50), nullable=True)
    resource_id = Column(String(100), nullable=True)
    details = Column(Text, nullable=True)
    status = Column(String(20), default="SUCCESS")  # SUCCESS, FAILED, WARNING
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)

