from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional

from app.core.permissions import UserRole, require_roles, get_optional_user
from app.database import get_db
from app.models.household import Household
from app.models.user import User
from app.schemas.household import HouseholdResponse
from app.services.audit_service import record_audit_event
from pydantic import BaseModel

router = APIRouter()


class HouseholdCreate(BaseModel):
    household_code: str
    zone_id: str
    address: str | None = None
    latitude: float
    longitude: float
    elevation: float = 1000.0
    members_count: int = 1
    elderly_count: int = 0
    children_count: int = 0
    disabled_count: int = 0
    medical_needs: str | None = None


@router.get("/", response_model=list[HouseholdResponse])
def get_households(
    zone_id: Optional[str] = None,
    min_vulnerability: float = 0.0,
    current_user: User = Depends(require_roles([UserRole.RESCUE, UserRole.ADMIN])),
    db: Session = Depends(get_db),
):
    """Retrieve list of registered vulnerable households, with optional zone and vulnerability filters."""
    query = db.query(Household)
    if zone_id:
        query = query.filter(Household.zone_id == zone_id)
    if min_vulnerability > 0.0:
        query = query.filter(Household.vulnerability_score >= min_vulnerability)
    return query.all()


@router.get("/{household_code}", response_model=HouseholdResponse)
def get_household_by_code(
    household_code: str,
    current_user: User = Depends(require_roles([UserRole.RESCUE, UserRole.ADMIN])),
    db: Session = Depends(get_db),
):
    """Retrieve details for a single household by its code."""
    hh = (
        db.query(Household)
        .filter(Household.household_code == household_code)
        .first()
    )
    if not hh:
        raise HTTPException(status_code=404, detail="Household not found")
    return hh


@router.post("/", response_model=HouseholdResponse, status_code=status.HTTP_201_CREATED)
def create_household(
    hh_in: HouseholdCreate,
    current_user: User = Depends(require_roles([UserRole.RESCUE, UserRole.ADMIN])),
    db: Session = Depends(get_db),
):
    """Register a new household record with computed vulnerability scoring."""
    existing = (
        db.query(Household)
        .filter(Household.household_code == hh_in.household_code)
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Household code already registered",
        )

    household = Household(
        household_code=hh_in.household_code,
        zone_id=hh_in.zone_id,
        address=hh_in.address,
        latitude=hh_in.latitude,
        longitude=hh_in.longitude,
        elevation=hh_in.elevation,
        members_count=hh_in.members_count,
        elderly_count=hh_in.elderly_count,
        children_count=hh_in.children_count,
        disabled_count=hh_in.disabled_count,
        medical_needs=hh_in.medical_needs,
    )
    household.vulnerability_score = household.calculate_vulnerability()

    db.add(household)
    db.commit()
    db.refresh(household)

    record_audit_event(
        db=db,
        action="HOUSEHOLD_REGISTERED",
        actor_username=current_user.username if current_user else "REGISTRAR",
        actor_role=current_user.role if current_user else "ADMIN",
        resource_type="HOUSEHOLD",
        resource_id=household.household_code,
        details=f"Vulnerability Score: {household.vulnerability_score}",
    )

    return household
