from datetime import datetime
from app.database import Base
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text


class RescueAssignment(Base):
    __tablename__ = "rescue_assignments"

    id = Column(Integer, primary_key=True, index=True)
    sos_id = Column(Integer, ForeignKey("sos_requests.id"), nullable=False, index=True)
    sos_code = Column(String(50), index=True, nullable=False)
    responder_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    responder_username = Column(String(50), nullable=True)
    team_name = Column(String(100), nullable=True)
    status = Column(
        String(30), default="ASSIGNED"
    )  # ASSIGNED, EN_ROUTE, ON_SCENE, COMPLETED, CANCELLED
    assigned_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)

