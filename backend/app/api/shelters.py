from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from app.core.permissions import UserRole, require_roles, get_optional_user
from app.database import get_db
from app.models.shelter import Shelter
from app.models.user import User
from app.schemas.shelter import ShelterResponse
from app.services.audit_service import record_audit_event

router = APIRouter()


class ShelterOccupancyUpdate(BaseModel):
    current_occupancy: int
    operational_status: Optional[str] = None
    is_safe: Optional[bool] = None


@router.get("/", response_model=list[ShelterResponse])
def get_shelters(db: Session = Depends(get_db)):
    """Retrieve all emergency shelters with live capacity and availability."""
    shelters = db.query(Shelter).all()
    for s in shelters:
        s.available_beds = max(0, s.capacity - s.current_occupancy)
    return shelters


@router.get("/{shelter_code}", response_model=ShelterResponse)
def get_shelter(shelter_code: str, db: Session = Depends(get_db)):
    """Retrieve details for a specific shelter."""
    shelter = db.query(Shelter).filter(Shelter.shelter_code == shelter_code).first()
    if not shelter:
        raise HTTPException(status_code=404, detail="Shelter not found")
    shelter.available_beds = max(0, shelter.capacity - shelter.current_occupancy)
    return shelter


@router.patch("/{shelter_code}/occupancy", response_model=ShelterResponse)
def update_shelter_occupancy(
    shelter_code: str,
    update_in: ShelterOccupancyUpdate,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db),
):
    """Update shelter occupancy, operational status, or safety condition."""
    shelter = db.query(Shelter).filter(Shelter.shelter_code == shelter_code).first()
    if not shelter:
        raise HTTPException(status_code=404, detail="Shelter not found")

    shelter.current_occupancy = max(0, update_in.current_occupancy)
    if update_in.operational_status:
        shelter.operational_status = update_in.operational_status
    if update_in.is_safe is not None:
        shelter.is_safe = update_in.is_safe

    db.commit()
    db.refresh(shelter)
    shelter.available_beds = max(0, shelter.capacity - shelter.current_occupancy)

    record_audit_event(
        db=db,
        action="SHELTER_OCCUPANCY_UPDATED",
        actor_username=current_user.username if current_user else "RESPONDER",
        actor_role=current_user.role if current_user else "RESCUE",
        resource_type="SHELTER",
        resource_id=shelter.shelter_code,
        details=f"Occupancy: {shelter.current_occupancy}/{shelter.capacity}",
    )

    return shelter
