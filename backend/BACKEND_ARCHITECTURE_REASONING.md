# FIRE-EYE Backend Architecture & Reasoning

This document details the backend architecture for the FIRE-EYE system and explains the **reasoning behind every technological and architectural choice**. This will help you understand *why* the backend is designed this way.

## 1. Core Backend Framework: FastAPI (Python)

**What it is:** A modern, fast (high-performance) web framework for building APIs with Python.

**Why we use it:**
*   **Python Native:** Since our project relies heavily on Machine Learning (XGBoost/Random Forest) and data processing, Python is mandatory. FastAPI allows us to serve the ML models directly within the same ecosystem without needing complex microservices right away.
*   **Asynchronous by Default:** During a disaster, the system might receive thousands of concurrent SOS requests from the mesh network gateways. FastAPI's async capabilities (`async`/`await`) allow it to handle massive concurrent traffic efficiently.
*   **Auto-generated Documentation:** It automatically generates Swagger UI documentation. For a fast-paced project/hackathon, this saves hours of documenting the API for the frontend/mobile teams.

## 2. Primary Database: PostgreSQL with PostGIS

**What it is:** PostgreSQL is a robust relational database. PostGIS is an extension that adds support for geographic objects allowing location queries to be run in SQL.

**Why we use it:**
*   **Geospatial Data is Core:** FIRE-EYE is fundamentally about location—where is the disaster (Risk Zones), where are the victims (SOS locations), where are the shelters, and where are the safe roads.
*   **Spatial Queries:** PostGIS allows us to write SQL queries like *"Find all SOS requests within 5km of a high-risk flood zone"* or *"Find the nearest shelter to this latitude/longitude"* natively and extremely fast. Standard databases (like MongoDB or MySQL without spatial extensions) struggle with complex geometry intersections.
*   **ACID Compliance:** For rescue operations, data integrity is critical. We cannot afford to lose an SOS record.

## 3. Real-Time Layer: Redis & WebSockets

**What it is:** Redis is an in-memory data structure store, used as a database, cache, and message broker (Pub/Sub).

**Why we use it:**
*   **Real-Time Dashboard Updates:** When an SOS is received by the backend, the Rescue Dashboard needs to see it *instantly* without refreshing the page. We use WebSockets for the live connection, and Redis Pub/Sub to broadcast the new SOS to all connected dashboard clients.
*   **Caching:** Complex GIS queries (e.g., generating the current risk map) can be heavy on the database. We can cache the results in Redis for a few minutes to reduce database load.

## 4. Machine Learning Integration

**What it is:** Loading a pre-trained `joblib` (XGBoost/Random Forest) model directly into the FastAPI application.

**Why we use it:**
*   **Low Latency Predictions:** By keeping the ML model in memory within the FastAPI app, we can calculate Risk Probability instantly when new environmental data arrives, without the overhead of making network calls to a separate ML microservice.
*   **Simplicity:** It keeps the architecture simple and easy to deploy while focusing strictly on the backend logic.

## 5. The Priority Engine (Custom Logic Module)

**What it is:** A backend module that intercepts incoming SOS requests and assigns them a "Priority Score" before saving to the database.

**Why we use it:**
*   **Triage during Disasters:** Rescue teams have limited resources. If 100 SOS signals come in, who gets saved first? The Priority Engine calculates a score based on:
    *   **Vulnerability:** Elderly, children, or people with disabilities get higher priority.
    *   **Context:** Is the person in a "High Risk" zone?
    *   **Severity:** Is it a medical emergency vs. a request for supplies?
*   This ensures the Rescue Dashboard always shows the most critical victims at the top of the queue.

## 6. Routing: OSRM (Open Source Routing Machine)

**What it is:** A high-performance routing engine for shortest paths in road networks.

**Why we use it:**
*   **Dynamic Road Penalties:** Standard Google Maps doesn't know that a specific road is currently flooded or blocked by debris. We use OSRM because we can feed it our PostGIS risk maps and apply "penalties" to dangerous roads, forcing the routing engine to calculate the *safest* route for rescue teams, not just the fastest under normal conditions.

## 7. Security: JWT (JSON Web Tokens) & Role-Based Access

**What it is:** Stateless authentication mechanism.

**Why we use it:**
*   **Data Privacy:** Victim data and exact locations are highly sensitive. 
*   **Stateless Scaling:** JWTs allow the backend to verify users (Victim, Volunteer, Rescue Worker, Admin) without looking up the database for every single request, which is crucial for performance.

---

## Summary of the Backend Request Flow (SOS Example)

1.  Gateway sends an SOS payload to `POST /api/v1/sos` (FastAPI).
2.  FastAPI validates the token (JWT).
3.  The **Priority Engine** analyzes the victim's data and current risk maps to assign a Priority Score.
4.  The SOS is saved to **PostgreSQL/PostGIS** with its geospatial coordinates.
5.  FastAPI publishes the new SOS event to **Redis Pub/Sub**.
6.  The WebSocket manager reads from Redis and pushes the SOS to the live **Rescue Dashboard**.
7.  If a route is requested, **OSRM** calculates the safest path avoiding current risk zones.
