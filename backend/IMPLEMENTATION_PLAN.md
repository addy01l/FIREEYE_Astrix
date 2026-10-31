# FIRE-EYE Backend Implementation Plan

This document breaks down the complete implementation of the FIRE-EYE backend into actionable, logical stages. Following this plan ensures we don't get blocked by dependencies and can deliver a working system efficiently.

---

## Stage 1: Foundation & Database Setup (The Core)
*Goal: Get the basic server running and define how our data is stored, particularly geospatial data.*

1. **Initialize Project:**
   * Set up Python virtual environment (`venv` or `uv`).
   * Install core dependencies: `fastapi`, `uvicorn`, `sqlalchemy`, `geoalchemy2`, `psycopg2-binary`, `redis`, `pydantic`.
   * Create standard folder structure (`/routers`, `/models`, `/schemas`, `/services`, `/core`).
2. **Docker Environment:**
   * Create a `docker-compose.yml` for local development containing:
     * **PostgreSQL + PostGIS** (for the database).
     * **Redis** (for cache and Pub/Sub).
3. **Database Schemas (SQLAlchemy + GeoAlchemy2):**
   * `User` model (Rescue workers, admins).
   * `SOSRequest` model (Requires PostGIS `Geometry(POINT)` for lat/long).
   * `RiskZone` model (Requires PostGIS `Geometry(POLYGON)` for flood/fire areas).
   * `Shelter` model (Locations of safe zones).
4. **Initial Migrations:**
   * Set up `alembic` to manage database migrations and generate the initial schema.

---

## Stage 2: Mesh Gateway & Ingestion Layer (The Offline Protocol)
*Goal: Allow the backend to receive and process offline mesh SOS messages from the gateways.*

1. **Gateway API Endpoint (`POST /api/v1/sos/mesh`):**
   * Create Pydantic schemas that match the `OFFLINE_PROTOCOL.md` (handling `message_id`, `ttl`, `hops`, `payload.vulnerabilities`, etc.).
2. **Duplicate Prevention:**
   * Integrate Redis.
   * Before processing an SOS, check if `message_id` exists in Redis `seen_messages`. If yes, drop it to prevent gateway spam. If no, cache it for 24 hours.
3. **Data Normalization:**
   * Convert the mesh payload into our standard database format, ready for the priority engine.

---

## Stage 3: ML Integration & Priority Engine (The Brain)
*Goal: Intelligently sort incoming SOS requests so rescue workers save the most critical people first.*

1. **ML Model Integration:**
   * Load the pre-trained `joblib` model (XGBoost/Random Forest) inside a FastAPI startup event so it stays in memory.
   * Create an internal service function: `predict_risk(lat, lon) -> Probability Score`.
2. **The Priority Engine Logic (`/services/priority.py`):**
   * Build the scoring algorithm. Factors to calculate:
     * **Vulnerability:** Add points for `ELDERLY`, `MOBILITY_IMPAIRED`, children, etc. (Extracted from the mesh payload).
     * **Severity:** Add points if severity is `CRITICAL`.
     * **Environmental Risk:** Query the ML model or PostGIS RiskZones to see if the SOS coordinates are in imminent danger. Add massive points if true.
3. **Finalize SOS Save:**
   * Connect the Gateway API (Stage 2) -> Priority Engine (Stage 3) -> Save to PostgreSQL.

---

## Stage 4: Real-Time Dashboard Layer (The Eyes)
*Goal: Push live SOS updates to the React dashboard instantly without them needing to refresh.*

1. **WebSockets Setup:**
   * Create a WebSocket endpoint (`/ws/dashboard`).
   * Manage active connection pools (handling disconnects/reconnects).
2. **Redis Pub/Sub Integration:**
   * Every time an SOS is successfully saved in Stage 3, publish the JSON payload to a Redis channel (e.g., `sos_updates`).
3. **Broadcast Manager:**
   * Have a background asyncio task listening to the Redis channel. When it hears a message, push it to all connected WebSocket clients.

---

## Stage 5: Routing & Map Data APIs (The Navigator)
*Goal: Provide the frontend with the map data and safe routes to victims.*

1. **Map Data Endpoints:**
   * `GET /api/v1/map/risk-zones`: Returns GeoJSON of all active danger zones.
   * `GET /api/v1/map/shelters`: Returns GeoJSON of nearby shelters.
2. **OSRM (Open Source Routing Machine) Integration:**
   * Set up an OSRM Docker container (if running locally) or connect to an external OSRM API.
   * Build the `GET /api/v1/route` endpoint.
   * **Advanced (Road Penalties):** Query PostGIS to find which roads intersect with `RiskZones`. Apply penalties to those roads when asking OSRM for a route, ensuring the returned path is *safe*, not just fast.

---

## Stage 6: Security & Final Polish
*Goal: Lock down the API and prepare for deployment.*

1. **Authentication (JWT):**
   * Implement `/api/v1/auth/login` for rescue workers.
   * Secure dashboard endpoints and WebSockets with JWT validation. 
   *(Note: The Gateway mesh ingestion endpoint might use a different API key system since it's automated).*
2. **Testing:**
   * Write `pytest` unit tests, focusing heavily on the Priority Engine logic and Duplicate Message dropping.
3. **Deployment Prep:**
   * Finalize `.env.example`.
   * Ensure `Dockerfile` is optimized for production (using Gunicorn with Uvicorn workers).
