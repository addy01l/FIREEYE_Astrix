from pydantic import BaseModel


class ShelterResponse(BaseModel):
    id: int
    shelter_code: str
    name: str
    facility_type: str
    latitude: float
    longitude: float
    capacity: int
    current_occupancy: int
    available_beds: int
    has_medical_staff: bool
    has_power_backup: bool
    has_oxygen: bool
    is_safe: bool
    contact_phone: str | None = None

    class Config:
        from_attributes = True
