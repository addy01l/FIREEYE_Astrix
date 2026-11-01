from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.permissions import require_admin
from app.database import get_db
from app.models.profile import Profile
from app.models.user import User
from app.schemas.auth import UserResponse
from app.services.audit_service import record_audit_event

router = APIRouter()


class UserRoleUpdate(BaseModel):
    role: str = Field(..., description="Role to assign: 'admin' or 'user'")


class UserStatusUpdate(BaseModel):
    is_active: bool


@router.get("/", response_model=list[UserResponse])
def list_all_users(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """
    [ADMIN ONLY] List all registered users across the platform.
    Requires ADMIN authority.
    """
    return db.query(User).offset(skip).limit(limit).all()


@router.get("/{user_id}", response_model=UserResponse)
def get_user_by_id(
    user_id: str,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """[ADMIN ONLY] Retrieve details for a specific user."""
    query = db.query(User)
    if user_id.isdigit():
        target = query.filter(User.id == int(user_id)).first()
    else:
        target = query.filter((User.supabase_uid == user_id) | (User.username == user_id)).first()

    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    return target


@router.patch("/{user_id}/role", response_model=UserResponse)
def update_user_role(
    user_id: str,
    role_update: UserRoleUpdate,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """
    [ADMIN ONLY] Securely update a user's role (admin or user).
    Records an authoritative audit event with actor, target, old role, new role, and timestamp.
    """
    new_role = role_update.role.lower().strip()
    if new_role not in ["admin", "user"]:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Role must be either 'admin' or 'user'",
        )

    query = db.query(User)
    if user_id.isdigit():
        target_user = query.filter(User.id == int(user_id)).first()
    else:
        target_user = query.filter((User.supabase_uid == user_id) | (User.username == user_id)).first()

    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    old_role = target_user.role
    target_user.role = new_role

    # Update persistent Profile table
    uid = target_user.supabase_uid
    if uid:
        profile = db.query(Profile).filter(Profile.id == uid).first()
        if profile:
            profile.role = new_role
        else:
            db.add(Profile(id=uid, role=new_role))

    db.commit()
    db.refresh(target_user)

    record_audit_event(
        db=db,
        action="USER_ROLE_CHANGED",
        actor_username=current_user.username,
        actor_role=current_user.role,
        resource_type="USER",
        resource_id=str(target_user.id),
        details=f"Admin {current_user.username} changed {target_user.username}'s role from {old_role} to {new_role}",
    )

    return target_user


@router.patch("/{user_id}/status", response_model=UserResponse)
def update_user_status(
    user_id: str,
    status_update: UserStatusUpdate,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """[ADMIN ONLY] Activate or deactivate a user account."""
    query = db.query(User)
    if user_id.isdigit():
        target_user = query.filter(User.id == int(user_id)).first()
    else:
        target_user = query.filter((User.supabase_uid == user_id) | (User.username == user_id)).first()

    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    target_user.is_active = status_update.is_active
    db.commit()
    db.refresh(target_user)

    record_audit_event(
        db=db,
        action="USER_STATUS_UPDATED",
        actor_username=current_user.username,
        actor_role=current_user.role,
        resource_type="USER",
        resource_id=str(target_user.id),
        details=f"User active status changed to {status_update.is_active}",
    )

    return target_user
