# 🔥 FIRE-EYE
## Inclusive & Fault-Tolerant Disaster Response System

> Predict Risk → Identify Vulnerable People → Communicate Offline → Prioritize Rescue → Find Safe Route

---

# 1. Product Overview

FIRE-EYE is an AI-powered disaster response platform designed to help communities before and during disasters.

The system combines:

- AI-based disaster risk assessment
- Vulnerable population identification
- Emergency SOS
- Offline multi-hop communication
- Rescue prioritization
- Dynamic evacuation routing
- Shelter allocation
- Rescue command dashboard

The key differentiator is:

> FIRE-EYE does not stop at detecting disaster risk. It converts risk information into an actionable, inclusive response plan—even when conventional communication networks are unavailable.

---

# 2. Problem Statement

During disasters, existing emergency systems face several limitations:

1. People may receive warnings but not know what action to take.
2. Mobile networks and internet may fail.
3. Elderly people and other vulnerable groups may not have smartphones.
4. Rescue teams may receive multiple SOS requests simultaneously.
5. Roads can become unsafe or blocked.
6. Static evacuation routes may become dangerous.
7. Rescue teams need situational awareness in real time.

FIRE-EYE addresses these problems through a unified disaster response platform.

---

# 3. Target Users

## Citizens
- Receive disaster alerts
- Send SOS
- View evacuation routes
- Find shelters

## Elderly / Non-Smartphone Users
- Physical SOS button/node
- Community relay
- Voice/local alerts

## Rescue Teams
- Receive SOS requests
- View victim locations
- Prioritize emergencies
- Get safer routes

## Disaster Authorities
- Monitor disaster zones
- Monitor vulnerable population
- Track rescue operations
- Monitor shelters and hospitals

## Volunteers
- Act as communication relays
- Assist vulnerable households

---

# 4. Core Features

## 4.1 Disaster Risk Prediction

Input:

- Rainfall
- Cumulative rainfall
- Slope
- Elevation
- Soil/land characteristics
- Historical disaster events

Output:

- Risk probability
- LOW
- MEDIUM
- HIGH

The system provides a risk estimate and does not claim deterministic disaster prediction.

---

# 5. Risk Map

The dashboard displays disaster-prone zones.

### Color Levels

- 🟢 LOW
- 🟡 MEDIUM
- 🔴 HIGH

Each zone provides:

- Risk score
- Population
- Vulnerable population
- Nearby roads
- Shelters
- Hospitals

---

# 6. Vulnerable Population Mapping

Each household can contain:

- Number of residents
- Elderly people
- Children
- Persons with disabilities
- Medical dependency

Example:

| Household | Members | Elderly | Children | Disabled |
|---|---:|---:|---:|---:|
| H101 | 4 | 2 | 0 | 0 |
| H102 | 5 | 0 | 2 | 0 |
| H103 | 3 | 1 | 0 | 1 |

A vulnerability score is calculated for rescue prioritization.

---

# 7. Emergency SOS

## Smartphone SOS

User presses:

`SOS`

System sends:

- User ID
- Location
- Emergency type
- Severity
- Timestamp

---

# 8. Offline Emergency Communication

FIRE-EYE supports a store-and-forward communication model.

When internet/mobile networks are unavailable:

```text
Device A
   ↓
Device B
   ↓
Device C
   ↓
Gateway
   ↓
Rescue Dashboard
```

Communication technologies:

- Bluetooth
- Wi-Fi Direct
- Optional LoRa

Each message contains:

- Message ID
- Sender ID
- Location
- Timestamp
- Severity
- TTL

---

# 9. No-Smartphone Emergency Support

For elderly or non-smartphone users:

- Physical SOS button
- Local communication node
- Community volunteer relay

Example:

```text
Elderly Person
      ↓
SOS Button
      ↓
Local Node
      ↓
Nearby Device
      ↓
Mesh Network
      ↓
Rescue Gateway
```

---

# 10. Rescue Priority Engine

SOS requests are ranked according to:

- Medical severity
- Vulnerability
- Disaster risk
- Isolation
- Distance from rescue team

Example:

```text
#1 🔴 H101 - Critical elderly patient
#2 🔴 H205 - Injured child
#3 🟠 H112 - Medical emergency
#4 🟡 H301 - Minor injury
```

---

# 11. Dynamic Evacuation Routing

The system calculates safer routes instead of simply finding the shortest route.

Factors:

- Blocked roads
- Road risk
- Disaster zones
- Distance
- Shelter availability

Example:

```text
Road A → HIGH RISK
Road B → SAFE
Road C → BLOCKED

Recommended Route → Road B
```

---

# 12. Shelter Allocation

System considers:

- Distance
- Capacity
- Occupancy
- Accessibility
- Route safety

Example:

```text
Shelter A → 500 capacity → 320 occupied
Shelter B → 200 capacity → 50 occupied
Shelter C → 100 capacity → 90 occupied
```

---

# 13. Rescue Command Dashboard

Dashboard shows:

- Active disaster
- Risk map
- Active SOS
- Rescue teams
- Vulnerable households
- Shelters
- Hospitals
- Roads
- Evacuation routes

---

# 14. What-If Simulation

The system can simulate changes in disaster conditions.

Example:

```text
Current rainfall:
100 mm

Simulated rainfall:
150 mm

System recalculates:

Risk
Affected population
Road vulnerability
Shelter requirements
Evacuation route
```

---

# 15. Technology Stack

## Frontend
- React
- TypeScript
- Tailwind CSS
- Leaflet
- OpenStreetMap

## Backend
- Python
- FastAPI
- Pydantic
- SQLAlchemy
- JWT
- WebSockets

## Database
- PostgreSQL
- PostGIS

## Machine Learning
- Pandas
- NumPy
- Scikit-learn
- XGBoost
- Joblib

## GIS
- GeoPandas
- Shapely
- PostGIS

## Routing
- OpenStreetMap
- OSRM

## Real-Time
- Redis
- WebSockets

## Notifications
- Firebase Cloud Messaging

## Offline Communication
- Bluetooth
- Wi-Fi Direct
- Optional ESP32 + LoRa

---

# 16. MVP Scope

The 20-hour hackathon MVP will focus on:

1. Risk prediction
2. Risk map
3. Vulnerable households
4. SOS system
5. Offline mesh simulation
6. Rescue priority
7. Safe route
8. Shelter recommendation
9. Rescue dashboard

Hardware and advanced mesh communication are optional extensions.

---

# 17. Success Criteria

FIRE-EYE will be considered successful if:

- Risk prediction works
- Risk appears on map
- Vulnerable households are identified
- SOS can be generated
- SOS can be prioritized
- Offline message flow can be demonstrated
- Safe route can be generated
- Shelter can be recommended
- Rescue dashboard updates correctly

---

# 18. Core USP

Existing systems may answer:

> "Where is the disaster risk?"

FIRE-EYE answers:

> "Who is at risk, how do we communicate with them when networks fail, who should be rescued first, and where should they go?"

---

# 19. One-Line Pitch

> FIRE-EYE transforms disaster risk information into an inclusive, network-resilient rescue operation for everyone — including people without smartphones.
