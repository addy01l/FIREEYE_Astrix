from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class UserRegister(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6)
    email: EmailStr | None = None
    role: str = "CITIZEN"  # CITIZEN, RESCUE, VOLUNTEER, ADMIN
    full_name: str | None = None
    phone: str | None = None


class UserLogin(BaseModel):
    username: str
    password: str


class TokenRefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"
    role: str
    username: str
    user_id: int | None = None


class UserResponse(BaseModel):
    id: int
    username: str
    email: str | None = None
    role: str
    full_name: str | None = None
    phone: str | None = None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True
