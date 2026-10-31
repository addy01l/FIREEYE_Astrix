import uuid


def test_mesh_packet_ingestion_and_deduplication(client):
    msg_id = f"MESH-TEST-{uuid.uuid4()}"
    packet = {
        "message_id": msg_id,
        "sender_id": "NODE-DEVICE-01",
        "type": "SOS",
        "latitude": 30.2844,
        "longitude": 78.9811,
        "severity": "CRITICAL",
        "household_id": "H101",
        "timestamp": 1791370200,
        "ttl": 5,
        "hops": ["NODE-DEVICE-01", "RELAY-NODE-A", "GATEWAY-CENTRAL-01"],
        "payload": {
            "vulnerabilities": ["Elderly", "Oxygen Dependency"],
            "battery_level": 78,
        },
    }

    # 1. Ingest mesh packet
    resp1 = client.post("/api/v1/mesh/packet", json=packet)
    assert resp1.status_code == 200
    data1 = resp1.json()
    assert data1["status"] == "ACCEPTED"
    assert data1["action_taken"] in ["SOS_ENQUEUED", "ATTACHED_TO_EXISTING_SOS"]

    # 2. Resend same packet (Duplicate)
    resp2 = client.post("/api/v1/mesh/packet", json=packet)
    assert resp2.status_code == 200
    data2 = resp2.json()
    assert data2["status"] == "DUPLICATE_DROPPED"
    assert data2["action_taken"] == "Ignored"


def test_mesh_messages_audit(client):
    resp = client.get("/api/v1/mesh/messages")
    assert resp.status_code == 200
    messages = resp.json()
    assert isinstance(messages, list)

