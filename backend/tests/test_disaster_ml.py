def test_get_disaster_zones(client):
    resp = client.get("/api/v1/disaster/zones")
    assert resp.status_code == 200
    zones = resp.json()
    assert len(zones) >= 2
    assert any(z["zone_code"] == "ZONE-04-NORTH" for z in zones)


def test_predict_landslide_endpoint_new_features(client):
    # Test with fireeye-ai-final features
    req_payload = {
        "rainfall_mm": 300.0,
        "slope_degrees": 50.0,
        "elevation_m": 1800.0,
        "soil_type": "Clay",
    }
    resp = client.post("/api/v1/disaster/predict/landslide", json=req_payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data["risk_level"] in ["LOW", "MEDIUM", "HIGH"]
    assert 0.0 <= data["risk_score"] <= 1.0
    assert "class_probabilities" in data
    assert "HIGH" in data["class_probabilities"]
    assert "disclaimer" in data


def test_predict_landslide_endpoint_legacy_features(client):
    req_payload = {
        "rainfall_24h": 185.0,
        "cumulative_rainfall_7d": 380.0,
        "slope": 38.5,
        "elevation": 1250.0,
        "soil_type": "Loamy",
    }
    resp = client.post("/api/v1/disaster/predict/landslide", json=req_payload)
    assert resp.status_code == 200
    data = resp.json()
    assert "risk_level" in data
    assert "class_probabilities" in data


def test_intelligence_pipeline_endpoint(client):
    payload = {
        "environmental_data": {
            "rainfall_mm": 300,
            "slope_degrees": 50,
            "elevation_m": 1800,
            "soil_type": "Clay",
        },
        "sos_requests": [
            {
                "id": "SOS-PIPELINE-01",
                "severity": 90,
                "vulnerability": 100,
                "isolation": 80,
            },
            {
                "id": "SOS-PIPELINE-02",
                "severity": 60,
                "vulnerability": 50,
                "isolation": 40,
            },
        ],
        "road_network": {
            "Base": {"Village": 5},
            "Village": {"Base": 5, "Hospital": 4},
            "Hospital": {"Village": 4},
        },
        "rescue_base": "Base",
        "destination": "Hospital",
        "blocked_roads": None,
    }
    resp = client.post("/api/v1/disaster/pipeline", json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert "risk_assessment" in data
    assert "risk_score_used_for_priority" in data
    assert "ranked_rescue_requests" in data
    assert "route_plan" in data
    assert data["route_plan"]["success"] is True
    assert data["route_plan"]["route"] == ["Base", "Village", "Hospital"]
