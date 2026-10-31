# 🔥 FIRE-EYE: Inclusive & Fault-Tolerant Disaster Response System

## What is FIRE-EYE?
FIRE-EYE is an AI-powered disaster response platform designed to assist communities before, during, and after disasters. It goes beyond simple disaster risk detection by converting risk information into an actionable, inclusive response plan. Even when conventional communication networks fail, FIRE-EYE ensures that people can send SOS signals and receive evacuation guidance. 

## What Problem Does It Solve?
During disasters, existing emergency systems face several critical limitations:
1. **Lack of Actionable Alerts**: People may receive warnings but often don't know the exact actions to take or where to go.
2. **Network Failures**: Mobile networks and internet connectivity frequently fail during severe disasters.
3. **Digital Divide**: Elderly individuals and other vulnerable groups may not have smartphones to access apps or call for help.
4. **Overwhelmed Rescue Teams**: Rescuers receive multiple SOS requests simultaneously, making it hard to prioritize.
5. **Dynamic Hazards**: Static evacuation routes become dangerous as roads get blocked or unsafe.
6. **Lack of Situational Awareness**: Rescue teams lack real-time visibility into the disaster zone and the locations of the most vulnerable populations.

**FIRE-EYE solves these issues by:**
- Using offline multi-hop (mesh) communication for SOS signals when internet fails.
- Prioritizing rescue operations based on medical severity, vulnerability, and disaster risk.
- Dynamically calculating safe evacuation routes rather than just the shortest ones.
- Integrating hardware/community relay solutions for non-smartphone users.

## Core Features
- **AI Disaster Risk Prediction**: Evaluates rainfall, slope, elevation, and soil characteristics to predict risk probability.
- **Risk & Vulnerability Mapping**: Visualizes disaster-prone zones alongside vulnerable households (e.g., elderly, children, disabled).
- **Fault-Tolerant Emergency SOS**: Uses a store-and-forward mesh communication model (Bluetooth, Wi-Fi Direct, LoRa) to relay SOS messages to gateways.
- **Rescue Priority Engine**: Ranks SOS requests based on medical severity, vulnerability, and isolation.
- **Dynamic Evacuation Routing**: Recommends safer routes avoiding high-risk or blocked roads.
- **Shelter Allocation**: Allocates shelters based on capacity, occupancy, distance, and route safety.

## Technology Stack Used

### Frontend
- **React & TypeScript**: For building a robust and type-safe user interface.
- **Tailwind CSS**: For responsive and modern styling.
- **Leaflet & OpenStreetMap**: For interactive maps and visualizing the disaster zones.

### Backend
- **Python & FastAPI**: For high-performance, asynchronous REST APIs.
- **Pydantic**: For data validation.
- **SQLAlchemy**: ORM for database interactions.
- **WebSockets**: For real-time updates and communication.
- **JWT (JSON Web Tokens)**: For secure authentication.

### Database & GIS
- **PostgreSQL**: Relational database for structured data.
- **PostGIS**: Spatial database extension for geographic objects and queries.
- **GeoPandas & Shapely**: For geospatial data manipulation and analysis in Python.

### Machine Learning
- **Scikit-learn & XGBoost**: For training predictive models.
- **Pandas & NumPy**: For data processing and analysis.
- **Joblib**: For model serialization.

### Real-Time & Routing
- **Redis**: In-memory data store for caching and message brokering.
- **OSRM (Open Source Routing Machine)**: For calculating routes.

### Offline Communication
- **Bluetooth & Wi-Fi Direct**: For device-to-device mesh networking.
- **ESP32 + LoRa (Optional)**: For long-range hardware communication nodes.

## The Core USP (Unique Selling Proposition)
Existing systems answer: *"Where is the disaster risk?"*
FIRE-EYE answers: *"Who is at risk, how do we communicate with them when networks fail, who should be rescued first, and where should they go?"*
