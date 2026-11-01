from datetime import datetime
from app.database import Base
from sqlalchemy import Column, DateTime, String


class Profile(Base):
    __tablename__ = "profiles"

    id = Column(String(64), primary_key=True)  # UUID from auth.users
    role = Column(String(20), default="user", nullable=False)  # 'admin', 'user'
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
