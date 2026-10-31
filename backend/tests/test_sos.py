import uuid


def test_create_sos_and_idempotency(client):
    idempotency_key = f"IDEM-KEY-{uuid.uuid4()}"
    sos_payload = {
        "household_code": "H101",
        "latitude": 30.2846,
        "longitude": 78.9815,
        "emergency_type": "LANDSLIDE_TRAPPED",
        "severity": "CRITICAL",
        "notes": "Mud entering ground floor, need immediate assistance",
        "idempotency_key": idempotency_key,
    }

    # 1. First submission
    resp1 = client.post("/api/v1/sos/", json=sos_payload)
    assert resp1.status_code == 201
    data1 = resp1.json()
    assert "sos_code" in data1
    assert data1["status"] == "PENDING"
    assert data1["severity"] == "CRITICAL"
    sos_id = data1["id"]

    # 2. Duplicate submission with same idempotency key -> Returns original SOS without creating duplicate
    resp2 = client.post("/api/v1/sos/", json=sos_payload)
    assert resp2.status_code in [200, 201]
    data2 = resp2.json()
    assert data2["id"] == sos_id
    assert data2["sos_code"] == data1["sos_code"]


def test_get_active_sos_and_status_update(client):
    # Retrieve active SOS list
    resp = client.get("/api/v1/sos/active")
    assert resp.status_code == 200
    active_list = resp.json()
    assert isinstance(active_list, list)

    if active_list:
        sos_id = active_list[0]["id"]
        # Update status
        patch_resp = client.patch(
            f"/api/v1/sos/{sos_id}/status",
            json={"status": "DISPATCHED", "assigned_team_id": "RESCUE_TEAM_ALPHA"},
        )
        assert patch_resp.status_code == 200
        assert patch_resp.json()["status"] == "DISPATCHED"
        assert patch_resp.json()["assigned_team_id"] == "RESCUE_TEAM_ALPHA"


def test_rescue_assignment(client):
    # Log in as rescue commander
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"username": "commander", "password": "securepassword"},
    )
    token = login_resp.json()["access_token"]

    # Create SOS
    sos_resp = client.post(
        "/api/v1/sos/",
        json={
            "household_code": "H102",
            "latitude": 30.2840,
            "longitude": 78.9805,
            "emergency_type": "FLOOD_SURROUNDED",
            "severity": "HIGH",
        },
    )
    sos_id = sos_resp.json()["id"]

    # Assign rescue team
    assign_resp = client.post(
        f"/api/v1/sos/{sos_id}/assign",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "team_name": "NDRF Quick Response Unit 2",
            "notes": "Dispatched via high ground route",
        },
    )
    assert assign_resp.status_code == 200
    assignment_data = assign_resp.json()
    assert assignment_data["sos_id"] == sos_id
    assert assignment_data["team_name"] == "NDRF Quick Response Unit 2"
    assert assignment_data["status"] == "ASSIGNED"

