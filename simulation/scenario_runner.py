"""
FIRE-EYE: Automated 12-Step Hackathon Demo Scenario Runner
Executes the complete end-to-end presentation flow.
"""

import time
import sys

# Ensure UTF-8 output on Windows consoles
if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

from simulation.mesh_simulator import MeshNode

def step_pause(seconds=1):
    time.sleep(seconds)

def run_hackathon_demo():
    print("=" * 70)
    print("🎬 FIRE-EYE: 12-STEP DISASTER RESPONSE SYSTEM DEMONSTRATION")
    print("=" * 70)

    print("\n[STEP 1] Initial State: Normal Weather")
    print("  • Location: Rudraprayag Sector 4 Hill Range")
    print("  • Rainfall (24h): 25.0 mm | Slope: 38° | Elevation: 1250m")
    print("  • Status: Zone Sector 4 is 🟢 LOW RISK (Risk Score: 0.12)")
    step_pause(1)

    print("\n[STEP 2] Deteriorating Weather: Heavy Monsoon Downpour")
    print("  • Inflow: Extreme cloudburst event")
    print("  • Rainfall (24h) rises from 25.0mm -> 185.0 mm")
    step_pause(1)

    print("\n[STEP 3] ML Hazard Assessment Triggered")
    from ml.predict import predict_landslide_risk
    pred = predict_landslide_risk(rainfall_24h=185.0, slope=38.0, elevation=1250.0)
    print(f"  • ML Engine: {pred['model_used']}")
    print(f"  • Model Prediction: {pred['risk_level']} (Hazard Score: {pred['risk_score']})")
    step_pause(1)

    print("\n[STEP 4] Live Disaster Map Alert Update")
    print("  • Sector 4 polygon turns 🔴 CRITICAL RED on Command Map")
    print("  • Geofence activated: 1,240 civilians inside hazard zone")
    step_pause(1)

    print("\n[STEP 5] Vulnerable Population Registry Queried")
    print("  • Household H101 identified:")
    print("    - 4 occupants, 2 elderly individuals")
    print("    - 1 person with motor disability + oxygen concentrator")
    print("    - Calculated Vulnerability Index: 0.94 (HIGH)")
    step_pause(1)

    print("\n[STEP 6] Emergency SOS Triggered")
    print("  • Household H101 presses physical emergency panic node")
    print("  • Distress Message: 'Landslide mud entering ground floor, need stretcher'")
    step_pause(1)

    print("\n[STEP 7] Cellular Network Infrastructure Down")
    print("  • Cell towers lost power. Fiber severed. 4G/5G/WiFi: ❌ OFFLINE")
    print("  • System switches automatically to Store-and-Forward Mesh protocol")
    step_pause(1)

    print("\n[STEP 8] Multi-Hop Store & Forward Mesh Transmission")
    node_a = MeshNode("NODE-H101")
    node_b = MeshNode("NODE-VOLUNTEER-B")
    node_c = MeshNode("NODE-COMMUNITY-C")
    gateway = MeshNode("GATEWAY-RESCUE-TRUCK", is_gateway=True)

    node_a.connect(node_b)
    node_b.connect(node_c)
    node_c.connect(gateway)

    packet = {
        "message_id": "SOS-DEMO-9912",
        "sender_id": "NODE-H101",
        "household_id": "H101",
        "latitude": 11.6082,
        "longitude": 76.0921,
        "severity": "CRITICAL",
        "timestamp": int(time.time()),
        "ttl": 8,
        "hops": ["NODE-H101"]
    }
    for peer in node_a.peers:
        peer.receive_packet(packet, from_peer=node_a.node_id)
    step_pause(1)

    print("\n[STEP 9] Gateway Packet Ingestion")
    print("  • Satellite Gateway uploads mesh packet to FIRE-EYE Command Center")
    print("  • SOS-DEMO-9912 stored and acknowledged in central database")
    step_pause(1)

    print("\n[STEP 10] Dynamic Rescue Priority Engine Ranking")
    print("  • Formula: Priority = Severity(40) + Vulnerability(30) + Risk(20) + Isolation(10)")
    score = (1.0 * 40) + (0.94 * 30) + (pred['risk_score'] * 20) + (0.8 * 10)
    print(f"  • Household H101 Priority Score: {score:.1f}/100.0")
    print("  • Rescue Queue: H101 placed at #1 TOP RESCUE PRIORITY")
    step_pause(1)

    print("\n[STEP 11] Hazard-Avoidance Evacuation Routing")
    print("  • Standard route through Valley Rd is BLOCKED / DANGEROUS")
    print("  • Dynamic Router plots Ridge Bypass Road (High-ground path)")
    print("  • Estimated traversal time: 14 minutes")
    step_pause(1)

    print("\n[STEP 12] Shelter & Hospital Allocation")
    print("  • Allocated: St. Mary Community Shelter (Sector 2)")
    print("  • Open Bed Capacity: 42 beds remaining | Generator Power: Available")
    print("  • Medical Support: Oxygen support ready for H101 arrival")

    print("\n" + "=" * 70)
    print("🏆 FULL 12-STEP DEMO COMPLETED SUCCESSFULLY!")
    print("=" * 70)

if __name__ == "__main__":
    run_hackathon_demo()
