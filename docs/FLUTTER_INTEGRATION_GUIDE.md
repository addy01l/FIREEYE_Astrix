# 🔥 FIRE-EYE — Flutter Developer Integration Guide

This guide contains everything you need to build the **FIRE-EYE Android Mobile Application** with Flutter, Riverpod, Dio, and local offline storage (Drift/SQLite).

---

## 1. Quick Backend Startup

Before running the Flutter application, ensure the FIRE-EYE backend is running on your host machine:

```powershell
# Navigate to backend directory
cd backend

# Activate virtual environment (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# (Optional) Seed fresh demo scenario data (Uttarakhand disaster zone)
python -m app.seeds.seed_data

# Start FastAPI server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### URLs
- **Swagger Documentation (Interactive UI)**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **OpenAPI 3.0 Schema**: [http://localhost:8000/api/v1/openapi.json](http://localhost:8000/api/v1/openapi.json) (or file located at `docs/openapi.json`)
- **Health Check**: [http://localhost:8000/health](http://localhost:8000/health)

---

## 2. Base URLs for Flutter / Android

| Target Environment | Base REST URL | WebSocket URL |
|---|---|---|
| **Android Emulator** | `http://10.0.2.2:8000/api/v1` | `ws://10.0.2.2:8000/api/v1/ws/` |
| **Physical Android Device** | `http://<YOUR_LAN_IP>:8000/api/v1` | `ws://<YOUR_LAN_IP>:8000/api/v1/ws/` |
| **iOS Simulator** | `http://localhost:8000/api/v1` | `ws://localhost:8000/api/v1/ws/` |

> [!IMPORTANT]
> **Android Cleartext Traffic Requirement (Local Development)**:
> In your `android/app/src/main/AndroidManifest.xml`, make sure `<application>` tag includes:
> ```xml
> android:usesCleartextTraffic="true"
> ```
> Also ensure permissions are declared:
> ```xml
> <uses-permission android:name="android.permission.INTERNET" />
> <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
> <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
> ```

---

## 3. Pre-Seeded Test Accounts (All 4 Roles)

Password for all accounts is: **`securepassword`**

| Role | Username | Purpose & Primary Screens |
|---|---|---|
| **`CITIZEN`** | `citizen1` | One-tap Emergency SOS, offline queue, evacuation guidance, hazard alerts, profile |
| **`RESCUE`** | `commander` | Real-time rescue triage queue, active SOS map, unit dispatch & assignment, status updates |
| **`VOLUNTEER`** | `volunteer1` | Local relief tasks, vulnerable household support, community check-in |
| **`ADMIN`** | `admin` | Full operational command, hazard zones, shelter capacity overrides, audit event log |

---

## 4. Suggested Flutter Project Structure

```text
mobile/lib/
  main.dart
  core/
    constants/          # ApiEndpoints, AppColors, AppStrings
    network/            # DioClient, AuthInterceptor, ErrorHandler
    storage/            # SecureStorageService, LocalDatabase (Drift/SQLite)
    theme/              # Material 3 light & dark themes
    routing/            # GoRouter with role-based route guards
  shared/
    models/             # User, SOS, RiskZone, Shelter, PriorityItem
    widgets/            # SOSButton, RiskBadge, CustomTextField, OfflineBanner
  features/
    auth/               # LoginScreen, RegisterScreen, auth_controller
    citizen/            # CitizenDashboard, EvacuationScreen, HazardMapScreen
    rescue/             # PriorityQueueScreen, TriageDetailScreen, ResponderMap
    volunteer/          # TasksScreen, HouseholdCheckScreen
    admin/              # AdminDashboardScreen, AuditLogScreen, SheltersScreen
    sos/                # SOSController, OfflineSOSQueueService
    mesh/               # BluetoothMeshRelayService, PacketEncoder
```

---

## 5. API Contract Reference

### 5.1 Authentication (`/auth`)

#### `POST /auth/login`
**Request:**
```json
{
  "username": "commander",
  "password": "securepassword"
}
```
**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "role": "RESCUE",
  "username": "commander",
  "user_id": 2
}
```

#### `POST /auth/register`
**Request:**
```json
{
  "username": "john_citizen",
  "password": "mypassword123",
  "email": "john@example.com",
  "role": "CITIZEN",
  "full_name": "John Doe",
  "phone": "+91-9876543210"
}
```

#### `POST /auth/refresh`
**Request:** `{"refresh_token": "eyJhbGciOi..."}`  
**Response:** Same shape as login `TokenResponse`.

#### `GET /auth/me`
Requires header: `Authorization: Bearer <access_token>`

---

### 5.2 Emergency SOS (`/sos`)

#### `POST /sos/` (With Idempotency Key)
> [!TIP]
> Always generate a unique UUID v4 in Flutter (`uuid.v4()`) and send it as `idempotency_key`. If the request drops and retries, the server will not create duplicate SOS dispatches!

**Request:**
```json
{
  "latitude": 30.2846,
  "longitude": 78.9815,
  "emergency_type": "LANDSLIDE_TRAPPED",
  "severity": "CRITICAL",
  "notes": "Elderly grandmother cannot walk, mud entering house",
  "household_code": "H101",
  "idempotency_key": "c4b96f2a-79a8-48bc-9f93-01824ab1192d"
}
```

**Response (201 Created or 200 OK):**
```json
{
  "id": 14,
  "sos_code": "SOS-WEB-9B41E2",
  "idempotency_key": "c4b96f2a-79a8-48bc-9f93-01824ab1192d",
  "user_id": 4,
  "household_code": "H101",
  "latitude": 30.2846,
  "longitude": 78.9815,
  "emergency_type": "LANDSLIDE_TRAPPED",
  "severity": "CRITICAL",
  "status": "PENDING",
  "priority_score": 92.4,
  "notes": "Elderly grandmother cannot walk, mud entering house",
  "assigned_team_id": null,
  "assigned_shelter_id": null,
  "via_mesh": "FALSE",
  "hops_count": 0,
  "created_at": "2026-10-31T12:00:00Z"
}
```

#### `GET /sos/active`
Returns all unresolved SOS calls sorted by priority score (`PENDING`, `ASSIGNED`, `DISPATCHED`).

#### `PATCH /sos/{id}/status`
Update rescue status:
```json
{
  "status": "DISPATCHED",
  "assigned_team_id": "NDRF Quick Response Team 1",
  "notes": "Team en-route via Ridge Road"
}
```

#### `POST /sos/{id}/assign` (Rescue / Admin)
Assign responder team and generate audit trail:
```json
{
  "team_name": "NDRF Quick Response Team 1",
  "notes": "Priority evacuation"
}
```

---

### 5.3 Priority Queue (`/priority`)

#### `GET /priority/queue`
Returns sorted rescue priority queue evaluated with:
$$\text{Score} = \text{Severity} (30) + \text{Vulnerability} (20) + \text{Zone Risk} (15) + \text{Isolation} (10) + \text{Time Decay} (10) + \text{Medical Urgency} (10) + \text{ML Risk} (5)$$

---

### 5.4 Hazard Zones & ML Prediction (`/disaster`)

#### `GET /disaster/zones`
Monitored disaster zones, real-time risk level (`LOW`, `MEDIUM`, `HIGH`), polygon coordinates, and rainfall.

#### `POST /disaster/predict/landslide`
Runs the Random Forest ML model:
```json
{
  "rainfall_24h": 185.0,
  "cumulative_rainfall_7d": 380.0,
  "slope": 38.0,
  "elevation": 1250.0,
  "historical_disasters": 2
}
```

---

### 5.5 Evacuation Routing & Shelters (`/routing`, `/shelters`)

#### `POST /routing/safe-route`
Calculates road routing with automatic hazard zone avoidance:
```json
{
  "origin": { "lat": 30.2846, "lng": 78.9815 },
  "destination": { "lat": 30.2900, "lng": 78.9900 },
  "avoid_high_risk": true
}
```
**Response Key Points:**
- `is_verified_safe`: `true` if OpenRouteService verified road navigation avoiding hazard polygons.
- If network/routing provider is offline, returns `routing_status: "DEGRADED_STRAIGHT_LINE"` and `is_verified_safe: false` with explicit safety warnings.

#### `GET /shelters/`
List emergency shelters with live `available_beds`, `operational_status`, and medical facilities.

---

### 5.6 Offline Mesh Gateway (`/mesh`)

#### `POST /mesh/packet`
When an Android device receives a peer Bluetooth/Wi-Fi Direct store-and-forward packet:
```json
{
  "message_id": "MESH-MSG-9812",
  "sender_id": "NODE-DEVICE-ALPHA",
  "type": "SOS",
  "latitude": 30.2846,
  "longitude": 78.9815,
  "severity": "CRITICAL",
  "household_id": "H101",
  "timestamp": 1791370200,
  "ttl": 5,
  "hops": ["NODE-DEVICE-ALPHA", "RELAY-PHONE-B", "GATEWAY-CENTRAL-01"],
  "payload": {
    "vulnerabilities": ["Elderly", "Oxygen Dependency"],
    "battery_level": 64
  }
}
```

---

### 5.7 Real-Time WebSockets (`/ws`)

Connect to:
`ws://<BASE_URL>/api/v1/ws/`

#### Events Streamed:
1. `NEW_SOS` — When an emergency SOS is created online or ingested via mesh.
2. `SOS_STATUS_UPDATED` — When status changes (e.g. `DISPATCHED` -> `RESCUED`).
3. `ZONE_RISK_UPDATED` — When risk level changes.
4. `RESCUE_ASSIGNED` — When a unit accepts an assignment.
5. `HEARTBEAT` — Sent every 30s by server:
   ```json
   {
     "event": "HEARTBEAT",
     "data": { "server_time": "2026-10-31T12:00:00Z", "clients": 3 }
   }
   ```
To keep alive: send `"ping"` string over WS, server will reply `"pong"`.

---

## 6. Offline Storage Architecture (Drift/SQLite)

Store SOS messages locally before transmission:

```
[User Taps SOS]
      ↓
[Save in SQLite: status = 'QUEUED', id = uuid.v4()]
      ↓
[Check Connectivity (Internet or Mesh Peer)]
   ↙                                    ↘
(Online)                             (Offline)
   ↓                                    ↓
HTTP POST /api/v1/sos/               Broadcast via BLE Mesh
   ↓                                    ↓
Update local status: 'ACKNOWLEDGED'   Store & Relay to Peers
```

