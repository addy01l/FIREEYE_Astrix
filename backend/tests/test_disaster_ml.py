def test_get_disaster_zones(client):
    resp = client.get("/api/v1/disaster/zones")
    assert resp.status_code == 200
    zones = resp.json()
    assert len(zones) >= 2
    assert any(z["zone_code"] == "ZONE-04-NORTH" for z in zones)


def test_predict_landslide_endpoint(client):
    req_payload = {
        "rainfall_24h": 185.0,
        "cumulative_rainfall_7d": 380.0,
        "slope": 38.5,
        "elevation": 1250.0,
        "historical_disasters": 2,
    }
    resp = client.post("/api/v1/disaster/predict/landslide", json=req_payload)
    assert resp.status_code == 200
    data = resp.json()
    assert "risk_level" in data
    assert "risk_score" in data
    assert data["risk_level"] in ["LOW", "MEDIUM", "HIGH"]
    assert 0.0 <= data["risk_score"] <= 1.0
    assert "features_used" in data
    assert "disclaimer" in data

