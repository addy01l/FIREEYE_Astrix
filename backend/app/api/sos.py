from datetime import datetime
import uuid
from typing import Optional
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.permissions import (
    UserRole,
    get_current_active_user,
    get_optional_user,
    require_roles,
)
from app.database import get_db
from app.models.household import Household
from app.models.rescue_assignment import RescueAssignment
from app.models.sos import SOSRequest
from app.models.user import User
from app.schemas.mesh import MeshPacket, MeshPacketAck
from app.schemas.rescue_assignment import RescueAssignmentResponse
from app.schemas.sos import (
    SOSAssignRequest,
    SOSCreate,
    SOSResponse,
    SOSStatusUpdate,
)
from app.services.audit_service import record_audit_event
from app.services.mesh_gateway import process_mesh_packet
from app.services.priority_engine import compute_ranked_rescue_queue
from app.services.websocket_manager import publish_event

router = APIRouter()


@router.post("/", response_model=SOSResponse, status_code=status.HTTP_201_CREATED)
async def create_sos(
    sos_in: SOSCreate,
    background_tasks: BackgroundTasks,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db),
):
    """
    Create an Emergency SOS request.
    Idempotent: If an SOS with the same idempotency_key already exists, returns the existing record.
    """
    if sos_in.idempotency_key:
        existing_sos = (
            db.query(SOSRequest)
            .filter(SOSRequest.idempotency_key == sos_in.idempotency_key)
            .first()
        )
        if existing_sos:
            return existing_sos

    sos_code = f"SOS-WEB-{str(uuid.uuid4())[:6].upper()}"

    # Calculate dynamic priority score using official FIRE-EYE algorithm:
    # Score = severity*0.40 + vulnerability*0.30 + risk*0.20 + isolation*0.10
    sev_str = (sos_in.severity or "HIGH").upper()
    type_str = (sos_in.emergency_type or "").lower()
    if sev_str == "CRITICAL" or any(k in type_str for k in ["trapped", "collapse", "fire", "flood", "cardiac"]):
        sev_val = 95.0
    elif sev_str == "HIGH":
        sev_val = 80.0
    elif sev_str == "MEDIUM":
        sev_val = 55.0
    else:
        sev_val = 30.0

    vuln_val = 60.0
    notes_lower = (sos_in.notes or "").lower()
    if any(k in notes_lower for k in ["elderly", "infant", "child", "disabled", "pregnant"]):
        vuln_val += 20.0
    if any(k in notes_lower for k in ["medical", "injury", "injured", "bleeding"]):
        vuln_val += 15.0
    if sos_in.household_code:
        hh = db.query(Household).filter(Household.household_code == sos_in.household_code).first()
        if hh and hh.vulnerability_score:
            vuln_val = hh.vulnerability_score * 100.0
    vuln_val = min(vuln_val, 100.0)

    risk_val = 70.0
    try:
        from app.services.priority_engine import predict_risk_at_location
        ml_risk = predict_risk_at_location(sos_in.latitude, sos_in.longitude)
        risk_val = min(max(ml_risk * 100.0, 30.0), 100.0)
    except Exception:
        risk_val = 75.0

    iso_val = 70.0
    computed_priority = round(sev_val * 0.40 + vuln_val * 0.30 + risk_val * 0.20 + iso_val * 0.10, 1)

    new_sos = SOSRequest(
        sos_code=sos_code,
        idempotency_key=sos_in.idempotency_key,
        user_id=current_user.id if current_user else None,
        household_code=sos_in.household_code,
        sender_device_id=sos_in.sender_device_id,
        latitude=sos_in.latitude,
        longitude=sos_in.longitude,
        emergency_type=sos_in.emergency_type,
        severity=sos_in.severity,
        status="PENDING",
        priority_score=computed_priority,
        notes=sos_in.notes,
        via_mesh=sos_in.via_mesh or "FALSE",
        source_type="MOBILE",
    )
    db.add(new_sos)
    db.commit()
    db.refresh(new_sos)

    # Publish real-time event to WebSocket and Redis
    publish_event(
        "NEW_SOS",
        {
            "sos_id": new_sos.id,
            "sos_code": new_sos.sos_code,
            "severity": new_sos.severity,
            "status": new_sos.status,
            "priority_score": new_sos.priority_score,
            "latitude": new_sos.latitude,
            "longitude": new_sos.longitude,
            "emergency_type": new_sos.emergency_type,
            "notes": new_sos.notes,
            "created_at": new_sos.created_at.isoformat() if new_sos.created_at else datetime.utcnow().isoformat(),
        },
    )

    record_audit_event(
        db=db,
        action="SOS_CREATED",
        actor_username=current_user.username if current_user else "ANONYMOUS",
        actor_role=current_user.role if current_user else "CITIZEN",
        resource_type="SOS",
        resource_id=new_sos.sos_code,
        details=f"Emergency SOS created: {new_sos.emergency_type} ({new_sos.severity})",
    )

    # Trigger emergency alerts dispatch in background
    try:
        from app.services.alerts_service import dispatch_emergency_alerts

        background_tasks.add_task(
            dispatch_emergency_alerts,
            sos_code=new_sos.sos_code,
            severity=new_sos.severity,
            location_str=f"{new_sos.latitude}, {new_sos.longitude}",
            message=f"SOS alert: {new_sos.emergency_type} - {new_sos.notes or 'Immediate rescue required'}",
        )
    except Exception:
        pass

    return new_sos


@router.get("/active", response_model=list[SOSResponse])
def get_active_sos(db: Session = Depends(get_db)):
    """Retrieve all unresolved active SOS requests sorted by priority."""
    return (
        db.query(SOSRequest)
        .filter(SOSRequest.status.in_(["PENDING", "ASSIGNED", "DISPATCHED"]))
        .order_by(SOSRequest.priority_score.desc())
        .all()
    )


@router.get("/my", response_model=list[SOSResponse])
def get_my_sos_requests(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Retrieve all SOS requests initiated by the current authenticated citizen."""
    return (
        db.query(SOSRequest)
        .filter(SOSRequest.user_id == current_user.id)
        .order_by(SOSRequest.created_at.desc())
        .all()
    )


@router.get("/{sos_id}", response_model=SOSResponse)
def get_sos_by_id(sos_id: str, db: Session = Depends(get_db)):
    """Retrieve details for a single SOS request by ID or code."""
    query = db.query(SOSRequest)
    if str(sos_id).isdigit():
        sos = query.filter(SOSRequest.id == int(sos_id)).first()
    else:
        sos = query.filter(SOSRequest.sos_code == sos_id).first()
    if not sos:
        sos = query.filter(SOSRequest.sos_code.ilike(f"%{sos_id}%")).first()
    if not sos:
        raise HTTPException(status_code=404, detail="SOS not found")
    return sos


@router.patch("/{sos_id}/status", response_model=SOSResponse)
async def update_sos_status(
    sos_id: str,
    status_update: SOSStatusUpdate,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db),
):
    """
    Update the triage or rescue operational status of an SOS request.
    Allowed statuses: PENDING, ASSIGNED, DISPATCHED, RESCUED, CANCELLED.
    """
    query = db.query(SOSRequest)
    if str(sos_id).isdigit():
        sos = query.filter(SOSRequest.id == int(sos_id)).first()
    else:
        sos = query.filter(SOSRequest.sos_code == sos_id).first()
    if not sos:
        sos = query.filter(SOSRequest.sos_code.ilike(f"%{sos_id}%")).first()
    if not sos:
        raise HTTPException(status_code=404, detail="SOS not found")

    old_status = sos.status
    sos.status = status_update.status.upper()
    if status_update.assigned_team_id:
        sos.assigned_team_id = status_update.assigned_team_id
    if status_update.assigned_shelter_id:
        sos.assigned_shelter_id = status_update.assigned_shelter_id
    if status_update.notes:
        sos.notes = (sos.notes or "") + f" | Update: {status_update.notes}"

    if sos.status in ["RESCUED", "CANCELLED"]:
        sos.resolved_at = datetime.utcnow()

    db.commit()
    db.refresh(sos)

    publish_event(
        "SOS_STATUS_UPDATED",
        {"sos_id": sos.id, "sos_code": sos.sos_code, "status": sos.status},
    )

    record_audit_event(
        db=db,
        action="SOS_STATUS_UPDATED",
        actor_username=current_user.username if current_user else "DISPATCHER",
        actor_role=current_user.role if current_user else "RESCUE",
        resource_type="SOS",
        resource_id=sos.sos_code,
        details=f"Status changed from {old_status} to {sos.status}",
    )

    return sos


@router.post("/{sos_id}/assign", response_model=RescueAssignmentResponse)
def assign_rescue_team(
    sos_id: int,
    assignment_in: SOSAssignRequest,
    current_user: User = Depends(require_roles([UserRole.RESCUE, UserRole.ADMIN])),
    db: Session = Depends(get_db),
):
    """Assign a rescue team or responder to an active SOS request."""
    sos = db.query(SOSRequest).filter(SOSRequest.id == sos_id).first()
    if not sos:
        raise HTTPException(status_code=404, detail="SOS not found")

    sos.status = "ASSIGNED"
    sos.assigned_team_id = assignment_in.team_name

    assignment = RescueAssignment(
        sos_id=sos.id,
        sos_code=sos.sos_code,
        responder_id=assignment_in.responder_id or current_user.id,
        responder_username=assignment_in.responder_username or current_user.username,
        team_name=assignment_in.team_name,
        status="ASSIGNED",
        notes=assignment_in.notes,
    )
    db.add(assignment)
    db.commit()
    db.refresh(assignment)

    publish_event(
        "RESCUE_ASSIGNED",
        {
            "sos_code": sos.sos_code,
            "team_name": assignment.team_name,
            "responder": assignment.responder_username,
        },
    )

    record_audit_event(
        db=db,
        action="RESCUE_ASSIGNMENT_CREATED",
        actor_username=current_user.username,
        actor_role=current_user.role,
        resource_type="ASSIGNMENT",
        resource_id=str(assignment.id),
        details=f"Team {assignment.team_name} assigned to SOS {sos.sos_code}",
    )

    return assignment


@router.post("/mesh", response_model=MeshPacketAck)
async def receive_mesh_packet_sos(
    packet: MeshPacket,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """Receive store-and-forward mesh packet representing an offline SOS."""
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

        try:
            from app.services.alerts_service import dispatch_emergency_alerts

            background_tasks.add_task(
                dispatch_emergency_alerts,
                sos_code=result["associated_sos_code"],
                severity=packet.severity,
                location_str=f"{packet.latitude}, {packet.longitude}",
                message=f"Mesh Packet received from Household {packet.household_id}",
            )
        except Exception:
            pass

    return MeshPacketAck(
        status=result["status"],
        message_id=result["message_id"],
        action_taken=result["action_taken"],
        associated_sos_code=result["associated_sos_code"],
    )
