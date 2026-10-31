from app.database import Base
from sqlalchemy import Boolean, Column, Float, Integer, String


class Shelter(Base):
    __tablename__ = "shelters"

    id = Column(Integer, primary_key=True, index=True)
    shelter_code = Column(String(50), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    facility_type = Column(String(50), default="SHELTER")
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    location = Column(String(255), nullable=True)
    capacity = Column(Integer, default=100)
    current_occupancy = Column(Integer, default=0)
    operational_status = Column(String(30), default="OPERATIONAL")  # OPERATIONAL, FULL, CLOSED
    has_medical_staff = Column(Boolean, default=True)
    has_power_backup = Column(Boolean, default=True)
    has_oxygen = Column(Boolean, default=True)
    is_safe = Column(Boolean, default=True)
    contact_phone = Column(String(20), nullable=True)
