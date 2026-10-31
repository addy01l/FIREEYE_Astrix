from app.api import (
    audit,
    auth,
    disaster,
    households,
    mesh,
    priority,
    routing,
    shelters,
    sos,
    websocket,
)
from fastapi import APIRouter

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(
    disaster.router, prefix="/disaster", tags=["Disaster Risk & Prediction"]
)
api_router.include_router(
    households.router, prefix="/households", tags=["Vulnerable Households"]
)
api_router.include_router(sos.router, prefix="/sos", tags=["Emergency SOS"])
api_router.include_router(
    priority.router, prefix="/priority", tags=["Rescue Priority Engine"]
)
api_router.include_router(
    routing.router, prefix="/routing", tags=["Evacuation Routing"]
)
api_router.include_router(
    shelters.router, prefix="/shelters", tags=["Shelters & Resources"]
)
api_router.include_router(mesh.router, prefix="/mesh", tags=["Offline Mesh Gateway"])
api_router.include_router(audit.router, prefix="/audit", tags=["Audit Trail"])
api_router.include_router(websocket.router, prefix="/ws", tags=["Real-time WebSockets"])
