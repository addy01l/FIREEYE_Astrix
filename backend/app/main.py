import asyncio
from contextlib import asynccontextmanager

from app.api import api_router
from app.config import settings
from app.database import Base, SessionLocal, engine
from app.seeds.seed_data import seed_hackathon_demo_data
from app.services.ml_service import load_model_at_startup
from app.services.websocket_manager import ws_manager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Create tables
Base.metadata.create_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    if settings.ENVIRONMENT.lower() == "production":
        if settings.SECRET_KEY == "development-only-change-this-secret":
            raise RuntimeError("SECRET_KEY must be set to a unique production value")
        if not settings.SUPABASE_URL or not settings.SUPABASE_JWT_SECRET:
            raise RuntimeError("SUPABASE_URL and SUPABASE_JWT_SECRET are required in production")
    load_model_at_startup()
    if settings.SEED_DEMO_DATA:
        try:
            db = SessionLocal()
            seed_hackathon_demo_data(db)
            db.close()
        except Exception as e:
            print(f"[FIRE-EYE SEED INFO] Seed check: {e}")
    ws_manager._heartbeat_task = asyncio.create_task(ws_manager.start_heartbeat())
    ws_manager._pubsub_task = asyncio.create_task(ws_manager.start_redis_subscriber())
    yield
    # Shutdown
    if ws_manager._heartbeat_task:
        ws_manager._heartbeat_task.cancel()
    if ws_manager._pubsub_task:
        ws_manager._pubsub_task.cancel()


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    description="FIRE-EYE Inclusive & Fault-Tolerant Disaster Response System API",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS config
app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin.strip() for origin in settings.CORS_ALLOW_ORIGINS.split(",") if origin.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/health")
def health_check():
    redis_status = "disconnected"
    try:
        from app.redis_client import redis_client
        if redis_client is not None and redis_client.ping():
            redis_status = "connected"
    except Exception:
        redis_status = "unreachable"

    return {
        "status": "ok",
        "service": settings.PROJECT_NAME,
        "redis": redis_status,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
