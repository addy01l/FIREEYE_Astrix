def test_priority_queue(client):
    # Ensure active SOS exists
    client.post(
        "/api/v1/sos/",
        json={
            "household_code": "H101",
            "latitude": 30.2846,
            "longitude": 78.9815,
            "emergency_type": "LANDSLIDE_TRAPPED",
            "severity": "CRITICAL",
            "notes": "Medical emergency with oxygen cylinder",
        },
    )

    resp = client.get("/api/v1/priority/queue")
    assert resp.status_code == 200
    data = resp.json()
    assert "total_active_sos" in data
    assert "queue" in data
    assert data["total_active_sos"] >= 1
    queue = data["queue"]
    if len(queue) > 1:
        # Check priority queue is ordered descending
        for i in range(len(queue) - 1):
            assert queue[i]["priority_score"] >= queue[i + 1]["priority_score"]


def test_routing_safe_route_or_degraded(client):
    route_req = {
        "origin": {"lat": 30.2846, "lng": 78.9815},
        "destination": {"lat": 30.2900, "lng": 78.9900},
        "avoid_high_risk": True,
    }
    resp = client.post("/api/v1/routing/safe-route", json=route_req)
    assert resp.status_code == 200
    data = resp.json()
    assert "distance_km" in data
    assert "hazard_status" in data
    assert "path" in data
    # Principle check: if unverified straight line, must be explicitly flagged
    if data.get("routing_status") == "DEGRADED_STRAIGHT_LINE":
        assert data["is_verified_safe"] is False
        assert data["hazard_status"] == "UNVERIFIED_FALLBACK"


def test_shelters_and_occupancy(client):
    resp = client.get("/api/v1/shelters/")
    assert resp.status_code == 200
    shelters = resp.json()
    assert len(shelters) >= 1
    shelter = shelters[0]
    assert "available_beds" in shelter
    assert shelter["available_beds"] == max(0, shelter["capacity"] - shelter["current_occupancy"])

    # Update occupancy
    patch_resp = client.patch(
        f"/api/v1/shelters/{shelter['shelter_code']}/occupancy",
        json={"current_occupancy": shelter["current_occupancy"] + 2},
    )
    assert patch_resp.status_code == 200
    updated = patch_resp.json()
    assert updated["current_occupancy"] == shelter["current_occupancy"] + 2

