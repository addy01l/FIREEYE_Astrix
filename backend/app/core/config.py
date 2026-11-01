import os
from pathlib import Path
from pydantic_settings import BaseSettings

# Base directories
BASE_DIR = Path(__file__).resolve().parent.parent.parent
ML_DIR = BASE_DIR.parent / "ml"

class Settings(BaseSettings):
    PROJECT_NAME: str = "FIRE-EYE Disaster Response Engine"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DATABASE_URL: str = os.getenv("DATABASE_URL", f"sqlite:///{BASE_DIR}/sql_app.db")
    
    # JWT & Auth
    SECRET_KEY: str = os.getenv("SECRET_KEY", "development-only-change-this-secret")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours
    REFRESH_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    SUPABASE_URL: str | None = os.getenv("SUPABASE_URL")
    SUPABASE_JWT_SECRET: str | None = os.getenv("SUPABASE_JWT_SECRET")
    ADMIN_BOOTSTRAP_UUID: str = os.getenv("ADMIN_BOOTSTRAP_UUID", "7900f312-14ea-49d0-9e1b-626228307084")
    SEED_DEMO_DATA: bool = os.getenv("SEED_DEMO_DATA", "false").lower() == "true"
    
    # ML & Inference
    ML_MODEL_PATH: str = os.getenv(
        "ML_MODEL_PATH",
        str(ML_DIR / "models" / "risk_model.joblib")
    )
    
    # Mesh Network
    MESH_GATEWAY_NODE_ID: str = os.getenv("MESH_GATEWAY_NODE_ID", "GATEWAY-CENTRAL-01")
    DEFAULT_TTL: int = 8
    
    # Routing
    ORS_API_KEY: str | None = os.getenv("ORS_API_KEY")
    CORS_ALLOW_ORIGINS: str = os.getenv("CORS_ALLOW_ORIGINS", "http://localhost:3000")
    
    # Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    
    # Alert Services (Optional)
    DISCORD_WEBHOOK_URL: str | None = os.getenv("DISCORD_WEBHOOK_URL")
    TELEGRAM_BOT_TOKEN: str | None = os.getenv("TELEGRAM_BOT_TOKEN")
    TELEGRAM_CHAT_ID: str | None = os.getenv("TELEGRAM_CHAT_ID")
    FCM_SERVER_KEY: str | None = os.getenv("FCM_SERVER_KEY")

    class Config:
        case_sensitive = True
        env_file = ".env"
        extra = "allow"

settings = Settings()

