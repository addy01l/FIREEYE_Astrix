# 📋 FIRE-EYE Task & Progress Tracker

This document tracks completed milestones and the roadmap for building the role-based Flutter mobile application.

---

## ✅ Completed Tasks

### 1. Backend Stabilization & Reconstruction (FastAPI)
- [x] **Core Architecture & Security:**
  - Implemented bcrypt password hashing and JWT access & refresh token lifecycle.
  - Built server-side Role-Based Access Control (RBAC) with 4 roles: `CITIZEN`, `RESCUE`, `VOLUNTEER`, `ADMIN`.
  - Added structured audit logging (`AuditEvent`).
- [x] **SOS Lifecycle & Idempotency:**
  - Added `idempotency_key` deduplication on `POST /sos/`.
  - Added `RescueAssignment` entity and assignment endpoints (`POST /sos/{id}/assign`).
  - Added status tracking (`PENDING` -> `ASSIGNED` -> `DISPATCHED` -> `RESCUED` -> `CANCELLED`).
- [x] **Machine Learning Pipeline:**
  - Corrected model artifact loading path (`ml/models/landslide_model.joblib`).
  - Ensured 100% feature order parity: `[rainfall_24h, cumulative_rainfall_7d, slope, elevation, historical_landslides]`.
  - Added calibrated hydrological fallback and operational disclaimers.
- [x] **Routing & Shelters:**
  - OpenRouteService hazard polygon avoidance.
  - Implemented safety rule: straight-line fallback is never labeled safe; flagged as `UNVERIFIED_FALLBACK` with explicit warnings.
  - Added shelter occupancy tracking and live bed availability calculation.
- [x] **Offline Mesh Gateway:**
  - Multi-tier deduplication (database persistence + Redis cache).
  - Store-and-forward packet ingestion with audit logs (`GET /mesh/messages`).
- [x] **Test Coverage:**
  - 13 comprehensive integration tests in `backend/tests/` passing with 100% success.
- [x] **Seeded Scenarios:**
  - Pre-configured demo accounts for all 4 roles (Password: `securepassword`).

### 2. Frontend Decoupling & Flutter Handover
- [x] Removed all legacy React/Vite web application files (`frontend/` directory completely removed).
- [x] Exported full OpenAPI 3.0 specification (`docs/openapi.json`) for automated Dart code generation.
- [x] Created comprehensive Flutter Integration Guide (`docs/FLUTTER_INTEGRATION_GUIDE.md`) covering:
  - Base URLs for Android Emulator (`10.0.2.2:8000`) and physical devices.
  - Dio client configuration and Auth Interceptor.
  - Offline-first SQLite/Drift queue for SOS messages.
  - Real-time WebSocket connection handling.
  - Role-based screen requirements.

---

## 📱 Next Steps (Flutter Mobile Developer Handover)

### Flutter Application (`mobile/`)
- [ ] Initialize Flutter project: `flutter create --org org.fireeye mobile`.
- [ ] Add dependencies: `flutter_riverpod`, `dio`, `drift`, `sqlite3_flutter_libs`, `flutter_secure_storage`, `geolocator`, `google_maps_flutter`, `web_socket_channel`.
- [ ] Implement typed models from `docs/openapi.json`.
- [ ] Build shared navigation and role-based route guards with `GoRouter`.
- [ ] **Role Screens**:
  - `CITIZEN`: One-tap SOS button, offline queue status badge, hazard zone warnings, safe shelter list.
  - `RESCUE`: Live priority rescue triage queue, victim details, team assignment, navigation map.
  - `VOLUNTEER`: Local assistance tasks, household support, relief supply check-ins.
  - `ADMIN`: Command center overview, risk zones, shelter capacity overrides, audit log view.
- [ ] Implement physical Android device mesh communications (BLE / Nearby Connections).
