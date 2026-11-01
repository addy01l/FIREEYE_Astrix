import uuid
from unittest.mock import patch
from app.services.ai_assistant_service import (
    _generate_rule_based_fallback,
    analyze_sos_with_groq,
)


def test_rule_based_fallback_structure():
    fallback = _generate_rule_based_fallback(
        sos_code="SOS-TEST-001",
        emergency_type="FLASH_FLOOD",
        severity="CRITICAL",
        latitude=30.28,
        longitude=78.98,
        notes="Trapped on roof with elderly person and child, water rising",
        priority_score=92.0,
    )
    assert "incident_summary" in fallback
    assert isinstance(fallback["identified_risk_factors"], list)
    assert len(fallback["identified_risk_factors"]) > 0
    assert isinstance(fallback["recommended_rescue_actions"], list)
    assert len(fallback["recommended_rescue_actions"]) > 0
    assert isinstance(fallback["required_rescue_resources"], list)
    assert len(fallback["required_rescue_resources"]) > 0
    assert fallback["suggested_urgency_level"] == "CRITICAL"


def test_ai_analysis_endpoint(client):
    # Create SOS
    idempotency_key = f"IDEM-AI-{uuid.uuid4()}"
    sos_payload = {
        "household_code": "H101",
        "latitude": 30.2846,
        "longitude": 78.9815,
        "emergency_type": "BUILDING_COLLAPSE",
        "severity": "CRITICAL",
        "notes": "People trapped under rubble, infant crying",
        "idempotency_key": idempotency_key,
    }

    create_resp = client.post("/api/v1/sos/", json=sos_payload)
    assert create_resp.status_code == 201
    sos_data = create_resp.json()
    sos_code = sos_data["sos_code"]
    sos_id = sos_data["id"]

    # Request AI analysis by sos_code
    resp = client.get(f"/api/v1/sos/{sos_code}/ai-analysis")
    assert resp.status_code == 200
    ai_data = resp.json()

    assert ai_data["sos_code"] == sos_code
    assert "incident_summary" in ai_data and len(ai_data["incident_summary"]) > 0
    assert isinstance(ai_data["identified_risk_factors"], list)
    assert len(ai_data["identified_risk_factors"]) > 0
    assert isinstance(ai_data["recommended_rescue_actions"], list)
    assert len(ai_data["recommended_rescue_actions"]) > 0
    assert isinstance(ai_data["required_rescue_resources"], list)
    assert len(ai_data["required_rescue_resources"]) > 0
    assert "suggested_urgency_level" in ai_data
    assert ai_data["reviewed_by_human"] is False

    # Also test by integer ID
    resp_id = client.get(f"/api/v1/sos/{sos_id}/ai-analysis")
    assert resp_id.status_code == 200
    assert resp_id.json()["sos_code"] == sos_code


def test_ai_analysis_fallback_on_groq_exception():
    with patch("app.services.ai_assistant_service._get_groq_client", return_value=None):
        result = analyze_sos_with_groq(
            sos_code="SOS-MOCK-999",
            emergency_type="LANDSLIDE",
            severity="HIGH",
            latitude=30.0,
            longitude=78.0,
            notes="Road blocked, power cut",
            priority_score=70.0,
        )
        assert result["suggested_urgency_level"] == "HIGH"
        assert result["model_used"] == "FIRE_EYE_Heuristic_Safety_Engine"
        assert len(result["recommended_rescue_actions"]) >= 1
