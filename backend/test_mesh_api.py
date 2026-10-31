import requests
import time
import json
import uuid

url = "http://127.0.0.1:8000/api/v1/mesh/packet"

payload = {
    "message_id": f"SOS-{int(time.time())}-{uuid.uuid4().hex[:4].upper()}",
    "sender_id": "DEVICE-A",
    "household_id": "H101",
    "latitude": 11.6082,
    "longitude": 76.0921,
    "severity": "CRITICAL",
    "timestamp": int(time.time()),
    "ttl": 8,
    "hops": ["DEVICE-A", "DEVICE-B", "DEVICE-C", "GATEWAY-RESCUE-TRUCK"],
    "payload": {
        "vulnerabilities": ["ELDERLY", "MOBILITY_IMPAIRED"],
        "people_count": 4,
        "battery_level": 82
    }
}

print(f"Sending offline mesh packet to gateway API...")
print(json.dumps(payload, indent=2))

try:
    response = requests.post(url, json=payload)
    print(f"\nResponse Code: {response.status_code}")
    print(f"Response Body: {json.dumps(response.json(), indent=2)}")
except Exception as e:
    print(f"\nError hitting API: {e}")
