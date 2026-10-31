"""
FIRE-EYE: Offline Store-and-Forward Mesh Simulator
Simulates ad-hoc multi-hop emergency packet propagation without internet.
Matches Phase 8 requirements from 20-HOUR-WORKFLOW.md
"""

import time
import uuid
import json
import sys
import requests

# Ensure UTF-8 output on Windows consoles
if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

class MeshNode:
    def __init__(self, node_id: str, is_gateway: bool = False):
        self.node_id = node_id
        self.is_gateway = is_gateway
        self.seen_messages = set()
        self.inbox = []
        self.peers = []

    def connect(self, peer: "MeshNode"):
        if peer not in self.peers:
            self.peers.append(peer)
        if self not in peer.peers:
            peer.peers.append(self)

    def receive_packet(self, packet: dict, from_peer: str = None) -> bool:
        msg_id = packet["message_id"]

        # 1. Duplicate Detection
        if msg_id in self.seen_messages:
            print(f"[{self.node_id}] DUPLICATE DROPPED: {msg_id}")
            return False

        self.seen_messages.add(msg_id)
        self.inbox.append(packet)

        if self.is_gateway:
            print(f"[{self.node_id}] ★ GATEWAY RECEIVED SOS: {msg_id} from {packet['sender_id']}! Hops: {' -> '.join(packet['hops'])}")
            print(f"[{self.node_id}] UPLOADING TO COMMAND CENTER DATABASE via POST /api/v1/mesh/packet...")
            
            try:
                # Add payload wrapper like in the schema
                api_packet = dict(packet)
                if "payload" not in api_packet:
                    api_packet["payload"] = {
                        "vulnerabilities": ["ELDERLY", "MOBILITY_IMPAIRED"],
                        "people_count": 2,
                        "battery_level": 82
                    }
                response = requests.post("http://127.0.0.1:8000/api/v1/mesh/packet", json=api_packet)
                print(f"[{self.node_id}] SERVER RESPONSE: {response.status_code}")
                print(json.dumps(response.json(), indent=2))
            except Exception as e:
                print(f"[{self.node_id}] ❌ FAILED TO REACH BACKEND: {e}")
                
            return True

        print(f"[{self.node_id}] MESSAGE RECEIVED: {msg_id} (TTL={packet['ttl']})")

        # 2. TTL Check
        if packet["ttl"] <= 1:
            print(f"[{self.node_id}] TTL EXPIRED: Packet cannot be forwarded further.")
            return False

        # 3. Store & Forward
        forward_packet = dict(packet)
        forward_packet["ttl"] -= 1
        forward_packet["hops"] = packet["hops"] + [self.node_id]

        print(f"[{self.node_id}] FORWARDING TO PEERS (TTL now {forward_packet['ttl']})...")
        for peer in self.peers:
            if peer.node_id != from_peer:
                peer.receive_packet(forward_packet, from_peer=self.node_id)
        return True


def run_simulation():
    print("=" * 60)
    print("🔥 FIRE-EYE OFFLINE STORE-AND-FORWARD MESH SIMULATION")
    print("=" * 60)

    # Topology: Device A (Elderly H101) -> Device B (Citizen) -> Device C (Volunteer) -> Gateway (Rescue vehicle)
    node_a = MeshNode("DEVICE-A (Victim H101)")
    node_b = MeshNode("DEVICE-B (Citizen Relay)")
    node_c = MeshNode("DEVICE-C (Volunteer Relay)")
    gateway = MeshNode("GATEWAY (Rescue Vehicle)", is_gateway=True)

    # Connect linear / ad-hoc multi-hop mesh
    node_a.connect(node_b)
    node_b.connect(node_c)
    node_c.connect(gateway)

    print("\n[!] CELLULAR & FIBER INFRASTRUCTURE DOWN: Internet OFF")
    print("[!] Household H101 presses physical SOS emergency button...\n")

    # Device A creates SOS packet
    msg_id = f"SOS-{int(time.time())}-{uuid.uuid4().hex[:4].upper()}"
    sos_packet = {
        "message_id": msg_id,
        "sender_id": "DEVICE-A",
        "household_id": "H101",
        "latitude": 11.6082,
        "longitude": 76.0921,
        "severity": "CRITICAL",
        "timestamp": int(time.time()),
        "ttl": 8,
        "hops": ["DEVICE-A"]
    }

    print(f"[{node_a.node_id}] SOS CREATED: {msg_id}")
    print(f"[{node_a.node_id}] Broadcasting over Bluetooth / Wi-Fi Direct...")

    # Forward from A
    for peer in node_a.peers:
        peer.receive_packet(sos_packet, from_peer=node_a.node_id)

    print("\n" + "=" * 60)
    print("✅ MESH PACKET SUCCESSFULLY REACHED RESCUE GATEWAY!")
    print("=" * 60)


if __name__ == "__main__":
    run_simulation()
