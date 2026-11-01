"""
FIRE-EYE Groq API-Powered AI SOS Response Assistant
Provides rapid LLM-assisted tactical triage, risk factor extraction,
and recommended rescue resources for incoming disaster SOS calls.
All AI outputs are strictly advisory and must be reviewed by a human rescuer.
"""

from datetime import datetime
import json
import logging
import os
import re
from typing import Any

from app.core.config import settings
from app.models.sos import SOSRequest
from app.models.sos_ai_analysis import SOSAIAnalysis
from sqlalchemy.orm import Session

logger = logging.getLogger("fireeye.ai_assistant")

_GROQ_CLIENT = None


def _get_groq_client():
    global _GROQ_CLIENT
    api_key = settings.GROQ_API_KEY or os.getenv("GROQ_API_KEY")
    if not api_key:
        return None
    if _GROQ_CLIENT is None:
        try:
            from groq import Groq
            _GROQ_CLIENT = Groq(api_key=api_key, timeout=7.0)
        except Exception as e:
            logger.warning(f"Could not initialize Groq SDK: {e}")
            return None
    return _GROQ_CLIENT


def _clean_json_response(raw_text: str) -> dict[str, Any]:
    """Extract and parse clean JSON from LLM response, stripping code blocks."""
    cleaned = raw_text.strip()
    match = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", cleaned)
    if match:
        cleaned = match.group(1).strip()
    return json.loads(cleaned)


def _generate_rule_based_fallback(
    sos_code: str,
    emergency_type: str,
    severity: str,
    latitude: float,
    longitude: float,
    notes: str | None,
    priority_score: float,
) -> dict[str, Any]:
    """
    High-reliability tactical fallback if Groq API is unreachable or times out.
    Guarantees SOS workflows are never blocked.
    """
    notes_lower = (notes or "").lower()
    urgency = (severity or "HIGH").upper()
    if priority_score >= 80.0 or "trapped" in notes_lower or "infant" in notes_lower:
        urgency = "CRITICAL"

    risks = ["Unstable terrain / structural secondary collapse", "Delayed medical response in disaster perimeter"]
    if "rain" in notes_lower or "weather" in notes_lower:
        risks.append("Saturated soil elevating active landslide movement")
    if "child" in notes_lower or "infant" in notes_lower or "elderly" in notes_lower:
        risks.append("Vulnerable dependent civilian trapped on-site")
    if "breathing" in notes_lower or "injury" in notes_lower or "bleeding" in notes_lower:
        risks.append("Critical acute trauma requiring immediate triage")

    actions = [
        f"Deploy local search-and-rescue team to coordinates ({latitude:.4f}, {longitude:.4f})",
        "Establish tactical comms via BLE mesh and mobile repeaters",
        "Clear primary access route and verify bridge/road passability",
        "Evacuate verified casualties to nearest operational shelter",
    ]

    resources = [
        "4x4 Emergency Rescue Vehicle",
        "First-Aid & Trauma Immobilization Kit",
        "Battery-Powered Hydraulic Cutters / Debris Spreaders",
        "Satellite / LoRa Mesh Relay Field Radio",
    ]
    if "trapped" in notes_lower or "collapse" in notes_lower:
        resources.append("Heavy Shoring Equipment & Search Dog Squad")
    if "elderly" in notes_lower or "breathing" in notes_lower:
        resources.append("Portable Oxygen Concentrator & Medical Evac Unit")

    summary = (
        f"Emergency beacon [{sos_code}]: {emergency_type} at ({latitude:.4f}, {longitude:.4f}). "
        f"{notes or 'Immediate search and extraction requested.'}"
    )

    return {
        "incident_summary": summary,
        "identified_risk_factors": risks[:4],
        "recommended_rescue_actions": actions[:4],
        "required_rescue_resources": resources[:5],
        "suggested_urgency_level": urgency,
        "model_used": "FIRE_EYE_Heuristic_Safety_Engine",
    }


def analyze_sos_with_groq(
    sos_code: str,
    emergency_type: str,
    severity: str,
    latitude: float,
    longitude: float,
    notes: str | None = None,
    priority_score: float = 50.0,
    via_mesh: bool | str = False,
) -> dict[str, Any]:
    """
    Synthesize distress telemetry using Groq LLM API into structured tactical JSON.
    Falls back gracefully on any network timeout or failure.
    """
    client = _get_groq_client()
    if not client:
        logger.info(f"Groq API key not configured. Using rule-based safety engine for {sos_code}")
        return _generate_rule_based_fallback(
            sos_code, emergency_type, severity, latitude, longitude, notes, priority_score
        )

    user_prompt = f"""You are the FIRE-EYE Tactical Disaster Response AI Assistant.
Analyze this emergency SOS dispatch:
- SOS Code: {sos_code}
- Emergency Type: {emergency_type}
- Reported Severity: {severity}
- Priority Triage Score: {priority_score:.1f} / 100
- Location: {latitude:.4f}° N, {longitude:.4f}° E
- Mesh Relay Broadcast: {via_mesh}
- Field Situation & Notes: {notes or 'No additional details provided'}

Generate a structured JSON response containing exactly these fields:
{{
  "incident_summary": "1-2 sentence concise operational summary of the situation",
  "identified_risk_factors": ["list of 3-4 specific threats or hazards"],
  "recommended_rescue_actions": ["list of 3-4 tactical action steps for responders"],
  "required_rescue_resources": ["list of 3-4 specialized equipment, vehicles, or squads needed"],
  "suggested_urgency_level": "{severity.upper() if severity else 'HIGH'}"
}}
Ensure the output is clean, valid JSON only. Do not include markdown or explanations."""

    candidate_models = [
        settings.GROQ_MODEL or "openai/gpt-oss-120b",
        "openai/gpt-oss-20b",
        "qwen/qwen3.8-27b",
    ]

    for model_name in candidate_models:
        try:
            logger.info(f"Querying Groq model {model_name} for SOS [{sos_code}]...")
            completion = client.chat.completions.create(
                model=model_name,
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are a disaster tactical emergency response assistant. "
                            "You generate clean, valid JSON advisory intelligence for search-and-rescue teams."
                        ),
                    },
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.2,
            )

            raw_content = completion.choices[0].message.content or "{}"
            parsed = _clean_json_response(raw_content)

            # Validate required schema keys
            required_keys = [
                "incident_summary",
                "identified_risk_factors",
                "recommended_rescue_actions",
                "required_rescue_resources",
                "suggested_urgency_level",
            ]
            if all(k in parsed for k in required_keys):
                parsed["model_used"] = f"groq-{model_name}"
                logger.info(f"Groq AI analysis completed successfully for SOS [{sos_code}] using {model_name}")
                return parsed

        except Exception as exc:
            logger.warning(f"Groq attempt with model {model_name} failed: {exc}")

    logger.warning(f"All Groq API models exhausted for {sos_code}. Reverting to rule-based fallback.")
    return _generate_rule_based_fallback(
        sos_code, emergency_type, severity, latitude, longitude, notes, priority_score
    )


def get_or_generate_sos_analysis(db: Session, sos: SOSRequest) -> SOSAIAnalysis:
    """Retrieve existing analysis from database or generate a new one via Groq."""
    existing = db.query(SOSAIAnalysis).filter(SOSAIAnalysis.sos_code == sos.sos_code).first()
    if existing:
        return existing

    analysis_data = analyze_sos_with_groq(
        sos_code=sos.sos_code,
        emergency_type=sos.emergency_type or "Disaster Distress",
        severity=sos.severity or "HIGH",
        latitude=sos.latitude,
        longitude=sos.longitude,
        notes=sos.notes,
        priority_score=sos.priority_score or 50.0,
        via_mesh=sos.via_mesh or "FALSE",
    )

    new_record = SOSAIAnalysis(
        sos_code=sos.sos_code,
        incident_summary=analysis_data.get("incident_summary", "Emergency SOS requiring tactical review."),
        identified_risk_factors=json.dumps(analysis_data.get("identified_risk_factors", [])),
        recommended_rescue_actions=json.dumps(analysis_data.get("recommended_rescue_actions", [])),
        required_rescue_resources=json.dumps(analysis_data.get("required_rescue_resources", [])),
        suggested_urgency_level=analysis_data.get("suggested_urgency_level", sos.severity or "HIGH"),
        model_used=analysis_data.get("model_used", "groq-openai/gpt-oss-120b"),
        reviewed_by_human=False,
    )

    try:
        db.add(new_record)
        db.commit()
        db.refresh(new_record)
        return new_record
    except Exception as e:
        db.rollback()
        logger.warning(f"Failed to persist AI analysis record to DB: {e}")
        # Return transient record
        return new_record


def generate_and_save_ai_analysis_task(sos_id: int, sos_code: str):
    """Background task executed asynchronously whenever a new SOS is created."""
    from app.database import SessionLocal

    db = SessionLocal()
    try:
        sos = db.query(SOSRequest).filter(SOSRequest.sos_code == sos_code).first()
        if not sos:
            sos = db.query(SOSRequest).filter(SOSRequest.id == sos_id).first()
        if sos:
            get_or_generate_sos_analysis(db, sos)
    except Exception as exc:
        logger.warning(f"Background AI analysis task encountered an error: {exc}")
    finally:
        db.close()
