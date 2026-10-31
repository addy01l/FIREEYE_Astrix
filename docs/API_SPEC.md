# 🔥 FIRE-EYE — API Specification

The backend runs as a FastAPI service providing REST endpoints and a real-time WebSocket connection.

---

## Base URL
`http://localhost:8000/api/v1`

---

## 1. Authentication (`/auth`)

### `POST /auth/login`
- **Request Body**:
  ```json
  {
    "username": "commander@fire-eye.org",
    "password": "securepassword"
  }
  ```
- **Response**:
  ```json
  {
    "access_token": "eyJhbG...",
    "token_type": "bearer",
    "role": "RESCUE",
    "user_id": "USR-101"
  }
  ```

---

## 2. Disaster Risk & Predictions (`/disaster`)

### `GET /disaster/zones`
Returns all monitored disaster zones and current real-time hazard status.
- **Response**:
  ```json
  [
    {
      "zone_id": "ZONE-NORTH-01",
      "name": "Wayanad Slope Sector 4",
      "risk_level": "HIGH",
      "risk_score": 0.88,
      "rainfall_24h": 182.5,
      "slope": 38.2,
      "elevation": 1250,
      "population": 1240,
      "vulnerable_count": 87,
      "coordinates": [[11.605, 76.085], [11.615, 76.095], [11.595, 76.105]]
    }
  ]
  ```

### `POST /disaster/predict/landslide`
Runs the ML model inference.
- **Request Body**:
  ```json
  {
    "rainfall_24h": 185.0,
    "slope": 37.5,
    "elevation": 1200.0,
    "soil_type": "clay_loam",
    "historical_events": 2
  }
  ```
- **Response**:
  ```json
  {
    "risk_score": 0.89,
    "risk_level": "HIGH",
    "features_contributing": {
      "rainfall_24h": "high_impact",
      "slope": "critical"
    }
  }
  ```

---

## 3. Vulnerable Households (`/households`)

### `GET /households`
- **Query Params**: `zone_id`, `min_vulnerability`
- **Response**:
  ```json
  [
    {
      "household_id": "H101",
      "zone_id": "ZONE-NORTH-01",
      "address": "42 Hilltop Ridge",
      "latitude": 11.6082,
      "longitude": 76.0921,
      "members_count": 4,
      "elderly_count": 2,
      "children_count": 0,
      "disabled_count": 1,
      "medical_dependency": "Oxygen Concentrator",
      "vulnerability_score": 0.92
    }
  ]
  ```

---

## 4. Emergency SOS (`/sos`)

### `POST /sos`
Triggered via Smartphone or Mesh Gateway ingestion.
- **Request Body**:
  ```json
  {
    "household_id": "H101",
    "latitude": 11.6082,
    "longitude": 76.0921,
    "emergency_type": "LANDSLIDE_TRAPPED",
    "severity": "CRITICAL",
    "notes": "Elderly grandmother cannot walk, mud entering ground floor."
  }
  ```
- **Response**:
  ```json
  {
    "sos_id": "SOS-9821",
    "status": "PENDING",
    "priority_score": 94.6,
    "created_at": "2026-10-07T12:00:00Z"
  }
  ```

### `GET /sos/active`
Returns all active SOS calls sorted by priority.

### `PATCH /sos/{sos_id}/status`
Update status: `PENDING`, `DISPATCHED`, `RESCUED`, `CANCELLED`.

---

## 5. Priority Queue (`/priority`)

### `GET /priority/queue`
Returns sorted rescue queue based on formula:
`Score = Severity * 40 + Vulnerability * 30 + Risk * 20 + Isolation * 10`

---

## 6. Evacuation Routing & Shelters (`/routing`, `/shelters`)

### `POST /routing/safe-route`
- **Request Body**:
  ```json
  {
    "origin": { "lat": 11.6082, "lng": 76.0921 },
    "destination": { "lat": 11.5950, "lng": 76.1200 },
    "avoid_high_risk": true
  }
  ```
- **Response**:
  ```json
  {
    "route_coordinates": [[11.6082, 76.0921], [11.6040, 76.0980], [11.5950, 76.1200]],
    "distance_km": 4.2,
    "estimated_minutes": 18,
    "hazard_level": "LOW",
    "bypassed_zones": ["ZONE-NORTH-01"]
  }
  ```

### `GET /shelters`
Returns list of shelters with available capacity and coordinates.

---

## 7. Offline Mesh Gateway (`/mesh`)

### `POST /mesh/packet`
Receives store-and-forward mesh packet from a gateway node.
- **Request Body**:
  ```json
  {
    "message_id": "MESH-SOS-5541",
    "sender_id": "NODE-DEVICE-A",
    "type": "SOS",
    "latitude": 11.6082,
    "longitude": 76.0921,
    "severity": "CRITICAL",
    "household_id": "H101",
    "timestamp": 1791370200,
    "ttl": 5,
    "hops": ["NODE-DEVICE-A", "NODE-DEVICE-B", "NODE-DEVICE-C", "GATEWAY-01"]
  }
  ```
- **Response**:
  ```json
  {
    "status": "ACCEPTED",
    "action": "SOS_ENQUEUED",
    "sos_id": "SOS-9821"
  }
  ```

---

## 8. Real-Time WebSockets (`/ws`)
Connect to `ws://localhost:8000/ws` to receive instant updates when:
- An SOS is broadcast
- A zone changes hazard color
- A rescue team changes status
