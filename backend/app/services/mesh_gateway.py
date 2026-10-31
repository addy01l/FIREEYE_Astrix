import uuid
from typing import Any
import logging

from app.models.mesh_message import MeshMessage
from app.models.sos import SOSRequest
from app.schemas.mesh import MeshPacket
from app.services.ml_service import predict_risk_at_location
from app.services.priority_engine import calculate_priority_score
from sqlalchemy.orm import Session

logger = logging.getLogger("fire-eye.mesh")


def process_mesh_packet(db: Session, packet: MeshPacket) -> dict[str, Any]:
    """
    Ingests an offline store-and-forward mesh packet received by the gateway.
    Implements multi-layer deduplication (Redis cache + PostgreSQL/SQLite persistence),
    TTL validation, and idempotent mapping to SOS records.
    """
    # 1. Check database for duplicate message ID (primary source of truth)
    existing_msg = (
        db.query(MeshMessage)
        .filter(MeshMessage.message_id == packet.message_id)
        .first()
    )
    if existing_msg:
        logger.info(f"Duplicate mesh packet {packet.message_id} dropped via DB check.")
        return {
            "status": "DUPLICATE_DROPPED",
            "message_id": packet.message_id,
            "action_taken": "Ignored",
            "associated_sos_code": None,
        }

    # Optional Redis fast-path check
    try:
        from app.redis_client import redis_client
        redis_key = f"mesh_seen:{packet.message_id}"
        if redis_client is not None:
            if redis_client.exists(redis_key):
                return {
                    "status": "DUPLICATE_DROPPED",
                    "message_id": packet.message_id,
                    "action_taken": "Ignored",
                    "associated_sos_code": None,
                }
            redis_client.set(redis_key, "seen", ex=86400)
    except Exception as e:
        logger.debug(f"Redis unavailable, relying on database deduplication: {e}")

    # 2. TTL Verification
    if packet.ttl < 0:
        return {
            "status": "TTL_EXPIRED",
            "message_id": packet.message_id,
            "action_taken": "Dropped",
            "associated_sos_code": None,
        }

    # 3. Store Mesh Packet
    mesh_entry = MeshMessage(
        message_id=packet.message_id,
        sender_id=packet.sender_id,
        message_type=packet.type,
        household_code=packet.household_id,
        latitude=packet.latitude,
        longitude=packet.longitude,
        severity=packet.severity,
        ttl=packet.ttl,
        hops_trail=str(packet.hops),
        raw_payload=packet.payload.model_dump_json() if packet.payload else None,
        sync_state="PROCESSED" if packet.type == "SOS" else "RECEIVED",
    )
    db.add(mesh_entry)
    db.flush()

    # 4. Generate SOS Request if it's an SOS packet
    associated_sos_code = None
    if packet.type == "SOS":
        # Check if active SOS already exists for this household to avoid dups
        existing_sos = None
        if packet.household_id:
            existing_sos = (
                db.query(SOSRequest)
                .filter(
                    SOSRequest.household_code == packet.household_id,
                    SOSRequest.status.in_(["PENDING", "ASSIGNED", "DISPATCHED"]),
                )
                .first()
            )

        if not existing_sos:
            sos_code = f"SOS-MESH-{str(uuid.uuid4())[:6].upper()}"

            # Predict Risk & Calculate Priority
            ml_risk = predict_risk_at_location(packet.latitude, packet.longitude)

            vuln_score = 0.5
            if packet.payload and packet.payload.vulnerabilities:
                vuln_score = 0.85

            scores = calculate_priority_score(
                severity=packet.severity,
                vulnerability_score=vuln_score,
                zone_risk_score=0.5,
                isolation_score=0.75,
                time_decay=0.0,
                medical_urgency=0.0,
                ml_risk=ml_risk,
            )

            notes = f"Mesh Hop Count: {len(packet.hops)}. Trail: {' -> '.join(packet.hops)}"
            if packet.payload and packet.payload.vulnerabilities:
                notes += f" | Needs: {', '.join(packet.payload.vulnerabilities)}"

            new_sos = SOSRequest(
                sos_code=sos_code,
                household_code=packet.household_id,
                sender_device_id=packet.sender_id,
                latitude=packet.latitude,
                longitude=packet.longitude,
                emergency_type="MESH_EMERGENCY",
                severity=packet.severity,
                status="PENDING",
                priority_score=scores["total_score"],
                notes=notes,
                via_mesh="TRUE",
                hops_count=len(packet.hops),
                source_type="MESH_GATEWAY",
            )
            db.add(new_sos)
            db.commit()
            db.refresh(new_sos)
            associated_sos_code = new_sos.sos_code
            action_taken = "SOS_ENQUEUED"
        else:
            db.commit()
            associated_sos_code = existing_sos.sos_code
            action_taken = "ATTACHED_TO_EXISTING_SOS"
    else:
        db.commit()
        action_taken = "PACKET_RECORDED"

    return {
        "status": "ACCEPTED",
        "message_id": packet.message_id,
        "action_taken": action_taken,
        "associated_sos_code": associated_sos_code,
    }
