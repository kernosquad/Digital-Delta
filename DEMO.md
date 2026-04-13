# Digital Delta — Judge Demo Walkthrough

> **HackFusion 2026** | Step-by-step evaluation guide for all 8 modules + Track A UI/UX  
> Estimated demo time: **10 minutes** (core path) | Full coverage: ~20 minutes

---

## Setup Before the Demo

### Services to start (3 terminals)

**Terminal 1 — Backend API**

```bash
cd apps/api
node ace serve --hmr
# Expected: "Server started on http://localhost:3333"
```

**Terminal 2 — Web Dashboard**

```bash
cd apps/web
pnpm dev
# Expected: "Ready on http://localhost:3000"
```

**Terminal 3 — Chaos Server**

```bash
cd docs
python3 chaos_server.py
# Expected: "Hackfusion 2026: Digital Delta Chaos API is running!"
```

**Mobile app** — run on Android device/emulator:

```bash
cd apps/digital_delta_mobile_app
flutter run
```

### Verify baseline health

```bash
curl http://localhost:3333/health
# {"status":"ok","timestamp":"..."}
```

---

## Track A — UI/UX & Frontend Design [30 pts]

> Judges: Evaluate this track independently from backend correctness.

### A1 — Visual Design System (6 pts)

1. Open `http://localhost:3000`
2. Observe: consistent color palette (emergency red `#D32F2F`, relief teal `#00796B`, neutral grays), Inter typeface hierarchy, card components from Ant Design token system
3. Note: all interactive states (hover, active, disabled, loading) are styled consistently

### A2 — Responsive Layouts (6 pts)

1. In browser DevTools, resize to:
   - **360px** — mobile: hamburger nav, stacked cards
   - **768px** — tablet: two-column grid, collapsible sidebar
   - **1440px** — desktop: full three-column dashboard layout
2. Disable Wi-Fi → reload page → offline banner appears, cached data renders (no layout break)

### A3 — Dashboard & Data Visualization (8 pts)

1. Navigate to `http://localhost:3000/dashboard/map`
2. Observe: live route map with node markers (camps, hubs, waypoints), edge overlays colored by flood risk
3. Navigate to `http://localhost:3000/dashboard` → main overview
4. Supply heatmap, mission priority counts, and node status panel load within **3 seconds** of page load
5. Open SSE stream in browser console:

```js
const es = new EventSource('http://localhost:3333/api/dashboard/stream', { withCredentials: true });
es.onmessage = (e) => console.log(JSON.parse(e.data));
```

### A4 — Accessibility (5 pts)

1. Tab through login form — all fields focusable, visible focus ring
2. Run Lighthouse accessibility audit → score ≥ 90
3. Screen reader: all buttons/inputs have `aria-label` or visible text labels
4. Color contrast: emergency red on white = 5.3:1 (> 4.5:1 WCAG AA)

### A5 — Offline Indicator & Sync State (5 pts)

1. Open mobile app → banner shows **"Online — Synced"** (green)
2. Enable airplane mode → banner transitions to **"Offline — Working locally"** (amber)
3. Re-enable network → banner shows **"Syncing…"** spinner then **"Synced"** (green)
4. Introduce a conflict (see M2 demo) → banner shows **"Conflict Detected"** (red) with resolution prompt

---

## Module 1 — Secure Authentication & Identity [9 pts]

### M1.1 — Mobile OTP (3 pts)

```bash
# Register a new field volunteer
curl -X POST http://localhost:3333/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@dd.org","password":"Demo1234!","role":"field_volunteer"}'

# Setup TOTP (returns base32 secret + QR URI)
curl -X POST http://localhost:3333/api/auth/otp/setup \
  -H "Authorization: Bearer <token>"

# Verify OTP — use any TOTP app (Google Authenticator) or:
python3 -c "import pyotp; print(pyotp.TOTP('<secret>').now())"

curl -X POST http://localhost:3333/api/auth/otp/verify \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"token":"<6-digit-otp>"}'
```

**Expected:** OTP valid for 30-second window; expired token returns `{"error":"OTP expired or invalid"}`.

### M1.2 — Asymmetric Key Provisioning (3 pts)

```bash
curl -X POST http://localhost:3333/api/auth/keys/provision \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"algorithm":"ed25519","device_id":"device-alice-001"}'
```

**Expected:** Returns `{"public_key":"<base64>","algorithm":"ed25519","device_id":"..."}`. Public key stored in `user_keys` table. Private key never leaves device.

### M1.3 — RBAC Enforcement (2 pts)

```bash
# field_volunteer tries to access /api/users (sync_admin only)
curl -X GET http://localhost:3333/api/users \
  -H "Authorization: Bearer <field_volunteer_token>"
# Expected: 403 Forbidden

# sync_admin can access
curl -X GET http://localhost:3333/api/users \
  -H "Authorization: Bearer <admin_token>"
# Expected: 200 with user list
```

### M1.4 — Immutable Audit Log (1 pt)

```bash
curl http://localhost:3333/api/dashboard/stats \
  -H "Authorization: Bearer <admin_token>"

# Inspect audit log table (hash-chaining demo):
curl http://localhost:3000/dashboard/audit
```

**Expected:** Each auth event row shows `prev_hash` → `hash` chain. Tampering with any row breaks the chain (validated server-side on each read).

---

## Module 2 — Offline CRDT Sync [10 pts]

### M2.1 — CRDT Data Model (4 pts)

```bash
# Device A: Update supply inventory
curl -X POST http://localhost:3333/api/sync/push \
  -H "Authorization: Bearer <token_device_a>" \
  -H "Content-Type: application/json" \
  -d '{
    "operations": [{
      "entity_type": "inventory",
      "entity_id": "inv-001",
      "field": "quantity",
      "value": 150,
      "vector_clock": {"device_a": 1},
      "operation_type": "lww_set"
    }]
  }'

# Device B: Concurrent conflicting update (simulated offline)
curl -X POST http://localhost:3333/api/sync/push \
  -H "Authorization: Bearer <token_device_b>" \
  -H "Content-Type: application/json" \
  -d '{
    "operations": [{
      "entity_type": "inventory",
      "entity_id": "inv-001",
      "field": "quantity",
      "value": 200,
      "vector_clock": {"device_b": 1},
      "operation_type": "lww_set"
    }]
  }'

# Reconnect — pull reveals conflict
curl -X POST http://localhost:3333/api/sync/pull \
  -H "Authorization: Bearer <token_device_a>" \
  -H "Content-Type: application/json" \
  -d '{"last_vector_clock": {"device_a": 1}}'
```

**Expected:** Conflict detected, both values returned, resolution UI shown in `http://localhost:3000/dashboard/sync`.

### M2.2 — Vector Clock Causal Ordering (3 pts)

```bash
# Verify causal ordering: pull shows operations in correct causal order
curl http://localhost:3333/api/sync/pull \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"last_vector_clock": {}}'
```

**Expected:** Response includes `vector_clock` on each operation; causal order preserved.

### M2.3 — Conflict Visualization (2 pts)

1. Navigate to `http://localhost:3000/dashboard/sync`
2. A conflict row shows both values side-by-side with **"Accept A"** / **"Accept B"** / **"Merge"** buttons
3. Resolution is logged to `sync_conflicts` table with `resolved_by` and `resolution`

### M2.4 — Delta Sync Bandwidth (1 pt)

```bash
# Measure payload size — only changed records transmitted
curl -X POST http://localhost:3333/api/sync/pull \
  -H "Authorization: Bearer <token>" \
  -d '{"last_vector_clock": {"device_a": 5}}' \
  -w "\nResponse size: %{size_download} bytes\n"
```

**Expected:** < 10 KB for typical 10-record delta.

---

## Module 3 — Ad-Hoc Mesh Network [9 pts]

### M3.1 — Store-and-Forward Relay (4 pts)

```bash
# Send a message destined for an offline node
curl -X POST http://localhost:3333/api/mesh/send \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "recipient_device_id": "device-charlie-003",
    "payload_encrypted": "<base64-aes256gcm>",
    "ttl_hours": 24,
    "priority": "high"
  }'

# Relay node (Device B) picks up and forwards
curl http://localhost:3333/api/mesh/messages?device_id=device-charlie-003

# When Device C comes online, it fetches its queued messages
curl "http://localhost:3333/api/mesh/messages?device_id=device-charlie-003&fetch_pending=true"
```

**Expected:** Message survives Device B going offline mid-relay; delivered when C reconnects. TTL expiry returns `{"error":"message_expired"}`.

### M3.2 — Dual-Role Node Architecture (3 pts)

```bash
# Check relay role assignments
curl http://localhost:3333/api/mesh/messages \
  -H "Authorization: Bearer <token>"
```

**On mobile app:** Settings → Mesh → shows current role: **CLIENT** or **RELAY**. Role switches automatically when battery > 30% and device is stationary (accelerometer = 0).

### M3.3 — E2E Encryption (2 pts)

```bash
# Inspect mesh_messages table — payload column is always ciphertext
curl http://localhost:3000/dashboard/mesh
```

**Expected:** Dashboard shows `payload_encrypted` column — raw bytes, never plaintext. Relay nodes logged in `mesh_relay_logs` with no decrypted content.

**Packet inspection demo:**

```bash
# On mobile: enable Wireshark/tcpdump on BLE interface
# All inter-node frames show AES-256-GCM encrypted payload
# Relay node CANNOT read content — verified by packet inspector
```

---

## Module 4 — Multi-Modal VRP Routing [10 pts]

### M4.1 — Graph Representation (3 pts)

```bash
# List all route edges (roads, waterways, airways)
curl http://localhost:3333/api/network/routes \
  -H "Authorization: Bearer <token>"
```

**Expected:** Each edge has `type` ∈ {`road`,`waterway`,`airway`}, `base_weight_mins`, `is_flooded`, `is_blocked`, `capacity`.

### M4.2 — Dynamic Re-Computation on Node Failure (4 pts)

```bash
# Mark a road edge as flooded (simulates chaos server event)
curl -X PATCH http://localhost:3333/api/network/routes/E1/condition \
  -H "Authorization: Bearer <sync_admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"is_flooded": true}'

# Re-run VRP — system recalculates within 2 seconds
time curl -X POST http://localhost:3333/api/network/vrp \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "origin_id": "N1",
    "destination_id": "N4",
    "vehicle_type": "truck",
    "payload_kg": 500
  }'
```

**Expected:** New route avoids flooded edge. Re-computation time logged in response `computed_in_ms` < 2000.

### M4.3 — Vehicle-Type Constraints (2 pts)

```bash
# Drone cannot use road edges
curl -X POST http://localhost:3333/api/network/vrp \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"origin_id":"N1","destination_id":"N4","vehicle_type":"drone","payload_kg":10}'
# Expected: route uses only airway edges

# Speedboat cannot use road edges
curl -X POST http://localhost:3333/api/network/vrp \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"origin_id":"N1","destination_id":"N3","vehicle_type":"speedboat","payload_kg":200}'
# Expected: route uses only waterway edges
```

### M4.4 — Live Map Visualization (1 pt)

1. Open `http://localhost:3000/dashboard/map`
2. Trigger flood on edge E1 (above command)
3. **Map updates in real-time** — flooded edge turns red, active routes re-drawn with new path
4. Vehicle position markers move along updated route

---

## Module 5 — Zero-Trust Proof-of-Delivery [7 pts]

### M5.1 — QR Challenge-Response Handshake (3 pts)

```bash
# Step 1: Driver generates QR
curl -X POST http://localhost:3333/api/delivery/generate-qr \
  -H "Authorization: Bearer <driver_token>" \
  -H "Content-Type: application/json" \
  -d '{"mission_id":"mission-001","payload_hash":"<sha256_of_manifest>"}'
# Returns: QR payload (signed with driver's Ed25519 private key)

# Step 2: Recipient scans and countersigns (via mobile app QR scanner)
# Step 3: Verify countersignature
curl -X POST http://localhost:3333/api/delivery/verify \
  -H "Authorization: Bearer <recipient_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "qr_payload": "<base64_signed_qr>",
    "recipient_signature": "<base64_countersig>",
    "nonce": "<uuid>"
  }'
```

**Expected:** `{"verified": true, "receipt_id": "...", "timestamp": "..."}` — no internet required (offline cryptographic verification).

### M5.2 — Replay Protection (2 pts)

```bash
# Replay the same nonce
curl -X POST http://localhost:3333/api/delivery/verify \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"qr_payload":"<same_as_above>","nonce":"<same_nonce>"}'
# Expected: 409 {"error":"nonce_already_used","code":"REPLAY_DETECTED"}
```

### M5.3 — Delivery Receipt Chain (2 pts)

```bash
# Each receipt is appended to CRDT ledger
curl http://localhost:3333/api/delivery/receipts \
  -H "Authorization: Bearer <token>"
```

**Expected:** Each receipt links to `crdt_operations` via `operation_id`. Chain of custody reconstructable from ledger history alone (no external DB needed).

---

## Module 6 — Autonomous Triage & Priority Preemption [7 pts]

### M6.1 — Priority Taxonomy (2 pts)

```bash
curl http://localhost:3333/api/triage/taxonomy \
  -H "Authorization: Bearer <token>"
```

**Expected:**

```json
{
  "P0": { "label": "Critical Medical", "sla_hours": 2, "examples": ["antivenom", "insulin"] },
  "P1": { "label": "High", "sla_hours": 6, "examples": ["water purification", "medical supplies"] },
  "P2": { "label": "Standard", "sla_hours": 24, "examples": ["food rations", "blankets"] },
  "P3": { "label": "Low", "sla_hours": 72, "examples": ["non-essential goods"] }
}
```

### M6.2 — Real-Time SLA Breach Prediction (3 pts)

```bash
# Create a mission with P0 priority that is close to SLA breach
curl -X POST http://localhost:3333/api/missions \
  -H "Authorization: Bearer <supply_manager_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "priority_class":"P0",
    "cargo":[{"supply_item_id":"antivenom-001","quantity":50}],
    "origin_location_id":"N1",
    "destination_location_id":"N4"
  }'

# Simulate route delay (flood event on M4)
# Then check SLA status
curl http://localhost:3333/api/triage/sla-status \
  -H "Authorization: Bearer <token>"
```

**Expected:** P0 mission ETA > 2h → `breach_predicted: true`, `preemption_triggered: true`.

### M6.3 — Autonomous Drop-and-Reroute (2 pts)

```bash
curl -X POST http://localhost:3333/api/triage/auto-preempt \
  -H "Authorization: Bearer <camp_commander_token>" \
  -H "Content-Type: application/json" \
  -d '{"mission_id":"mission-002"}'
```

**Expected:** P2/P3 cargo offloaded to nearest safe waypoint; vehicle immediately rerouted to complete P0/P1 cargo. Decision logged to `triage_decisions` with `rationale` field. Visible at `http://localhost:3000/dashboard/triage`.

---

## Module 7 — Predictive Route Decay (ML) [9 pts]

### M7.1 — Sensor Ingestion (2 pts)

```bash
# Ingest simulated rainfall sensor data at 1 Hz
curl -X POST http://localhost:3333/api/sensors \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "route_id":"E1",
    "sensor_type":"rainfall",
    "value":45.2,
    "unit":"mm_per_hour",
    "recorded_at":"2026-04-13T10:00:00Z"
  }'

# Bulk ingest CSV (for demo dataset)
# See docs/ml_model_card.md for dataset description
```

### M7.2 — Impassability Classifier (3 pts)

```bash
# Get ML prediction for edge E1
curl "http://localhost:3333/api/sensors/predictions?route_id=E1" \
  -H "Authorization: Bearer <token>"
```

**Expected:**

```json
{
  "route_id": "E1",
  "impassable_within_2h": true,
  "probability": 0.87,
  "risk_level": "critical",
  "features": {
    "cumulative_rainfall_mm": 182.4,
    "rate_of_change": 12.3,
    "soil_saturation_proxy": 0.91,
    "elevation_m": 12
  },
  "model_version": "v1.2",
  "predicted_at": "2026-04-13T10:01:00Z"
}
```

See [docs/ml_model_card.md](docs/ml_model_card.md) for F1/precision/recall metrics.

### M7.3 — Proactive Rerouting Integration (3 pts)

```bash
# High-risk prediction (prob > 0.7) triggers rerouting recommendation
curl http://localhost:3333/api/network/vrp \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"origin_id":"N1","destination_id":"N3","vehicle_type":"truck","payload_kg":400}'
```

**Expected:** Response includes `ml_warnings: [{"route_id":"E1","risk":"critical","probability":0.87}]` and route avoids E1 automatically.

### M7.4 — Prediction Confidence Display (1 pt)

1. Open `http://localhost:3000/dashboard/map`
2. Each edge is color-coded: green (< 0.3), yellow (0.3–0.7), red (> 0.7)
3. Hover an edge → tooltip shows probability score, contributing features, and prediction timestamp
4. Open `http://localhost:3000/dashboard/ml` for full prediction table

---

## Module 8 — Hybrid Fleet & Drone Handoff [9 pts]

### M8.1 — Reachability Analysis (2 pts)

```bash
curl -X POST http://localhost:3333/api/network/vrp \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"origin_id":"N2","destination_id":"N6","vehicle_type":"truck"}'
# If N6 unreachable by truck → response includes "drone_required": true
```

**Expected:** Destinations unreachable by ground/water flagged as **"Drone-Required Zone"** in `http://localhost:3000/dashboard/map`.

### M8.2 — Optimal Rendezvous Computation (3 pts)

```bash
curl -X POST http://localhost:3333/api/handoff \
  -H "Authorization: Bearer <drone_operator_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "boat_id": "vehicle-boat-01",
    "drone_id": "vehicle-drone-01",
    "destination_location_id": "N6",
    "payload_kg": 8
  }'
```

**Expected:** Response includes `rendezvous_point` (geographic midpoint minimizing total travel time for both agents), `boat_eta_mins`, `drone_eta_mins`. Correct on ≥ 3 test scenarios.

### M8.3 — Handoff Coordination Protocol (2 pts)

```bash
# Boat arrives at rendezvous — generates PoD receipt (Module 5)
curl -X POST http://localhost:3333/api/delivery/generate-qr \
  -H "Authorization: Bearer <driver_token>" \
  -d '{"mission_id":"mission-drone-001","payload_hash":"<hash>"}'

# Drone acknowledges with counter-signature
curl -X POST http://localhost:3333/api/delivery/verify \
  -H "Authorization: Bearer <drone_operator_token>" \
  -d '{"qr_payload":"...","recipient_signature":"...","nonce":"..."}'

# Ownership transferred in CRDT ledger
curl http://localhost:3333/api/handoff \
  -H "Authorization: Bearer <token>"
```

**Expected:** Handoff event record shows `boat_departed`, `drone_received`, `pod_receipt_id`, `crdt_operation_id`.

### M8.4 — Battery-Aware Mesh Throttling (2 pts)

On the mobile app:

1. Settings → Developer → Simulate Battery 25%
2. Observe: mesh broadcast frequency drops from 10s → 25s intervals (60% reduction)
3. Settings → Developer → Simulate Stationary + Battery 15%
4. Observe: broadcast frequency drops to every 50s (80% reduction)
5. Navigate near known node → frequency returns to baseline

**Dashboard verification:**

```bash
curl http://localhost:3000/dashboard/mesh
# Shows relay_frequency_hz per device alongside battery_level
```

---

## Fault Injection Scenarios (Bonus)

### Scenario 1 — Offline Sync (M2 + M3 combined)

1. Disconnect mobile Device A from network
2. On Device A: create 3 new supply inventory updates
3. On Device B (connected): create conflicting updates for same items
4. Reconnect Device A → observe delta-sync < 10 KB, conflict resolution UI fires

### Scenario 2 — Route Collapse (M4 + M6 + M7)

1. Start chaos server: `python3 docs/chaos_server.py`
2. Watch dashboard `http://localhost:3000/dashboard/map` — edges flood randomly
3. Active missions auto-reroute (M4)
4. If P0 mission ETA breaches SLA → autonomous preemption fires (M6)
5. ML predictions turn edges red before flood confirmed (M7)

### Scenario 3 — Replay Attack (M5)

1. Capture a valid PoD QR payload
2. Re-submit it 60 seconds later
3. **Expected:** `409 REPLAY_DETECTED` — nonce already consumed

### Scenario 4 — Drone Last-Mile (M8)

1. Mark all roads to N6 (Habiganj Medical) as flooded
2. Run VRP for truck → `drone_required: true`
3. Create handoff → compute rendezvous point
4. Complete PoD handshake → ownership transfers in CRDT ledger

---

## API Test Collection

A Postman/Bruno collection is available at `docs/Digital_Delta.postman_collection.json` (import and set `{{baseUrl}}=http://localhost:3333` and `{{token}}` to your JWT).

---

## Reset Between Demo Runs

```bash
# Reset chaos server map
curl -X POST http://localhost:5000/api/network/reset

# Reset database to seed state
cd apps/api
node ace migration:rollback --batch 1
node ace migration:run
node ace db:seed
```

---

_"The measure of an engineer is not the beauty of the algorithm on a whiteboard, but the reliability of the system under pressure, at 3 AM, when the power flickers."_  
— HackFusion 2026 Organizing Committee
