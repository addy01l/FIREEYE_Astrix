# 🎬 FIRE-EYE — 12-Step Hackathon Demo Script

Follow this script during your 3-minute jury presentation.

---

### Step 1: Normal Situation
- **Screen**: Command Center Dashboard.
- **Narrative**: "Here is our command dashboard monitoring Wayanad hill range. Current rainfall is 25mm. All hazard zones are green (LOW risk)."

### Step 2: Weather Deterioration
- **Action**: In the Simulation panel, move rainfall slider from 25mm to 185mm.
- **Narrative**: "Torrential monsoon rains hit Sector 4 with 185mm in 24 hours."

### Step 3: ML Risk Prediction
- **Action**: Click "Trigger ML Assessment".
- **Narrative**: "Our XGBoost/Random Forest model processes rainfall, slope degree (38°), elevation, and historical landslides. Risk probability spikes to 89%."

### Step 4: Live Map Zone Turns Red
- **Screen**: Zone 4 changes from green to pulsing RED on Leaflet map.
- **Narrative**: "The zone immediately turns RED on the situational map."

### Step 5: Vulnerable Population Identification
- **Action**: Click on Household H101 pin inside the red zone.
- **Narrative**: "The system maps vulnerable households. Household H101 has 2 elderly members and a bed-ridden patient dependent on oxygen."

### Step 6: SOS Triggered
- **Action**: Click "Trigger SOS for H101".
- **Narrative**: "The household activates emergency SOS."

### Step 7: Network Failure Simulation
- **Action**: Toggle "Internet: OFF" switch.
- **Narrative**: "Cell towers in the valley collapse. No 4G/5G or WiFi."

### Step 8: Multi-Hop Store & Forward Mesh
- **Screen**: Open the Mesh Visualizer widget.
- **Narrative**: "Device A relays the BLE packet to Device B (a volunteer), who walks and forwards to Device C, reaching the Mobile Rescue Gateway."

### Step 9: Gateway Ingestion
- **Narrative**: "The gateway uploads the stored SOS packets directly to the command server."

### Step 10: Rescue Priority Queue
- **Screen**: Look at Priority Rescue Queue.
- **Narrative**: "Instead of first-come first-served, our engine calculates Priority = Severity(40%) + Vulnerability(30%) + Risk(20%) + Isolation(10%). H101 takes position #1 with a 94.6 score."

### Step 11: Dynamic Hazard-Avoidance Routing
- **Screen**: Click "View Evacuation Route".
- **Narrative**: "Normal GPS navigation routes through the valley where roads are flooded. FIRE-EYE calculates an alternate high-ground evacuation path avoiding the red hazard zone."

### Step 12: Safe Shelter Allocation
- **Screen**: Shelter card opens.
- **Narrative**: "Community Hall Shelter #2 is assigned, which has 45 open beds, medical staff, and emergency power."
