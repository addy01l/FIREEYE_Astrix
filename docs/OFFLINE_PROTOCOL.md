# 📡 FIRE-EYE — Offline Mesh Protocol Specification

## 1. Context & Motivation
During disasters (landslides, earthquakes, floods), cellular towers lose power and fiber backhauls are severed. Citizens and emergency response units lose internet connectivity.

FIRE-EYE uses a **Store-and-Forward Opportunistic Mesh Network** over short-range radio (Bluetooth Low Energy / Wi-Fi Direct / LoRa).

---

## 2. Mesh Topology
```text
┌─────────────────┐
│ Device A (Victim│
│ Elderly H101)   │
└────────┬────────┘
         │ (BLE / Direct Ad-Hoc)
         ▼
┌─────────────────┐
│ Device B        │  (Store packet in local SQLite)
│ (Citizen Relay) │  (Decrements TTL from 8 to 7)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Device C        │  (Store & Forward)
│ (Volunteer)     │  (Decrements TTL to 6)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ RESCUE GATEWAY  │  (Satellite Uplink / Long-range link)
│ (Vehicle / Node)│  (Ingests into Command Center)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ FIRE-EYE Backend│
└─────────────────┘
```

---

## 3. Packet Schema

```json
{
  "message_id": "MSG-SOS-2026-9912",
  "sender_id": "DEV-ELDERLY-H101",
  "type": "SOS",
  "household_id": "H101",
  "latitude": 11.6082,
  "longitude": 76.0921,
  "severity": "CRITICAL",
  "payload": {
    "vulnerabilities": ["ELDERLY", "MOBILITY_IMPAIRED"],
    "people_count": 4,
    "battery_level": 82
  },
  "timestamp": 1791370200,
  "ttl": 8,
  "hops": ["DEV-ELDERLY-H101"]
}
```

---

## 4. Node Ingestion Rulesf

1. **Duplicate Check**:
   - Check if $P.\text{message\_id} \in \text{seen\_messages}$.
   - If true, silently drop $P$.
   - If false, add $P.\text{message\_id}$ to $\text{seen\_messages}$.

2. **TTL Check**:
   - If $P.\text{ttl} \le 1$, do not forward.
   - Else, $P.\text{ttl} \leftarrow P.\text{ttl} - 1$.

3. **Hop Append**:
   - Append $N.\text{node\_id}$ to $P.\text{hops}$.

4. **Persistence**:
   - Save $P$ to local store.

5. **Forwarding**:
   - When a peer device is discovered, transmit $P$.

6. **Gateway Sync**:
   - When gateway connects to cloud/FastAPI, it flushes stored packets via `POST /api/v1/mesh/packet`.
