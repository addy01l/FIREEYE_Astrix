from datetime import datetime
from app.database import Base
from sqlalchemy import Boolean, Column, DateTime, Integer, String, Text


class SOSAIAnalysis(Base):
    __tablename__ = "sos_ai_analyses"

    id = Column(Integer, primary_key=True, index=True)
    sos_code = Column(String(50), unique=True, index=True, nullable=False)
    incident_summary = Column(Text, nullable=False)
    identified_risk_factors = Column(Text, nullable=False)  # JSON-serialized list
    recommended_rescue_actions = Column(Text, nullable=False)  # JSON-serialized list
    required_rescue_resources = Column(Text, nullable=False)  # JSON-serialized list
    suggested_urgency_level = Column(String(20), nullable=False)  # CRITICAL, HIGH, MEDIUM, LOW
    model_used = Column(String(50), default="groq-openai/gpt-oss-120b")
    reviewed_by_human = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
