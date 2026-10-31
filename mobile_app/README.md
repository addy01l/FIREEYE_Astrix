# FIRE-EYE (FIREEYE_Astrix) — Tactical Disaster Management & Emergency Response Mobile Application

A production-grade cross-platform Flutter application engineered for disaster management, wildfire tracking, thermal hotspot monitoring, casualty triage, and tactical emergency coordination. Designed to integrate directly with the **FIRE-EYE Python FastAPI** backend, NASA FIRMS satellite telemetry, and PostGIS geospatial pipelines.

---

## 🛰️ Architecture & Technology Stack

- **Framework**: Flutter 3.x (Dart null-safe)
- **UI Design System**: Material Design 3 with custom Dark Navy & Charcoal Tactical Operations Theme
- **State Management**: `Provider` (`ChangeNotifierProvider`, `MultiProvider`)
- **Networking**: `Dio` with token interceptor, exponential retry, and standardized error parsing
- **Real-Time Telemetry**: WebSocket client connecting to `/ws/alerts` with auto-reconnection
- **Geospatial Mapping**: `flutter_map` with OpenStreetMap (OSM) tile server and interactive tactical markers
- **Location Services**: `geolocator` with runtime GPS permission flows
- **Secure Persistence**: `flutter_secure_storage` for tactical authentication tokens
- **Local Preferences**: `shared_preferences` for gateway host caching and UI options
- **Typography & Icons**: `google_fonts` (Inter & JetBrains Mono) and `lucide_icons_flutter`

---

## 📁 Repository Directory Structure

```
mobile_app/
├── lib/
│   ├── main.dart                      # App entrypoint (initialization & orientation lock)
│   ├── app.dart                       # MultiProvider wiring & Dark Theme configuration
│   ├── core/
│   │   ├── config/
│   │   │   └── api_config.dart        # Configurable API gateways & route contracts
│   │   ├── constants/
│   │   │   └── app_constants.dart     # Severity keys, storage keys, branding constants
│   │   ├── network/
│   │   │   ├── api_client.dart        # Dio singleton, timeout handling & auth interceptor
│   │   │   └── websocket_service.dart # Auto-reconnecting client for /ws/alerts
│   │   ├── storage/
│   │   │   └── secure_storage_service.dart # Secure hardware enclave token storage
│   │   ├── theme/
│   │   │   ├── app_colors.dart        # Tactical navy, emergency red, warning orange
│   │   │   └── app_theme.dart         # Material 3 dark/light themes with mono headers
│   │   └── utils/
│   │       └── error_handler.dart     # Standardized HTTP/network error parser
│   ├── models/
│   │   ├── alert_model.dart           # Bulletins & WebSocket alerts schema
│   │   ├── anomaly_model.dart         # NASA FIRMS thermal anomaly schema (matches FastAPI)
│   │   ├── incident_model.dart        # Emergency incident report schema
│   │   ├── rescue_center_model.dart   # Rescue center & vehicle fleet schema
│   │   ├── shelter_model.dart         # Relief camp & capacity schema
│   │   ├── user_model.dart            # Tactical operator identity & RBAC roles
│   │   └── victim_model.dart          # Casualty registry & triage status schema
│   ├── providers/
│   │   ├── alert_provider.dart        # Real-time WebSocket bulletins state
│   │   ├── anomaly_provider.dart      # /api/anomalies/live ingestion state
│   │   ├── auth_provider.dart         # Operator login, session & role switcher
│   │   ├── incident_provider.dart     # Incidents management & creation state
│   │   ├── rescue_center_provider.dart# Rescue bases & fleet state
│   │   ├── shelter_provider.dart      # Shelter capacity & occupancy state
│   │   └── victim_provider.dart       # Victim tracking & triage state
│   ├── services/
│   │   ├── anomaly_service.dart       # GET /api/anomalies/live & GET /
│   │   ├── auth_service.dart          # Authentication & token caching
│   │   ├── incident_service.dart      # Incidents REST client & local store
│   │   ├── rescue_center_service.dart # Rescue bases REST client & local store
│   │   ├── shelter_service.dart       # Shelters REST client & local store
│   │   └── victim_service.dart        # Victim caserecords & triage updater
│   ├── widgets/
│   │   ├── brand_logo.dart            # FIRE-EYE tactical insignia widget
│   │   ├── empty_state_view.dart      # Accessible empty state container
│   │   ├── error_state_view.dart      # Network/server error retry container
│   │   ├── loading_view.dart          # Tactical pulse progress indicator
│   │   ├── stat_kpi_card.dart         # Operational metric card with severity tones
│   │   └── status_chip.dart           # Color-coded badge for severity & states
│   └── screens/
│       ├── splash/                    # Animated tactical boot screen & session restore
│       ├── auth/                      # Login & Registration with gateway switcher
│       ├── dashboard/                 # Command Dashboard with KPIs & FastAPI health pill
│       ├── map/                       # Fullscreen Live Map (OSM + Hotspots + Incidents)
│       ├── incidents/                 # Incident List, Detail Dossier & Create Report
│       ├── rescue_centers/            # Rescue Bases, Personnel & Vehicle Readiness
│       ├── shelters/                  # Camp Directory, Occupancy Bars & Contact
│       ├── victims/                   # Searchable Casualty Registry & Triage Updates
│       ├── notifications/             # Real-time /ws/alerts & Emergency Bulletins
│       ├── profile/                   # Identity Dossier, Role Simulator & Gateway IP Config
│       └── main_navigation_shell.dart # Tactical Navigation Bar & Command Drawer
└── test/
    ├── unit_test.dart                 # Data model & WebSocket parser unit tests
    └── widget_test.dart               # Core widget rendering & interaction smoke tests
```

---

## 🔌 FastAPI Backend Integration

### 1. Verified Live Endpoints (Source of Truth)
Inspected directly from `fire-eye-platform/backend-api/app/main.py`:
- `GET /`: Health check (`{"status": "online", "message": "FIRE-EYE Backend Operational"}`)
- `GET /api/anomalies/live`: Returns list of live thermal anomalies from NASA FIRMS & ML Engine:
  ```json
  [
    {
      "id": 1,
      "latitude": 30.3165,
      "longitude": 78.0322,
      "brightness": 325.4,
      "frp": 12.5,
      "is_wildfire": true
    }
  ]
  ```
- `WebSocket /ws/alerts`: Broadcasts real-time thermal anomaly triggers to connected mobile clients.

### 2. Operational Endpoints with Graceful Fallback
For endpoints not yet implemented on the FastAPI server (`/api/v1/auth/login`, `/api/v1/incidents/`, `/api/v1/shelters/`, `/api/v1/rescue-centers/`, `/api/v1/victims/`), the app handles HTTP requests cleanly:
- Attempts the REST call to the configured FastAPI server.
- If the endpoint returns 404 or connection failure, it seamlessly falls back to pre-defined operational disaster records tagged with `[FIELD REPORT]` or `[DEMO RECORD]`, ensuring zero crashes and full demo readiness.
- Live data from `/api/anomalies/live` is marked with `[LIVE FASTAPI]`.

---

## ⚙️ Configuration & Gateway Switcher

The application supports dynamic switching of the backend host without recompiling:
1. **Android Emulator**: Uses `http://10.0.2.2:8000`
2. **Windows Desktop**: Uses `http://127.0.0.1:8000`
3. **Physical Android Device**: Uses your PC's local Wi-Fi IP address (e.g., `http://192.168.1.15:8000`)

*You can change the FastAPI URL at any time directly from the Login Screen (top-right gear icon) or Profile Screen (FastAPI Backend Gateway section).*

---

## 🚀 Running the Application

### Step 1: Start the FastAPI Backend
Ensure your Python virtual environment has dependencies installed and start uvicorn:
```bash
cd "fire-eye-platform/backend-api"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Step 2: Run Flutter Tests
Ensure all 7 unit and widget tests pass:
```bash
cd mobile_app
flutter test
```

### Step 3: Run the App on Windows Desktop
```bash
cd mobile_app
flutter run -d windows
```

### Step 4: Run the App on Android Emulator or Device
```bash
cd mobile_app
flutter run -d android
```

---

## 🛡️ Security & Tactical Features
- **Hardware Token Vault**: JWT tokens stored using `flutter_secure_storage`.
- **Role Simulation**: Quickly switch between `COMMANDER`, `RESPONDER`, `VOLUNTEER`, and `CITIZEN` roles in the Profile tab to test permissions.
- **Cleartext Traffic Policy**: Android manifest configured narrowly with `android:usesCleartextTraffic="true"` for local development against `http://` localhost. Production builds should route through HTTPS.
- **Triage Privacy**: Confidential casualty medical notes are protected behind role-based actions.
