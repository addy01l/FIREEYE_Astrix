"""
FIRE-EYE Priority Engine
Directly incorporates fireeye-ai-final priority calculation and ranking logic.
Formula: Score = Severity(40%) + Vulnerability(30%) + Risk(20%) + Isolation(10%)
Classifies: HIGH (>=75), MEDIUM (>=40), LOW (<40) with deterministic tie-breaking.
"""

from datetime import datetime
import math
from typing import Any
from sqlalchemy.orm import Session

from app.models.household import Household
from app.models.risk_zone import RiskZone
from app.models.sos import SOSRequest
from app.services.ml_service import predict_risk_at_location

# ── Core Weights matching fireeye-ai-final ──────────────────────────────────
WEIGHTS = {
    "severity": 0.40,
    "vulnerability": 0.30,
    "risk": 0.20,
    "isolation": 0.10,
}

SEVERITY_MAP = {
    "CRITICAL": 95.0,
    "HIGH": 75.0,
    "MEDIUM": 50.0,
    "LOW": 25.0,
}


def validate_sos(sos: dict[str, Any]):
    """Ensure all required numeric fields exist and are within 0-100 range."""
    if not isinstance(sos, dict):
        raise ValueError("Each SOS request must be a dictionary")

    required_fields = ["id", "severity", "vulnerability", "risk", "isolation"]
    for field in required_fields:
        if field not in sos:
            raise ValueError(f"Missing required field: {field}")

    if not isinstance(sos["id"], str) or not sos["id"].strip():
        raise ValueError("SOS ID must be a non-empty string")

    for field in ["severity", "vulnerability", "risk", "isolation"]:
        value = sos[field]
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError(f"{field} must be numeric")
        if not math.isfinite(value) or not 0 <= value <= 100:
            raise ValueError(f"{field} must be between 0 and 100")


def calculate_priority(sos: dict[str, Any]) -> dict[str, Any]:
    """
    Computes priority using the fireeye-ai-final formula:
    Score = severity*0.40 + vulnerability*0.30 + risk*0.20 + isolation*0.10
    """
    validate_sos(sos)

    breakdown = {}
    for factor, weight in WEIGHTS.items():
        breakdown[factor] = round(sos[factor] * weight, 2)

    score = round(sum(breakdown.values()), 2)

    if score >= 75:
        level = "HIGH"
    elif score >= 40:
        level = "MEDIUM"
    else:
        level = "LOW"

    return {
        "id": sos["id"],
        "priority_score": score,
        "priority_level": level,
        "breakdown": breakdown,
    }


def calculate_priority_score(
    severity: str | float,
    vulnerability_score: float,
    zone_risk_score: float,
    isolation_score: float = 0.7,
    time_decay: float = 0.3,
    medical_urgency: float = 0.0,
    ml_risk: float = 0.0,
) -> dict[str, float]:
    """Compatibility wrapper converting variables to fireeye-ai-final breakdown."""
    sev_val = SEVERITY_MAP.get(str(severity).upper(), 75.0) if isinstance(severity, str) else float(severity)
    vuln_val = vulnerability_score * 100.0 if vulnerability_score <= 1.0 else vulnerability_score
    risk_val = zone_risk_score * 100.0 if zone_risk_score <= 1.0 else zone_risk_score
    iso_val = isolation_score * 100.0 if isolation_score <= 1.0 else isolation_score

    res = calculate_priority({
        "id": "SOS-CALC",
        "severity": min(max(sev_val, 0.0), 100.0),
        "vulnerability": min(max(vuln_val, 0.0), 100.0),
        "risk": min(max(risk_val, 0.0), 100.0),
        "isolation": min(max(iso_val, 0.0), 100.0),
    })
    return {
        "total_score": res["priority_score"],
        "comp_severity": res["breakdown"]["severity"],
        "comp_vulnerability": res["breakdown"]["vulnerability"],
        "comp_risk": res["breakdown"]["risk"],
        "comp_isolation": res["breakdown"]["isolation"],
    }


def rank_requests(requests: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """
    Validates, scores, and ranks a list of SOS request dictionaries.
    Tie-breaking: (-priority_score, id)
    """
    if not isinstance(requests, list) or not requests:
        raise ValueError("SOS requests must be a non-empty list")

    results = []
    seen_ids = set()

    for sos in requests:
        result = calculate_priority(sos)
        if result["id"] in seen_ids:
            raise ValueError(f"Duplicate SOS ID: {result['id']}")
        seen_ids.add(result["id"])
        results.append(result)

    results.sort(key=lambda item: (-item["priority_score"], item["id"]))

    for rank, result in enumerate(results, start=1):
        result["rank"] = rank

    return results


def compute_ranked_rescue_queue(db: Session) -> list[dict[str, Any]]:
    """
    Fetches all active SOS records from the database, evaluates live
    multi-factor priority scores with the new fireeye-ai-final formula,
    and returns a sorted queue ranked #1 to #N.
    """
    active_sos = (
        db.query(SOSRequest)
        .filter(SOSRequest.status.in_(["PENDING", "ASSIGNED", "DISPATCHED"]))
        .all()
    )

    if not active_sos:
        return []

    household_codes = [s.household_code for s in active_sos if s.household_code]
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

    queue_items = []

    for sos in active_sos:
        hh = households.get(sos.household_code) if sos.household_code else None
        zn = zones.get(hh.zone_id) if (hh and hh.zone_id) else None

        # 1. Severity: map string to 0-100
        sev_val = SEVERITY_MAP.get((sos.severity or "HIGH").upper(), 75.0)

        # 2. Vulnerability: normalized to 0-100
        vuln_score = (hh.vulnerability_score * 100.0) if hh else 50.0

        # 3. Environmental Risk: zone risk or ML prediction (0-100)
        if zn and zn.risk_score:
            risk_val = zn.risk_score * 100.0
        else:
            ml_risk = predict_risk_at_location(sos.latitude, sos.longitude)
            risk_val = ml_risk * 100.0

        # 4. Isolation: based on elevation / remoteness
        isolation_val = 85.0 if (hh and hh.elevation and hh.elevation > 1100) else 60.0

        sos_dict = {
            "id": sos.sos_code,
            "severity": min(max(sev_val, 0.0), 100.0),
            "vulnerability": min(max(vuln_score, 0.0), 100.0),
            "risk": min(max(risk_val, 0.0), 100.0),
            "isolation": min(max(isolation_val, 0.0), 100.0),
        }

        priority_calc = calculate_priority(sos_dict)
        sos.priority_score = priority_calc["priority_score"]

        queue_items.append({
            "sos_id": sos.id,
            "sos_code": sos.sos_code,
            "household_code": sos.household_code,
            "priority_score": priority_calc["priority_score"],
            "priority_level": priority_calc["priority_level"],
            "breakdown": priority_calc["breakdown"],
            "severity": sos.severity,
            "severity_component": priority_calc["breakdown"]["severity"],
            "vulnerability_component": priority_calc["breakdown"]["vulnerability"],
            "risk_component": priority_calc["breakdown"]["risk"],
            "isolation_component": priority_calc["breakdown"]["isolation"],
            "latitude": sos.latitude,
            "longitude": sos.longitude,
            "emergency_type": sos.emergency_type,
            "status": sos.status,
            "source_type": sos.source_type,
            "via_mesh": sos.via_mesh,
            "hops_count": sos.hops_count,
            "notes": sos.notes,
            "elderly_count": hh.elderly_count if hh else 0,
            "disabled_count": hh.disabled_count if hh else 0,
            "medical_needs": hh.medical_needs if hh else None,
            "created_at": sos.created_at,
        })

    # Sort descending by priority, then by sos_code
    queue_items.sort(key=lambda item: (-item["priority_score"], item["sos_code"]))

    for rank, item in enumerate(queue_items, start=1):
        item["rank"] = rank

    db.commit()
    return queue_items
