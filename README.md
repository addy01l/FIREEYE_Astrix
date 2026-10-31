# 🔥 FIRE-EYE: Inclusive & Fault-Tolerant Disaster Response System

[![Backend Live](https://img.shields.io/badge/Render-Live_API-46E3B7?style=for-the-badge&logo=render&logoColor=white)](https://fireeye-astrix-backend.onrender.com/health)
[![Database](https://img.shields.io/badge/Database-Supabase_PostgreSQL-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Redis](https://img.shields.io/badge/Redis-Upstash_TLS-FF4438?style=for-the-badge&logo=redis&logoColor=white)](https://upstash.com)
[![Mobile App](https://img.shields.io/badge/Frontend-Flutter_3.47-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![AI / ML](https://img.shields.io/badge/ML-Scikit--learn_RandomForest-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white)](https://scikit-learn.org)
[![Tests](https://img.shields.io/badge/Tests-100%25_Passing-brightgreen?style=for-the-badge&logo=pytest&logoColor=white)](#-automated-testing--quality-assurance)

> **Predict Hazard Risk • Prioritize Vulnerable Populations • Offline Mesh Store-and-Forward • Live Commander Tactical Queue • Safe Evacuation Routing**

FIRE-EYE is an end-to-end mission-critical disaster management and rescue coordination platform designed for mountainous and isolated disaster-prone areas (such as Uttarakhand, Himalayas). When roads collapse, power grids fail, or cell towers go dark, FIRE-EYE ensures emergency distress beacons reach rescue commanders with dynamic multi-factor priority scores, offline store-and-forward mesh synchronization, and real-time distributed Pub/Sub broadcasting.

---

## 🌐 Live Production Deployment

| Component | Provider / Platform | Production URL / Endpoint | Status |
| :--- | :--- | :--- | :--- |
| **Backend API** | Render Cloud (Python 3.11) | `https://fireeye-astrix-backend.onrender.com` | **Active & Live** |
| **Interactive Docs** | FastAPI Swagger UI | [https://fireeye-astrix-backend.onrender.com/docs](https://fireeye-astrix-backend.onrender.com/docs) | **Interactive 200 OK** |
| **Health & Telemetry**| Fast System Check | [https://fireeye-astrix-backend.onrender.com/health](https://fireeye-astrix-backend.onrender.com/health) | `{"status":"ok","redis":"connected"}` |
| **Database** | Supabase (AWS) | PostgreSQL 17 + PostGIS 3.3.7 Extension | Resilient Connection Pooling |
| **Distributed Cache** | Upstash Redis | Port 6379 via TLS (`rediss://`) | Real-time Pub/Sub & Mesh Deduplication |
| **Mobile & Web App** | Flutter Cross-Platform | Android APK & Web (`mobile_app/build/web`) | Direct Cloud Sync |

---

## 🏗️ System Architecture

```mermaid
flowchart TD
    subgraph Citizens_Victims["Citizens & Affected Residents"]
        CitizenApp["📱 Flutter Mobile / Web App\n• SOS Distress Beacon\n• Offline SQLite Queue\n• Evacuation Navigation"]
    end

    subgraph Mesh_Network["Field Communications Layer"]
        MeshGateway["📡 Hybrid Mesh Gateway\n• Store-and-Forward\n• Multi-hop TTL Routing\n• Zero-Cellular Recovery"]
    end

    subgraph Cloud_Backend["FIRE-EYE Core Engine (FastAPI on Render)"]
        API["⚡ FastAPI REST & WebSocket Server"]
        PriorityEngine["🎯 Dynamic Priority Engine\nScore = 0.4*Sev + 0.3*Vuln + 0.2*Risk + 0.1*Iso"]
        MLEngine["🤖 Random Forest ML Pipeline\n• Soil Susceptibility (OneHot)\n• Slope, Elevation, Rainfall"]
    end

    subgraph Data_Layer["Production Data & Event Infrastructure"]
        Postgres[("🐘 Supabase PostgreSQL + PostGIS\n• Durable SOS Records\n• Geo-Spatial Hazard Zones\n• Shelters & Households")]
        UpstashRedis[("⚡ Upstash Redis (TLS)\n• O(1) Fast-Path Deduplication\n• fire_eye_events Pub/Sub Channel")]
    end

    subgraph Command_Rescuers["Rescue Commanders & Emergency Fleet"]
        CommanderConsole["🛡️ Tactical Command Console\n• Live Ranked Rescue Queue\n• Real-Time SOS Alert Badges\n• Triage & Squad Dispatching\n• Interactive Leaflet Map"]
    end

    CitizenApp -->|"HTTPS / WSS (Live)"| API
    CitizenApp -.->|"Offline Packet Queue"| MeshGateway
    MeshGateway -->|"Batch Mesh Ingestion"| API
    API <--> Postgres
    API <--> UpstashRedis
    API --> PriorityEngine
    PriorityEngine <--> MLEngine
    UpstashRedis -->|"Instant Pub/Sub Broadcast"| API
    API -->|"WebSocket Event Stream"| CommanderConsole
    API <--> CommanderConsole
```

---

## ⚡ Core Capabilities

### 1. 🚨 Citizen SOS Distress Beacon & Dynamic Priority Scoring
- Citizens transmit emergency beacons specifying GPS coordinates, stranded people count, emergency type (*Trapped / Structural Collapse*, *Wildfire*, *Flash Flood*), and vulnerable conditions (*infants, elderly, severe injury*).
- **Dynamic Scoring Formula**: Every SOS is scored server-side from 0 to 100 in real time:
  $$\text{Priority Score} = (\text{Severity} \times 0.40) + (\text{Vulnerability} \times 0.30) + (\text{Environmental Risk} \times 0.20) + (\text{Isolation} \times 0.10)$$
- Beacons immediately receive verified classification badges: **CRITICAL** ($\ge 75$), **HIGH** ($50 - 74$), or **MEDIUM** ($< 50$).

### 2. 🛡️ Commander Tactical Console & Live Rescue Queue
- When logged in as **Commander** or **Rescue Team**, incoming SOS beacons immediately surface on the **Command Dashboard** and the **Rescue Priority Queue** (`VictimsScreen`).
- Displays computed priority score badges, breakdown weights, distance, medical condition, and vulnerability flags.
- Real-time status update control: Commanders can transition beacons through operational states:
  $$\text{PENDING} \longrightarrow \text{ASSIGNED} \longrightarrow \text{DISPATCHED} \longrightarrow \text{RESCUED}$$

### 3. 📡 Offline Store-and-Forward Mesh Network
- If cellular or Wi-Fi connectivity drops, the mobile app queues SOS packets locally in encrypted persistent storage.
- When any node or mesh relay connects to the internet, packets synchronize with idempotent deduplication via Redis $O(1)$ fast-path caching.

### 4. 🤖 Machine Learning Landslide & Hazard Prediction
- Scikit-learn Pipeline combining `OneHotEncoder` and `RandomForestClassifier` trained on regional mountainous terrain datasets (87% accuracy).
- Evaluates categorical soil susceptibility (*Clay, Silty, Loamy, Sandy, Rocky*), slope degrees, elevation, and 24h cumulative rainfall.

### 5. 🏥 Shelter Management & Safe Evacuation Routing
- Live monitoring of emergency shelters, available bed capacity, medical staff, oxygen supply, and power backup.
- Evacuation routing engine using Dijkstra algorithm with dynamic hazard avoidance (reroutes around blocked roads and critical risk zones).

---

## 📁 Repository Structure

```text
hackathon-main/
├── backend/
│   ├── app/
│   │   ├── api/                 # REST & WebSocket endpoints
│   │   │   ├── auth.py          # JWT Login, Register, User Profile
│   │   │   ├── sos.py           # Dynamic priority SOS creation & status triage
│   │   │   ├── priority.py      # Ranked rescue triage queue (/api/v1/priority/queue)
│   │   │   ├── disaster.py      # Risk zones & ML landslide prediction
│   │   │   ├── households.py    # Vulnerable household registry
│   │   │   ├── shelters.py      # Emergency shelters & capacity
│   │   │   ├── mesh.py          # Offline mesh gateway & deduplication
│   │   │   ├── audit.py         # Security & operational audit trails
│   │   │   └── websocket.py     # Real-time WebSocket event connection
│   │   ├── core/                # JWT security, config, RBAC permission guards
│   │   ├── models/              # SQLAlchemy ORM database models
│   │   ├── schemas/             # Pydantic v2 schemas
│   │   ├── seeds/               # Idempotent demo database seeder
│   │   ├── services/            # ML inference, priority engine, mesh gateway, alerts
│   │   ├── database.py          # Resilient Supabase / SQLite connection engine
│   │   ├── redis_client.py      # Upstash TLS Redis client with credentials masking
│   │   └── main.py              # FastAPI application entry point & lifespan
│   ├── tests/                   # 16 automated pytest integration tests (100% pass)
│   ├── alembic/                 # Safe database migrations
│   ├── Dockerfile               # Production container definition
│   └── requirements.txt         # Production Python dependencies
├── mobile_app/                  # Flutter Cross-Platform Mobile & Web Client
│   ├── lib/
│   │   ├── core/
│   │   │   ├── config/          # ApiConfig pointing to live Render backend
│   │   │   ├── network/         # Dio ApiClient with resilient timeouts & error handler
│   │   │   └── theme/           # Tactical dark/light theme & colors
│   │   ├── models/              # Dart models (Incident, Victim, Shelter, Alert, User)
│   │   ├── providers/           # State providers (Incident, Victim, Shelter, Alert, Auth)
│   │   ├── screens/
│   │   │   ├── auth/            # Login & Register with cloud status indicator
│   │   │   ├── dashboard/       # Command Dashboard with Live SOS Queue & KPIs
│   │   │   ├── incidents/       # Incident Register & Dossier with Dispatch controls
│   │   │   ├── map/             # Interactive Leaflet live tactical map
│   │   │   ├── rescue_centers/  # Rescue fleet & posts
│   │   │   ├── shelters/        # Emergency shelters & capacity
│   │   │   ├── sos/             # Civilian Emergency SOS transmitter
│   │   │   └── victims/         # Commander Rescue Priority Queue & Triage modal
│   │   └── services/            # HTTP & offline services
│   ├── test/                    # 16 automated Flutter widget & unit tests (100% pass)
│   └── pubspec.yaml             # Flutter dependencies
├── ml/                          # Standalone AI/ML training scripts & joblib models
├── simulation/                  # Mesh network & disaster scenario simulation scripts
├── render.yaml                  # Render Infrastructure-as-Code blueprint
├── start-backend.ps1            # Local backend launcher
└── start-mobile.ps1             # One-click Flutter app launcher (defaults to Chrome)
```



---

## 🚀 How to Run the Project

### Option A: Run the Mobile / Web App (Instant, Connects to Live Backend)

From the project root:
```powershell
.\start-mobile.ps1
```
> **What this does:** Automatically resolves Flutter and launches the application in Google Chrome connected directly to the live Render cloud backend (`https://fireeye-astrix-backend.onrender.com`). No local Python server or Android SDK required!

To target a specific device:
```powershell
.\start-mobile.ps1 -Device windows       # Windows desktop app
.\start-mobile.ps1 -Device emulator-5554 # Android emulator
```

---

### Option B: Building Android Release APK

1. Ensure the Android SDK is installed (via Android Studio or `winget install Google.AndroidStudio`).
2. Accept Android licenses:
   ```powershell
   flutter doctor --android-licenses
   ```
3. Build the release APK:
   ```powershell
   cd mobile_app
   flutter build apk --release
   ```
   Output APK: `mobile_app/build/app/outputs/flutter-apk/app-release.apk`

---

### Option C: Running the Backend Locally

```powershell
cd backend

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Start FastAPI
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
- Local Swagger UI: [http://localhost:8000/docs](http://localhost:8000/docs)
- Local Health Check: [http://localhost:8000/health](http://localhost:8000/health)

---

## 👥 Pre-Configured Test Accounts

All accounts use password: **`securepassword`**

| Role | Username | Password | Purpose & Capabilities |
| :--- | :--- | :--- | :--- |
| **Incident Commander** | `commander` | `securepassword` | Accesses Tactical Command Dashboard, Live Map, Triage Dispatch, and Rescue Priority Queue. |
| **Citizen** | `citizen1` | `securepassword` | Broadcasts Emergency SOS beacons, views regional safe shelters and hazard alerts. |
| **Community Volunteer**| `volunteer1` | `securepassword` | Community responder supporting shelters and field observation logs. |
| **System Administrator**| `admin` | `securepassword` | Full system audit trail inspection, user management, and configuration. |

---

## 📡 REST API Reference

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `GET` | `/health` | System health check & Redis connection status | No |
| `POST` | `/api/v1/auth/register` | Register new user account | No |
| `POST` | `/api/v1/auth/login` | Authenticate & retrieve JWT bearer token | No |
| `GET` | `/api/v1/auth/me` | Fetch authenticated user profile | Bearer Token |
| `POST` | `/api/v1/sos/` | Create Emergency SOS with auto-computed priority score | Optional |
| `GET` | `/api/v1/sos/active` | Retrieve all active SOS requests sorted by priority | No |
| `GET` | `/api/v1/sos/{id}` | Get specific SOS details by numeric ID or code | No |
| `PATCH`| `/api/v1/sos/{id}/status`| Update triage status (`PENDING`, `DISPATCHED`, `RESCUED`) | Optional |
| `GET` | `/api/v1/priority/queue`| Retrieve fully ranked rescue queue with component breakdown | No |
| `GET` | `/api/v1/disaster/zones`| Get monitored risk zones & hazard levels | No |
| `POST` | `/api/v1/disaster/predict/landslide` | Run Random Forest ML inference on geological parameters | No |
| `GET` | `/api/v1/shelters/` | List safe emergency shelters & occupancy | No |
| `POST` | `/api/v1/routing/safe-route` | Compute hazard-avoiding Dijkstra evacuation route | No |
| `POST` | `/api/v1/mesh/packet` | Ingest store-and-forward mesh packet with Redis deduplication | No |
| `WS` | `/api/v1/ws/` | Real-time WebSocket stream for instant emergency alerts | No |

---

## 🧪 Automated Testing & Quality Assurance

Both the backend and mobile frontend maintain comprehensive automated test suites:

### Backend Pytest Suite
```powershell
cd backend
.\venv\Scripts\python.exe -m pytest tests/ -v
```
- **Results:** **16 / 16 PASSED (100%)**
- **Covers:** JWT authentication, RBAC authorization, dynamic SOS priority calculation, idempotency, triage status transitions, ML inference pipeline, Dijkstra safe routing, Upstash Redis Pub/Sub, and mesh deduplication.

### Flutter Test Suite
```powershell
cd mobile_app
flutter test
flutter analyze
```
- **Results:** **16 / 16 PASSED (100%)**
- **Flutter Analyzer:** **0 issues found**
- **Covers:** Offline SOS queueing in persistent storage, data model serialization, responsive UI layout without RenderFlex overflows across different screen dimensions.

---

## 🔐 Environment Variables

The backend loads configuration from `backend/.env` or system environment variables:

| Variable | Description | Default / Example |
| :--- | :--- | :--- |
| `PROJECT_NAME` | Service display name | `FIRE-EYE Disaster Response Engine` |
| `ENVIRONMENT` | Runtime environment | `production` or `development` |
| `DATABASE_URL` | PostgreSQL or SQLite connection string | `postgresql://user:pass@host:5432/postgres?sslmode=require` |
| `REDIS_URL` | Redis URL with TLS support | `rediss://default:token@host.upstash.io:6379` |
| `SECRET_KEY` | Secret key for JWT signing | `fire-eye-production-grade-secret-key-2026` |
| `ML_MODEL_PATH` | Path to Scikit-learn joblib model | `ml/models/risk_model.joblib` |
| `PORT` | Listening HTTP port | `8000` (Render dynamically injects `$PORT`) |

---

## 🛡️ License

Built with ❤️ for disaster resilience during emergencies. Released under the MIT License.
