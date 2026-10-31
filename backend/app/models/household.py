from datetime import datetime

from app.database import Base
from sqlalchemy import Column, DateTime, Float, Integer, String


class Household(Base):
    __tablename__ = "households"

    id = Column(Integer, primary_key=True, index=True)
    household_code = Column(
        String(50), unique=True, index=True, nullable=False
    )
    zone_id = Column(String(50), index=True, nullable=False)
    address = Column(String(255), nullable=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    location = Column(String, nullable=True)
    elevation = Column(Float, default=1000.0)
    members_count = Column(Integer, default=1)
    elderly_count = Column(Integer, default=0)
    children_count = Column(Integer, default=0)
    disabled_count = Column(Integer, default=0)
    medical_needs = Column(
        String(255), nullable=True
    )
    vulnerability_score = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)

    def calculate_vulnerability(self) -> float:
        """
        Calculates normalized vulnerability score (0.0 to 1.0)
        Elderly weight: 0.35, Disabled: 0.40, Medical: 0.25
        """
        elderly_factor = min(self.elderly_count / 2.0, 1.0) * 0.35
        disabled_factor = min(self.disabled_count / 1.0, 1.0) * 0.40
        medical_factor = 0.25 if self.medical_needs else 0.0
        score = elderly_factor + disabled_factor + medical_factor
        return round(min(max(score, 0.1), 1.0), 2)
