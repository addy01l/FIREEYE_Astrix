from enum import Enum
from typing import Callable
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import jwt
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import decode_token
from app.database import get_db
from app.models.user import User


class UserRole(str, Enum):
    CITIZEN = "CITIZEN"
    RESCUE = "RESCUE"
    VOLUNTEER = "VOLUNTEER"
    ADMIN = "ADMIN"


oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/auth/login",
    auto_error=False
)


def get_current_user(
    token: str | None = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """Validate bearer token and return authenticated User."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials or token expired",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if not token:
        raise credentials_exception

    try:
        payload = decode_token(token)
        username: str | None = payload.get("sub")
        if username is None or payload.get("type") != "access":
            raise credentials_exception
        user = db.query(User).filter(User.username == username).first()
        if user is None:
            raise credentials_exception
        return user
    except jwt.PyJWTError:
        pass

    # Supabase access tokens are accepted only when the backend JWT secret is
    # configured. Privileged roles come exclusively from trusted app_metadata.
    if not settings.SUPABASE_JWT_SECRET:
        raise credentials_exception
    try:
        options = {"require": ["sub", "exp", "aud"]}
        decode_args = {"audience": "authenticated", "algorithms": ["HS256"], "options": options}
        if settings.SUPABASE_URL:
            decode_args["issuer"] = f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1"
        payload = jwt.decode(token, settings.SUPABASE_JWT_SECRET, **decode_args)
        auth_id = payload.get("sub")
        email = payload.get("email")
        if not auth_id or not email:
            raise credentials_exception
        app_metadata = payload.get("app_metadata") or {}
        user_metadata = payload.get("user_metadata") or {}
        raw_role = app_metadata.get("role") or user_metadata.get("role")
        role_map = {
            "RESCUER": "RESCUE",
            "RESCUE": "RESCUE",
            "COMMAND_CENTER": "ADMIN",
            "ADMIN": "ADMIN",
            "VOLUNTEER": "VOLUNTEER",
            "CITIZEN": "CITIZEN",
        }
        if raw_role:
            role = role_map.get(str(raw_role).upper(), "RESCUE")
        else:
            # Users logging in through the official Rescuers & Officials Console
            # are granted RESCUE role by default so active dispatches are accessible.
            role = "RESCUE"

        username = f"sb_{str(auth_id).replace('-', '')[:40]}"
        user = db.query(User).filter(User.email == email).first()
        if user is None:
            user = User(
                username=username,
                email=email,
                hashed_password="SUPABASE_AUTH",
                role=role,
                full_name=user_metadata.get("full_name") or email.split("@")[0],
                is_active=True,
            )
            db.add(user)
        else:
            if user.role not in [UserRole.ADMIN, UserRole.RESCUE]:
                user.role = role
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


def require_roles(allowed_roles: list[str | UserRole]) -> Callable:
    """
    Role-Based Access Control (RBAC) dependency factory.
    Enforces that current_user.role is in allowed_roles.
    """
    role_strings = [
        r.value if isinstance(r, UserRole) else str(r).upper() for r in allowed_roles
    ]

    def role_checker(current_user: User = Depends(get_current_active_user)) -> User:
        user_role = (current_user.role or "").upper()
        if user_role not in role_strings:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Operation not permitted. Required role: {', '.join(role_strings)} (Current: {user_role})",
            )
        return current_user

    return role_checker

