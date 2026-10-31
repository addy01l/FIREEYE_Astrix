# 🔥 FIRE-EYE

> **Inclusive & Fault-Tolerant Disaster Response System**  
> *Predict Hazard Risk • Prioritize Vulnerable Populations • Offline Mesh Store-and-Forward • Safe Evacuation Routing*

FIRE-EYE is a resilient disaster management backend and emergency response platform built for crises such as landslides, flash floods, and cloudbursts in mountainous regions (e.g. Uttarakhand, India). The system supports **Citizens**, **Rescue Teams**, **Volunteers**, and **Administrators** through server-side Role-Based Access Control (RBAC).

---

## 📁 Repository Structure

```text
├── backend/
│   ├── app/
│   │   ├── api/            # REST and WebSocket endpoints
│   │   │   ├── auth.py     # JWT Login, Register, Refresh, Me
│   │   │   ├── sos.py      # Idempotent SOS creation, assignment, status
│   │   │   ├── priority.py # Multi-factor triage ranking queue
│   │   │   ├── disaster.py # Risk zones & ML landslide prediction
│   │   │   ├── households.py# Vulnerable household registry
│   │   │   ├── shelters.py # Emergency shelters & live capacity
│   │   │   ├── mesh.py     # Offline mesh packet gateway & audit logs
│   │   │   ├── audit.py    # Operational audit trail
│   │   │   └── websocket.py# Real-time WebSocket connection
│   │   ├── core/           # Security (bcrypt, JWT), RBAC permissions, config
│   │   ├── models/         # SQLAlchemy ORM entities
│   │   ├── schemas/        # Pydantic v2 validation models
│   │   ├── seeds/          # Demo scenario data seeder (4 roles pre-configured)
│   │   ├── services/       # ML inference, priority engine, routing, mesh gateway
│   │   ├── database.py     # Database engine & session factory
│   │   └── main.py         # FastAPI application entry point
│   ├── tests/              # 16 comprehensive pytest integration tests (100% pass)
│   ├── alembic/            # Database migration management
│   ├── Dockerfile          # Production container specification
│   ├── requirements.txt    # Locked Python dependencies
│   └── .env.example        # Environment variable configuration template
├── docs/
│   ├── FLUTTER_INTEGRATION_GUIDE.md # Complete handover guide for Flutter developers
│   ├── openapi.json        # Exported OpenAPI 3.0 schema for Dart codegen
│   ├── API_SPEC.md         # API specification and contract details
│   ├── OFFLINE_PROTOCOL.md # Store-and-forward mesh packet specification
│   └── DEMO_SCRIPT.md      # Disaster scenario demonstration script
├── ml/                     # AI & Intelligence Core (from fireeye-ai-final)
│   ├── data/               # Synthetic geological training data
│   ├── models/             # Retrained Random Forest pipeline (risk_model.joblib)
│   ├── intelligence_pipeline.py # Unified 4-stage AI risk-priority-route pipeline
│   ├── priority_engine.py  # 4-factor triage formula (40/30/20/10)
│   ├── risk_prediction.py  # Categorical soil + environmental inference
│   ├── route_optimizer.py  # Dijkstra shortest route with blocked road handling
│   └── train_model.py      # ML training pipeline (87% accuracy)
└── simulation/
    ├── mesh_simulator.py   # Multi-hop mesh node store-and-forward simulator
    └── scenario_runner.py  # End-to-end disaster scenario simulator
```

---

## 🚀 Quickstart: Running the Backend

### 1. Prerequisites
- Python 3.11 or 3.12 installed on your system.

### 2. Setup Virtual Environment & Install Dependencies
```powershell
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment (Windows PowerShell)
.\venv\Scripts\Activate.ps1
# On Linux/macOS: source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Seed Demo Data (Uttarakhand Scenario)
This populates the database with disaster risk zones, vulnerable households, safe shelters, and demo users for all 4 roles:
```powershell
python -m app.seeds.seed_data
```

### 4. Start the FastAPI Server
```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- **Interactive API Documentation (Swagger)**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **OpenAPI Schema**: [http://localhost:8000/api/v1/openapi.json](http://localhost:8000/api/v1/openapi.json)
- **Health Check**: [http://localhost:8000/health](http://localhost:8000/health)

---

## 🧪 Running Automated Tests

All 13 integration tests pass with 100% success:
```powershell
cd backend
$env:PYTHONPATH="."
.\venv\Scripts\pytest.exe -v
```

---

## 📱 Mobile App Development (Flutter Handover)

The previous web frontend has been decoupled and the backend is ready for Flutter Android/iOS application development:

- Detailed integration instructions: **[FLUTTER_INTEGRATION_GUIDE.md](docs/FLUTTER_INTEGRATION_GUIDE.md)**.
- Complete typed schema export: **[openapi.json](docs/openapi.json)** (can be directly imported into Postman or used with `openapi_generator_cli` to generate Dart client models).

### Base URLs for Flutter:
- **Android Emulator**: `http://10.0.2.2:8000/api/v1`
- **Physical Device**: `http://<HOST_IP>:8000/api/v1`
- **Real-time WebSockets**: `ws://10.0.2.2:8000/api/v1/ws/`

### Start mobile app with backend (Windows)

From the repository root, run:

```powershell
.\start-mobile.ps1
```

The launcher starts FastAPI on `0.0.0.0:8000`, waits for `/health`, launches
Flutter, and stops the backend when Flutter exits. Pass `-Device <id>` to select
a device or `-Release` for a release build:

```powershell
.\start-mobile.ps1 -Device emulator-5554
.\start-mobile.ps1 -Release
```

For a physical device, configure the app gateway to the host computer's LAN IP
from the login screen. The computer firewall must allow inbound TCP port 8000.

### Pre-Seeded Test Credentials:
All accounts use password: **`securepassword`**
- **Admin**: `admin`
- **Rescue Commander**: `commander`
- **Volunteer**: `volunteer1`
- **Citizen**: `citizen1`
