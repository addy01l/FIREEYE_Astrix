"""
FIRE-EYE Priority Engine v2.0
Multi-factor triage scoring with ML integration, time-decay, and medical urgency.
"""

from datetime import datetime
from typing import Any

from app.models.household import Household
from app.models.risk_zone import RiskZone
from app.models.sos import SOSRequest
from app.services.ml_service import predict_risk_at_location
from sqlalchemy.orm import Session

# ── Severity weights ─────────────────────────────────────────────────────────
SEVERITY_WEIGHTS = {"CRITICAL": 1.0, "HIGH": 0.75, "MEDIUM": 0.50, "LOW": 0.25}

# ── Medical urgency keywords → bonus multipliers ─────────────────────────────
MEDICAL_URGENCY_KEYWORDS = {
    "oxygen": 8.0,
    "dialysis": 7.5,
    "insulin": 7.0,
    "cardiac": 7.0,
    "seizure": 6.0,
    "bleeding": 6.5,
    "pregnant": 6.0,
    "ventilator": 9.0,
    "fracture": 4.0,
    "unconscious": 8.0,
}


def _compute_time_decay(created_at: datetime) -> float:
    """
    Returns 0.0–1.0 bonus based on how long the SOS has been waiting.
    Older requests get a higher urgency bump to prevent starvation.
    """
    if not created_at:
        return 0.5
    elapsed = datetime.utcnow() - created_at
    hours = elapsed.total_seconds() / 3600.0
    # Sigmoid-like curve: ramps sharply after 1h, plateaus at ~6h
    if hours <= 0.25:
        return 0.1
    elif hours <= 1.0:
        return 0.3
    elif hours <= 3.0:
        return 0.6
    elif hours <= 6.0:
        return 0.85
    else:
        return 1.0


def _compute_medical_urgency(medical_needs: str) -> float:
    """
    Scans medical notes for critical keywords and returns 0.0–1.0.
    """
    if not medical_needs:
        return 0.0
    text = medical_needs.lower()
    max_score = 0.0
    for keyword, weight in MEDICAL_URGENCY_KEYWORDS.items():
        if keyword in text:
            max_score = max(max_score, weight)
    return min(max_score / 10.0, 1.0)


def calculate_priority_score(
    severity: str,
    vulnerability_score: float,
    zone_risk_score: float,
    isolation_score: float = 0.7,
    time_decay: float = 0.3,
    medical_urgency: float = 0.0,
    ml_risk: float = 0.0,
) -> dict[str, float]:
    """
    Computes priority using the FIRE-EYE multi-factor priority formula v2:

    Priority = Severity(30) + Vulnerability(20) + EnvironmentalRisk(15)
             + Isolation(10) + TimeDecay(10) + MedicalUrgency(10) + ML_Risk(5)

    Max score: 100.0
    """
    sev_factor = SEVERITY_WEIGHTS.get(severity.upper(), 0.5)

    comp_severity = round(sev_factor * 30.0, 1)
    comp_vulnerability = round(min(max(vulnerability_score, 0.0), 1.0) * 20.0, 1)
    comp_risk = round(min(max(zone_risk_score, 0.0), 1.0) * 15.0, 1)
    comp_isolation = round(min(max(isolation_score, 0.0), 1.0) * 10.0, 1)
    comp_time = round(min(max(time_decay, 0.0), 1.0) * 10.0, 1)
    comp_medical = round(min(max(medical_urgency, 0.0), 1.0) * 10.0, 1)
    comp_ml = round(min(max(ml_risk, 0.0), 1.0) * 5.0, 1)

    total = round(
        comp_severity
        + comp_vulnerability
        + comp_risk
        + comp_isolation
        + comp_time
        + comp_medical
        + comp_ml,
        1,
    )

    return {
        "total_score": total,
        "comp_severity": comp_severity,
        "comp_vulnerability": comp_vulnerability,
        "comp_risk": comp_risk,
        "comp_isolation": comp_isolation,
        "comp_time_decay": comp_time,
        "comp_medical_urgency": comp_medical,
        "comp_ml_risk": comp_ml,
    }


def compute_ranked_rescue_queue(db: Session) -> list[dict[str, Any]]:
    """
    Fetches all active SOS calls, evaluates live priority scores against
    household, risk-zone, ML, and time-decay state, and returns a sorted
    queue ranked #1 to #N.
    """
    active_sos = (
        db.query(SOSRequest)
        .filter(SOSRequest.status.in_(["PENDING", "ASSIGNED", "DISPATCHED"]))
        .all()
    )

    # ── Batch-fetch related data (avoid N+1) ─────────────────────────────
    household_codes = [sos.household_code for sos in active_sos if sos.household_code]
    households: dict[str, Household] = {}
    zones: dict[str, RiskZone] = {}

    if household_codes:
        hh_results = (
            db.query(Household)
            .filter(Household.household_code.in_(household_codes))
            .all()
        )
        households = {hh.household_code: hh for hh in hh_results}

        zone_ids = list({hh.zone_id for hh in hh_results if hh.zone_id})
        if zone_ids:
            zone_results = (
                db.query(RiskZone).filter(RiskZone.zone_code.in_(zone_ids)).all()
            )
            zones = {z.zone_code: z for z in zone_results}

    # ── Score each SOS ───────────────────────────────────────────────────
    queue_items = []

    for sos in active_sos:
        household = households.get(sos.household_code) if sos.household_code else None

        vuln_score = household.vulnerability_score if household else 0.5
        zone = (
            zones.get(household.zone_id) if (household and household.zone_id) else None
        )
        risk_score = zone.risk_score if zone else 0.4

        # Isolation: high-altitude or remote location
        isolation = (
            0.85
            if (
                household
                and hasattr(household, "elevation")
                and household.elevation
                and household.elevation > 1100
            )
            else 0.60
        )

        # Time decay
        time_decay = _compute_time_decay(sos.created_at)

        # Medical urgency
        medical_text = (household.medical_needs or "") if household else ""
        if sos.notes:
            medical_text += " " + sos.notes
        medical_urgency = _compute_medical_urgency(medical_text)

        # ML environmental risk prediction
        ml_risk = predict_risk_at_location(sos.latitude, sos.longitude)

        scores = calculate_priority_score(
            severity=sos.severity,
            vulnerability_score=vuln_score,
            zone_risk_score=risk_score,
            isolation_score=isolation,
            time_decay=time_decay,
            medical_urgency=medical_urgency,
            ml_risk=ml_risk,
        )

        # Persist computed score
        sos.priority_score = scores["total_score"]

        queue_items.append(
            {
                "sos_id": sos.id,
                "sos_code": sos.sos_code,
                "household_code": sos.household_code,
                "priority_score": scores["total_score"],
                "severity": sos.severity,
                "severity_component": scores["comp_severity"],
                "vulnerability_component": scores["comp_vulnerability"],
                "risk_component": scores["comp_risk"],
                "isolation_component": scores["comp_isolation"],
                "time_decay_component": scores["comp_time_decay"],
                "medical_urgency_component": scores["comp_medical_urgency"],
                "ml_risk_component": scores["comp_ml_risk"],
                "latitude": sos.latitude,
                "longitude": sos.longitude,
                "emergency_type": sos.emergency_type,
                "status": sos.status,
                "source_type": sos.source_type,
                "via_mesh": sos.via_mesh,
                "hops_count": sos.hops_count,
                "notes": sos.notes,
                "elderly_count": household.elderly_count if household else 0,
                "disabled_count": household.disabled_count if household else 0,
                "medical_needs": household.medical_needs if household else None,
                "created_at": sos.created_at,
            }
        )

    # Sort descending by priority
    queue_items.sort(key=lambda x: x["priority_score"], reverse=True)

    # Assign ranks 1 → N
    for index, item in enumerate(queue_items, start=1):
        item["rank"] = index

    db.commit()
    return queue_items
