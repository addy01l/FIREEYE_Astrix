def test_priority_queue(client):
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
        for i in range(len(queue) - 1):
            assert queue[i]["priority_score"] >= queue[i + 1]["priority_score"]
    
    first_item = queue[0]
    assert "breakdown" in first_item
    assert "severity" in first_item["breakdown"]
    assert "vulnerability" in first_item["breakdown"]
    assert "risk" in first_item["breakdown"]
    assert "isolation" in first_item["breakdown"]


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


def test_network_routing_dijkstra(client):
    road_network = {
        "Rescue_Base": {"Village_A": 4, "Village_B": 2},
        "Village_A": {"Rescue_Base": 4, "Village_B": 1, "Village_C": 5},
        "Village_B": {"Rescue_Base": 2, "Village_A": 1, "Village_C": 8, "Village_D": 10},
        "Village_C": {"Village_A": 5, "Village_B": 8, "Village_D": 2, "Hospital": 9},
        "Village_D": {"Village_B": 10, "Village_C": 2, "Hospital": 3},
        "Hospital": {"Village_C": 9, "Village_D": 3},
    }

    # 1. Normal route
    req = {
        "graph": road_network,
        "start": "Rescue_Base",
        "destination": "Hospital",
        "blocked_roads": None,
    }
    resp = client.post("/api/v1/routing/network-route", json=req)
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert data["total_distance"] == 13

    # 2. Blocked road route
    req_blocked = {
        "graph": road_network,
        "start": "Rescue_Base",
        "destination": "Hospital",
        "blocked_roads": [["Village_C", "Village_D"]],
    }
    resp2 = client.post("/api/v1/routing/network-route", json=req_blocked)
    assert resp2.status_code == 200
    data2 = resp2.json()
    assert data2["success"] is True

    # 3. All roads blocked
    req_impossible = {
        "graph": road_network,
        "start": "Rescue_Base",
        "destination": "Hospital",
        "blocked_roads": [["Rescue_Base", "Village_A"], ["Rescue_Base", "Village_B"]],
    }
    resp3 = client.post("/api/v1/routing/network-route", json=req_impossible)
    assert resp3.status_code == 200
    data3 = resp3.json()
    assert data3["success"] is False


def test_shelters_and_occupancy(client):
    resp = client.get("/api/v1/shelters/")
    assert resp.status_code == 200
    shelters = resp.json()
    assert len(shelters) >= 1
    shelter = shelters[0]
    assert "available_beds" in shelter
    assert shelter["available_beds"] == max(0, shelter["capacity"] - shelter["current_occupancy"])

    patch_resp = client.patch(
        f"/api/v1/shelters/{shelter['shelter_code']}/occupancy",
        json={"current_occupancy": shelter["current_occupancy"] + 2},
    )
    assert patch_resp.status_code == 200
    updated = patch_resp.json()
    assert updated["current_occupancy"] == shelter["current_occupancy"] + 2
