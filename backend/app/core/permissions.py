from enum import Enum
from typing import Callable
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import jwt
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import decode_token
from app.database import get_db
from app.models.profile import Profile
from app.models.user import User


class UserRole(str, Enum):
    ADMIN = "ADMIN"
    USER = "USER"
    CITIZEN = "CITIZEN"
    RESCUE = "RESCUE"
    VOLUNTEER = "VOLUNTEER"
    COMMANDER = "COMMANDER"


ADMIN_ROLES = {"admin", "commander", "rescue"}
USER_ROLES = {"user", "citizen", "volunteer"}

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/auth/login",
    auto_error=False
)


def get_current_user(
    token: str | None = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    Validate bearer token (Internal FastAPI JWT or Supabase Auth JWT)
    and return authenticated User with authoritative database role.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials or token expired",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if not token:
        raise credentials_exception

    # 1. Attempt decode as internal JWT
    try:
        payload = decode_token(token)
        username: str | None = payload.get("sub")
        if username and payload.get("type") == "access":
            user = db.query(User).filter(User.username == username).first()
            if user:
                return user
    except jwt.PyJWTError:
        pass

    # 2. Attempt decode as Supabase JWT
    if not settings.SUPABASE_JWT_SECRET:
        raise credentials_exception

    try:
        options = {"require": ["sub", "exp", "aud"]}
        decode_args = {
            "audience": "authenticated",
            "algorithms": ["HS256"],
            "options": options,
        }
        if settings.SUPABASE_URL:
            decode_args["issuer"] = f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1"

        payload = jwt.decode(token, settings.SUPABASE_JWT_SECRET, **decode_args)
        auth_id = str(payload.get("sub") or "")
        email = payload.get("email")
        if not auth_id or not email:
            raise credentials_exception

        # Authoritative role resolution from public.profiles table in DB
        profile = db.query(Profile).filter(Profile.id == auth_id).first()
        if profile:
            authoritative_role = profile.role.lower()
        elif auth_id == settings.ADMIN_BOOTSTRAP_UUID:
            authoritative_role = "admin"
            new_profile = Profile(id=auth_id, role="admin")
            db.add(new_profile)
            try:
                db.commit()
            except Exception:
                db.rollback()
        else:
            authoritative_role = "user"
            new_profile = Profile(id=auth_id, role="user")
            db.add(new_profile)
            try:
                db.commit()
            except Exception:
                db.rollback()

        # Sync local User record with authoritative role
        username = f"sb_{auth_id.replace('-', '')[:40]}"
        user = db.query(User).filter(
            (User.supabase_uid == auth_id) | (User.email == email)
        ).first()

        if user is None:
            user = User(
                supabase_uid=auth_id,
                username=username,
                email=email,
                hashed_password="SUPABASE_AUTH",
                role=authoritative_role,
                full_name=(payload.get("user_metadata") or {}).get("full_name") or email.split("@")[0],
                is_active=True,
            )
            db.add(user)
        else:
            user.supabase_uid = auth_id
            user.role = authoritative_role
            user.is_active = True

        db.commit()
        db.refresh(user)
        return user
    except jwt.PyJWTError:
        raise credentials_exception


def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Ensure the authenticated user is active."""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user account"
        )
    return current_user


def get_optional_user(
    token: str | None = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User | None:
    """Extract user if token provided, but do not fail if unauthenticated."""
    if not token:
        return None
    try:
        return get_current_user(token=token, db=db)
    except HTTPException:
        return None


def require_admin(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """Enforce that current authenticated user has ADMIN role."""
    role_norm = (current_user.role or "").lower().strip()
    if role_norm not in ADMIN_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required"
        )
    return current_user


def require_user(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """Enforce authenticated active user."""
    return current_user


def require_roles(allowed_roles: list[str | UserRole]) -> Callable:
    """
    Role-Based Access Control (RBAC) dependency factory.
    Enforces that current_user.role is in allowed_roles (case-insensitive).
    """
    role_strings = set()
    for r in allowed_roles:
        val = (r.value if isinstance(r, UserRole) else str(r)).lower().strip()
        role_strings.add(val)
        if val in ADMIN_ROLES:
            role_strings.update(ADMIN_ROLES)
        if val in USER_ROLES:
            role_strings.update(USER_ROLES)

    def role_checker(current_user: User = Depends(get_current_active_user)) -> User:
        user_role = (current_user.role or "").lower().strip()
        # Admin has superuser authority across all operations
        if user_role in ADMIN_ROLES:
            return current_user
        if user_role not in role_strings:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Operation not permitted. Required role: {', '.join(sorted(role_strings))} (Current: {user_role})",
            )
        return current_user

    return role_checker
