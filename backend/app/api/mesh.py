import asyncio
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.core.permissions import get_optional_user
from app.models.user import User
from app.models.mesh_message import MeshMessage
from app.schemas.mesh import MeshPacket, MeshPacketAck
from app.services.alerts_service import dispatch_emergency_alerts
from app.services.mesh_gateway import process_mesh_packet
from app.services.websocket_manager import publish_event

router = APIRouter()


@router.post("/packet", response_model=MeshPacketAck)
async def receive_mesh_packet(
    packet: MeshPacket,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db),
):
    """
    Ingest a store-and-forward mesh packet submitted by a hardware gateway node or relaying device.
    Performs deduplication, updates message log, and enqueues SOS when appropriate.
    """
    result = process_mesh_packet(db, packet)

    if result["action_taken"] == "SOS_ENQUEUED" and result["associated_sos_code"]:
        publish_event(
            "NEW_SOS",
            {
                "sos_code": result["associated_sos_code"],
                "severity": packet.severity,
                "via_mesh": True,
            },
        )

        asyncio.create_task(
            dispatch_emergency_alerts(
                sos_code=result["associated_sos_code"],
                severity=packet.severity,
                location_str=f"{packet.latitude}, {packet.longitude}",
                message=f"Mesh Packet received from Household {packet.household_id} with vulnerabilities: {packet.payload.vulnerabilities if packet.payload else 'None'}",
            )
        )

        try:
            from app.services.ai_assistant_service import generate_and_save_ai_analysis_task
            asyncio.create_task(
                asyncio.to_thread(
                    generate_and_save_ai_analysis_task,
                    0,
                    result["associated_sos_code"],
                )
            )
        except Exception:
            pass

    return MeshPacketAck(
        status=result["status"],
        message_id=result["message_id"],
        action_taken=result["action_taken"],
        associated_sos_code=result["associated_sos_code"],
    )


@router.get("/messages")
def list_mesh_messages(
    limit: int = Query(default=50, le=200),
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db),
):
    """List recent ingested mesh packets and store-and-forward history."""
    return (
        db.query(MeshMessage)
        .order_by(MeshMessage.received_at.desc())
        .limit(limit)
        .all()
    )
