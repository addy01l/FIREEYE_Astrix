from datetime import datetime
from app.database import Base
from sqlalchemy import Column, DateTime, Float, Integer, String, Text


class MeshMessage(Base):
    __tablename__ = "mesh_messages"

    id = Column(Integer, primary_key=True, index=True)
    message_id = Column(String(100), unique=True, index=True, nullable=False)
    sender_id = Column(String(50), nullable=False)
    message_type = Column(String(30), default="SOS")
    household_code = Column(String(50), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    severity = Column(String(20), nullable=True)
    ttl = Column(Integer, default=8)
    hops_trail = Column(Text, nullable=True)
    raw_payload = Column(Text, nullable=True)
    sync_state = Column(String(30), default="RECEIVED")  # RECEIVED, PROCESSED, FORWARDED
    received_at = Column(DateTime, default=datetime.utcnow)
