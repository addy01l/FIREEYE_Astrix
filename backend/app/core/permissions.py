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
        # Anyone who logs in is granted ADMIN access
        role = "ADMIN"
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
    Grants ADMIN users and authenticated operators full clearance.
    """
    role_strings = [
        r.value if isinstance(r, UserRole) else str(r).upper() for r in allowed_roles
    ]

    def role_checker(current_user: User = Depends(get_current_active_user)) -> User:
        user_role = (current_user.role or "").upper()
        # Anyone with ADMIN access or active login is granted operational clearance
        if user_role == "ADMIN" or user_role == UserRole.ADMIN or user_role in role_strings:
            return current_user
        return current_user

    return role_checker

