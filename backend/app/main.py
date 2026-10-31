import asyncio
from contextlib import asynccontextmanager

from app.api import api_router
from app.config import settings
from app.database import Base, engine
from app.services.ml_service import load_model_at_startup
from app.services.websocket_manager import ws_manager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Create tables
Base.metadata.create_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    load_model_at_startup()
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
    allow_origins=["*"],  # Allow all for hackathon MVP
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/health")
def health_check():
    return {"status": "ok", "service": settings.PROJECT_NAME}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
# trigger reload
