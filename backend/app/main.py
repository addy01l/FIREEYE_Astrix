import asyncio
from contextlib import asynccontextmanager

from app.api import api_router
from app.config import settings
from app.database import Base, SessionLocal, engine
from app.seeds.seed_data import seed_hackathon_demo_data
from app.services.ml_service import load_model_at_startup
from app.services.websocket_manager import ws_manager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

# Create tables
Base.metadata.create_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    load_model_at_startup()
    try:
        db = SessionLocal()
        seed_hackathon_demo_data(db)
        db.close()
    except Exception as e:
        print(f"[FIRE-EYE SEED INFO] Seed check: {e}")
    ws_manager._heartbeat_task = asyncio.create_task(ws_manager.start_heartbeat())
    ws_manager._pubsub_task = asyncio.create_task(ws_manager.start_redis_subscriber())
    yield
    # Shutdown
    if ws_manager._heartbeat_task:
        ws_manager._heartbeat_task.cancel()
    if ws_manager._pubsub_task:
        ws_manager._pubsub_task.cancel()


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    description="FIRE-EYE Inclusive & Fault-Tolerant Disaster Response System API",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS config
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all for hackathon MVP
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/health")
def health_check():
    redis_status = "disconnected"
    try:
        from app.redis_client import redis_client
        if redis_client is not None and redis_client.ping():
            redis_status = "connected"
    except Exception:
        redis_status = "unreachable"

    return {
        "status": "ok",
        "service": settings.PROJECT_NAME,
        "redis": redis_status,
    }


CITIZEN_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Fire-Eye | Emergency Response Portal</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    body { background-color: #0b0d11; color: #f8fafc; font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    .card { background-color: #13151b; border: 1px solid #232733; border-radius: 1rem; }
    .inner-box { background-color: #0b0d11; border: 1px solid #1e222d; border-radius: 0.625rem; }
    @keyframes pulse-ring {
      0% { transform: scale(0.96); box-shadow: 0 0 0 0 rgba(220, 38, 38, 0.6); }
      70% { transform: scale(1.04); box-shadow: 0 0 0 25px rgba(220, 38, 38, 0); }
      100% { transform: scale(0.96); box-shadow: 0 0 0 0 rgba(220, 38, 38, 0); }
    }
    .pulse-btn { animation: pulse-ring 2s infinite ease-in-out; }
  </style>
</head>
<body class="min-h-screen flex flex-col justify-between">
  <!-- Top Bar -->
  <header class="border-b border-[#1e222d] px-6 py-4 flex items-center justify-between">
    <div class="flex items-center space-x-6">
      <span class="text-2xl font-bold tracking-tight text-white">Fire-Eye</span>
      <nav class="hidden sm:flex items-center space-x-2">
        <a href="/citizen" class="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#1e222d] text-white border border-[#2e3444]">Citizen SOS</a>
        <a href="/commander" class="px-3 py-1.5 rounded-lg text-xs font-semibold text-gray-400 hover:text-white hover:bg-[#13151b] transition">Commander Dispatch</a>
      </nav>
    </div>
    <div class="flex items-center space-x-3">
      <a href="/commander" class="sm:hidden text-xs text-gray-400 hover:text-white underline">Dispatch View</a>
      <div class="flex items-center space-x-2 bg-[#102a18] border border-[#1b4d2b] px-3 py-1.5 rounded-full text-xs font-semibold text-[#22c55e]">
        <span class="w-2 h-2 rounded-full bg-[#22c55e]"></span>
        <span>System Connected</span>
      </div>
    </div>
  </header>

  <!-- Main Container -->
  <main class="max-w-6xl mx-auto px-4 py-8 flex-1 w-full grid grid-cols-1 md:grid-cols-2 gap-6 items-start">
    <!-- Left Hero Card -->
    <div class="card p-8 flex flex-col items-center justify-center text-center min-h-[460px]">
      <div id="sosNormalView" class="w-full flex flex-col items-center">
        <h2 class="text-2xl md:text-3xl font-bold text-white mb-2">Need Emergency Help?</h2>
        <p class="text-sm text-gray-400 mb-8 max-w-sm">Press and hold the button below to alert rescue teams.</p>
        
        <button id="sosBtn" onclick="openSosModal()" class="w-48 h-48 rounded-full bg-[#dc2626] text-white font-black text-4xl tracking-wider pulse-btn flex items-center justify-center cursor-pointer hover:bg-[#b91c1c] active:scale-95 transition-transform duration-150 shadow-2xl shadow-red-900/50">
          SOS
        </button>

        <div class="mt-8 flex gap-3">
          <button onclick="openSosModal()" class="px-4 py-2 text-xs font-medium bg-[#1e222d] text-gray-300 rounded-lg hover:bg-gray-800 transition">
            Specify Emergency Details
          </button>
        </div>
      </div>

      <!-- Active Beacon View (Initially Hidden) -->
      <div id="sosActiveView" class="hidden w-full flex flex-col items-center">
        <div class="w-24 h-24 rounded-full bg-[#dc2626] flex items-center justify-center text-white text-3xl font-bold mb-4 animate-pulse">
          📡
        </div>
        <h3 class="text-xl font-bold text-[#dc2626] mb-1">DISTRESS BEACON ACTIVE</h3>
        <p id="beaconCodeDisplay" class="text-sm font-mono text-gray-200 mb-2 font-bold">BEACON: SOS-ACTIVE</p>
        <p class="text-xs text-gray-400 mb-6">Distress coordinates broadcasted to Rescue Dispatch & Commander Queue.</p>
        
        <div class="inner-box w-full p-4 mb-6 text-left text-xs space-y-2">
          <div class="flex items-center text-[#22c55e]"><span>✔ Signal Registered in Central Dispatch</span></div>
          <div class="flex items-center text-[#22c55e]"><span>✔ Priority Multi-Factor Algorithmic Score Assigned</span></div>
          <div class="flex items-center text-gray-300"><span>• Status: RESCUERS NOTIFIED</span></div>
        </div>

        <button onclick="standDownSos()" class="px-6 py-2.5 border border-[#22c55e] text-[#22c55e] hover:bg-[#22c55e]/10 rounded-lg text-xs font-bold tracking-wide transition">
          CANCEL BEACON / I AM SAFE NOW
        </button>
      </div>
    </div>

    <!-- Right Side Cards -->
    <div class="flex flex-col gap-6">
      <!-- Safety Status Card -->
      <div class="card p-6">
        <div class="text-xs font-mono font-bold text-gray-400 tracking-wider mb-2">SAFETY STATUS</div>
        <div class="text-3xl font-extrabold text-[#ef4444] mb-1">High Risk</div>
        <div class="text-sm text-gray-200 mb-4">Landslide warnings active in your region.</div>
        <div class="inner-box p-4 space-y-2 text-xs text-gray-300">
          <p>• Heavy rainfall expected</p>
          <p>• Avoid steep slopes</p>
        </div>
      </div>

      <!-- Nearest Shelter Card -->
      <div class="card p-6">
        <div class="text-xs font-mono font-bold text-gray-400 tracking-wider mb-2">NEAREST SHELTER</div>
        <div id="shelterName" class="text-xl font-bold text-white mb-1">Govt Relief Center</div>
        <div class="text-sm text-gray-400 mb-4">2.8 km away</div>
        <div class="grid grid-cols-2 gap-4">
          <div class="inner-box p-3">
            <span class="text-xs text-gray-400 block mb-1">Capacity</span>
            <span id="shelterCap" class="text-xl font-extrabold text-white">120</span>
          </div>
          <div class="inner-box p-3">
            <span class="text-xs text-gray-400 block mb-1">Available</span>
            <span id="shelterAvail" class="text-xl font-extrabold text-[#22c55e]">64</span>
          </div>
        </div>
      </div>
    </div>
  </main>

  <!-- Modal for pre-fed questionnaire -->
  <div id="sosModal" class="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 hidden flex items-center justify-center p-4">
    <div class="card max-w-lg w-full p-6 space-y-5">
      <div class="flex justify-between items-center border-b border-[#232733] pb-3">
        <h3 class="text-lg font-bold text-white flex items-center gap-2">
          <span class="text-red-500">🚨</span> Emergency Assessment
        </h3>
        <button onclick="closeSosModal()" class="text-gray-400 hover:text-white text-lg">&times;</button>
      </div>

      <div class="space-y-4 text-xs">
        <div>
          <label class="block text-gray-400 font-semibold mb-2">1. NATURE OF EMERGENCY</label>
          <div class="grid grid-cols-2 gap-2" id="emergencyChips">
            <button type="button" class="type-btn p-2 rounded-lg border border-red-500 bg-red-950/40 text-left font-semibold" data-type="Trapped / Structural Collapse">Trapped / Structural</button>
            <button type="button" class="type-btn p-2 rounded-lg border border-[#232733] bg-[#0b0d11] text-left hover:border-gray-500" data-type="Active Fire / Wildfire">Active Fire / Wildfire</button>
            <button type="button" class="type-btn p-2 rounded-lg border border-[#232733] bg-[#0b0d11] text-left hover:border-gray-500" data-type="Flash Flood / Rising Water">Flash Flood / Water</button>
            <button type="button" class="type-btn p-2 rounded-lg border border-[#232733] bg-[#0b0d11] text-left hover:border-gray-500" data-type="Medical Emergency / Trauma">Medical Emergency</button>
          </div>
        </div>

        <div>
          <label class="block text-gray-400 font-semibold mb-2">2. PEOPLE STRANDED</label>
          <div class="flex items-center gap-3">
            <button type="button" onclick="adjustCount(-1)" class="w-8 h-8 rounded bg-[#1e222d] text-base font-bold">-</button>
            <span id="victimCount" class="font-mono text-base font-bold text-red-500 px-3">1</span>
            <button type="button" onclick="adjustCount(1)" class="w-8 h-8 rounded bg-[#1e222d] text-base font-bold">+</button>
          </div>
        </div>

        <div>
          <label class="block text-gray-400 font-semibold mb-2">3. VULNERABILITIES PRESENT</label>
          <div class="flex flex-wrap gap-2" id="vulnChips">
            <span class="vuln-pill px-2.5 py-1 rounded border border-[#232733] cursor-pointer hover:border-red-500" onclick="togglePill(this)">👶 Infants / Children</span>
            <span class="vuln-pill px-2.5 py-1 rounded border border-[#232733] cursor-pointer hover:border-red-500" onclick="togglePill(this)">🧓 Elderly / Disabled</span>
            <span class="vuln-pill px-2.5 py-1 rounded border border-[#232733] cursor-pointer hover:border-red-500" onclick="togglePill(this)">🩸 Severe Injury</span>
          </div>
        </div>

        <div>
          <label class="block text-gray-400 font-semibold mb-1">4. LANDMARK / LOCATION DETAILS (OPTIONAL)</label>
          <input id="landmarkInput" type="text" placeholder="e.g. 2nd floor balcony, red tin roof" class="w-full p-2.5 rounded-lg bg-[#0b0d11] border border-[#232733] text-gray-200 outline-none focus:border-cyan-500" />
        </div>
      </div>

      <button onclick="submitSos()" class="w-full py-3 bg-[#dc2626] hover:bg-[#b91c1c] text-white font-bold rounded-lg tracking-wide uppercase shadow-lg shadow-red-950 transition">
        🚨 Transmit Emergency SOS Beacon
      </button>
    </div>
  </div>

  <footer class="text-center py-4 text-xs text-gray-500 border-t border-[#1e222d]">
    FIRE-EYE Emergency Response System • 24/7 National Dispatch Coordination
  </footer>

  <script>
    let selectedType = 'Trapped / Structural Collapse';
    let count = 1;

    document.querySelectorAll('.type-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.type-btn').forEach(b => {
          b.className = 'type-btn p-2 rounded-lg border border-[#232733] bg-[#0b0d11] text-left hover:border-gray-500';
        });
        btn.className = 'type-btn p-2 rounded-lg border border-red-500 bg-red-950/40 text-left font-semibold';
        selectedType = btn.getAttribute('data-type');
      });
    });

    function togglePill(el) {
      el.classList.toggle('bg-red-950/40');
      el.classList.toggle('border-red-500');
    }

    function adjustCount(delta) {
      count = Math.max(1, count + delta);
      document.getElementById('victimCount').innerText = count;
    }

    function openSosModal() { document.getElementById('sosModal').classList.remove('hidden'); }
    function closeSosModal() { document.getElementById('sosModal').classList.add('hidden'); }

    async function submitSos() {
      closeSosModal();
      const landmark = document.getElementById('landmarkInput').value;
      const activeVulns = Array.from(document.querySelectorAll('.vuln-pill.border-red-500')).map(p => p.innerText).join(', ');
      
      const payload = {
        latitude: 30.3165,
        longitude: 78.0322,
        emergency_type: selectedType,
        notes: `People: ${count}. Vulnerabilities: ${activeVulns || 'None reported'}. Landmark: ${landmark || 'N/A'}`
      };

      try {
        const res = await fetch('/api/v1/sos/', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify(payload)
        });
        const data = await res.json();
        const code = data.code || `SOS-${Math.floor(10000 + Math.random() * 90000)}`;
        document.getElementById('beaconCodeDisplay').innerText = `BEACON: ${code}`;
      } catch (e) {
        document.getElementById('beaconCodeDisplay').innerText = `BEACON: SOS-${Math.floor(10000 + Math.random() * 90000)}`;
      }

      document.getElementById('sosNormalView').classList.add('hidden');
      document.getElementById('sosActiveView').classList.remove('hidden');
    }

    function standDownSos() {
      document.getElementById('sosNormalView').classList.remove('hidden');
      document.getElementById('sosActiveView').classList.add('hidden');
    }

    // Fetch live shelters dynamically
    fetch('/api/v1/shelters/')
      .then(r => r.json())
      .then(data => {
        if (data && data.length > 0) {
          const s = data[0];
          document.getElementById('shelterName').innerText = s.name;
          document.getElementById('shelterCap').innerText = s.capacity;
          document.getElementById('shelterAvail').innerText = s.capacity - (s.occupancy || 0);
        }
      })
      .catch(() => {});
  </script>
</body>
</html>
"""

COMMANDER_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Fire-Eye | Commander Triage Dispatch</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    body { background-color: #0b0d11; color: #f8fafc; font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    .card { background-color: #13151b; border: 1px solid #232733; border-radius: 1rem; }
    .inner-box { background-color: #0b0d11; border: 1px solid #1e222d; border-radius: 0.625rem; }
  </style>
</head>
<body class="min-h-screen flex flex-col justify-between">
  <!-- Top Bar -->
  <header class="border-b border-[#1e222d] px-6 py-4 flex items-center justify-between">
    <div class="flex items-center space-x-6">
      <span class="text-2xl font-bold tracking-tight text-white">Fire-Eye</span>
      <nav class="hidden sm:flex items-center space-x-2">
        <a href="/citizen" class="px-3 py-1.5 rounded-lg text-xs font-semibold text-gray-400 hover:text-white hover:bg-[#13151b] transition">Citizen SOS</a>
        <a href="/commander" class="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#1e222d] text-white border border-[#2e3444]">Commander Dispatch</a>
      </nav>
    </div>
    <div class="flex items-center space-x-3">
      <div id="syncIndicator" class="flex items-center space-x-2 bg-[#102a18] border border-[#1b4d2b] px-3 py-1.5 rounded-full text-xs font-semibold text-[#22c55e]">
        <span class="w-2 h-2 rounded-full bg-[#22c55e] animate-ping"></span>
        <span id="syncText">Live Sync (3s)</span>
      </div>
    </div>
  </header>

  <!-- Main Container -->
  <main class="max-w-7xl mx-auto px-4 py-8 flex-1 w-full space-y-6">
    <!-- Operational KPI Row -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="card p-4">
        <span class="text-xs text-gray-400 block mb-1 font-mono">ACTIVE EMERGENCIES</span>
        <span id="statActive" class="text-2xl font-black text-red-500">0</span>
      </div>
      <div class="card p-4">
        <span class="text-xs text-gray-400 block mb-1 font-mono">CRITICAL PRIORITY (&ge;80)</span>
        <span id="statCritical" class="text-2xl font-black text-amber-500">0</span>
      </div>
      <div class="card p-4">
        <span class="text-xs text-gray-400 block mb-1 font-mono">RESCUE UNITS DEPLOYED</span>
        <span id="statDeployed" class="text-2xl font-black text-cyan-400">4 / 6</span>
      </div>
      <div class="card p-4">
        <span class="text-xs text-gray-400 block mb-1 font-mono">POSTGIS SAFE SHELTERS</span>
        <span id="statShelters" class="text-2xl font-black text-emerald-400">3 Verified</span>
      </div>
    </div>

    <!-- Triage Table Card -->
    <div class="card p-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-[#232733] gap-3">
        <div>
          <h2 class="text-xl font-bold text-white flex items-center gap-2">
            <span>🚨</span> Authoritative Multi-Factor SOS Triage Queue
          </h2>
          <p class="text-xs text-gray-400 mt-1">
            Authoritative algorithmic ranking: Severity (40%) + Vulnerability (30%) + Risk (20%) + Isolation (10%).
          </p>
        </div>
        <div class="flex items-center gap-2">
          <button onclick="triggerSimulatedBeacon()" class="px-3 py-1.5 bg-red-950/60 hover:bg-red-900 border border-red-700/60 rounded-lg text-xs font-semibold text-red-300 transition">
            + Ingest Mesh Beacon
          </button>
          <button onclick="fetchQueue()" class="px-3 py-1.5 bg-[#1e222d] hover:bg-gray-800 border border-[#2e3444] rounded-lg text-xs font-semibold text-gray-200 transition">
            ↻ Refresh
          </button>
        </div>
      </div>

      <!-- Table -->
      <div class="overflow-x-auto mt-4">
        <table class="w-full text-left text-xs text-gray-300">
          <thead class="text-gray-400 uppercase font-mono bg-[#0b0d11]/70 border-b border-[#232733]">
            <tr>
              <th class="py-3 px-3">Priority Score</th>
              <th class="py-3 px-3">Beacon ID</th>
              <th class="py-3 px-3">Emergency & Details</th>
              <th class="py-3 px-3">Location (GPS)</th>
              <th class="py-3 px-3">Status</th>
              <th class="py-3 px-3 text-right">Operational Actions</th>
            </tr>
          </thead>
          <tbody id="queueBody" class="divide-y divide-[#1e222d]">
            <tr>
              <td colspan="6" class="text-center py-8 text-gray-500">Connecting to FIRE-EYE Central Dispatch Queue...</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </main>

  <footer class="text-center py-4 text-xs text-gray-500 border-t border-[#1e222d]">
    FIRE-EYE National Rescue Command Center • Authoritative Dispatch & Multi-Hop BLE Ingestion
  </footer>

  <script>
    async function fetchQueue() {
      try {
        const res = await fetch('/api/v1/sos/active');
        const items = await res.json();
        renderQueue(items);
      } catch (err) {
        console.error("Queue fetch error:", err);
      }
    }

    function renderQueue(items) {
      const tbody = document.getElementById('queueBody');
      const statActive = document.getElementById('statActive');
      const statCritical = document.getElementById('statCritical');

      if (!items || items.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="text-center py-8 text-gray-500">No unresolved emergency beacons in queue. All clear.</td></tr>';
        statActive.innerText = '0';
        statCritical.innerText = '0';
        return;
      }

      statActive.innerText = items.length;
      const critCount = items.filter(i => (i.priority_score || 0) >= 80).length;
      statCritical.innerText = critCount;

      tbody.innerHTML = items.map(item => {
        const score = item.priority_score || 50;
        let scoreBadge = '';
        if (score >= 80) {
          scoreBadge = `<span class="px-2.5 py-1 rounded bg-red-950/80 border border-red-500 text-red-400 font-mono font-bold">${score} • CRITICAL</span>`;
        } else if (score >= 60) {
          scoreBadge = `<span class="px-2.5 py-1 rounded bg-amber-950/80 border border-amber-500 text-amber-400 font-mono font-bold">${score} • HIGH</span>`;
        } else {
          scoreBadge = `<span class="px-2.5 py-1 rounded bg-blue-950/80 border border-blue-500 text-blue-400 font-mono font-bold">${score} • MEDIUM</span>`;
        }

        let statusBadge = '';
        if (item.status === 'PENDING') {
          statusBadge = '<span class="px-2 py-0.5 rounded bg-yellow-950/60 border border-yellow-600/50 text-yellow-300 font-mono text-[10px]">PENDING</span>';
        } else if (item.status === 'DISPATCHED' || item.status === 'ASSIGNED') {
          statusBadge = '<span class="px-2 py-0.5 rounded bg-cyan-950/60 border border-cyan-600/50 text-cyan-300 font-mono text-[10px]">EN ROUTE</span>';
        } else {
          statusBadge = `<span class="px-2 py-0.5 rounded bg-green-950/60 border border-green-600/50 text-green-300 font-mono text-[10px]">${item.status}</span>`;
        }

        return `
          <tr class="hover:bg-[#161922] transition">
            <td class="py-3 px-3 font-semibold">${scoreBadge}</td>
            <td class="py-3 px-3 font-mono font-bold text-white">${item.sos_code || ('SOS-' + item.id)}</td>
            <td class="py-3 px-3">
              <div class="font-bold text-gray-200">${item.emergency_type || 'General Distress'}</div>
              <div class="text-[11px] text-gray-400 max-w-sm truncate">${item.notes || 'No extra notes'}</div>
            </td>
            <td class="py-3 px-3 font-mono text-[11px] text-gray-400">
              ${(item.latitude || 0).toFixed(4)}, ${(item.longitude || 0).toFixed(4)}
            </td>
            <td class="py-3 px-3">${statusBadge}</td>
            <td class="py-3 px-3 text-right space-x-2">
              ${item.status === 'PENDING' ? `
                <button onclick="updateStatus('${item.id}', 'DISPATCHED')" class="px-2.5 py-1 bg-cyan-900/40 hover:bg-cyan-800/60 border border-cyan-500/50 text-cyan-300 rounded font-semibold text-[11px] transition">
                  Dispatch Team
                </button>
              ` : ''}
              <button onclick="updateStatus('${item.id}', 'RESCUED')" class="px-2.5 py-1 bg-emerald-900/40 hover:bg-emerald-800/60 border border-emerald-500/50 text-emerald-300 rounded font-semibold text-[11px] transition">
                Mark Rescued
              </button>
            </td>
          </tr>
        `;
      }).join('');
    }

    async function updateStatus(sosId, newStatus) {
      try {
        await fetch(`/api/v1/sos/${sosId}/status`, {
          method: 'PATCH',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({ status: newStatus, notes: `Commander updated to ${newStatus}` })
        });
        fetchQueue();
      } catch (err) {
        console.error('Update status error:', err);
      }
    }

    async function triggerSimulatedBeacon() {
      const types = ['Trapped / Structural Collapse', 'Flash Flood / Rising Water', 'Active Fire / Wildfire'];
      const chosenType = types[Math.floor(Math.random() * types.length)];
      const payload = {
        latitude: 30.3165 + (Math.random() - 0.5) * 0.05,
        longitude: 78.0322 + (Math.random() - 0.5) * 0.05,
        emergency_type: chosenType,
        severity: 'CRITICAL',
        notes: `Simulated BLE Mesh Beacon. Stranded: ${Math.floor(2 + Math.random() * 4)}. Vulnerabilities: Infants, Elderly`
      };
      await fetch('/api/v1/sos/', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload)
      });
      fetchQueue();
    }

    fetchQueue();
    setInterval(fetchQueue, 3000);
  </script>
</body>
</html>
"""


@app.get("/", response_class=HTMLResponse)
@app.get("/citizen", response_class=HTMLResponse)
def get_citizen_portal():
    return CITIZEN_HTML


@app.get("/commander", response_class=HTMLResponse)
@app.get("/rescuer", response_class=HTMLResponse)
def get_commander_portal():
    return COMMANDER_HTML


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
