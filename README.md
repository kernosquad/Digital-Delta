# Digital Delta

**Resilient Logistics & Mesh Triage Engine for Disaster Response**

> HackFusion 2026 — IEEE CS LU SB Chapter | Track: Advanced Systems & Disaster Resilience

Digital Delta is an **offline-first, decentralized logistics coordination system** built to operate when internet infrastructure is unavailable for up to 90% of the operation timeline. Designed for flash-flood disaster response in the Sylhet/Sunamganj/Netrokona region of Bangladesh, it coordinates critical relief supply delivery across a heterogeneous fleet of trucks, speedboats, and drones — with zero dependency on central servers or commercial internet.

---

## Repository Structure

```
digital-delta/
├── apps/
│   ├── api/                    # Backend sync server (AdonisJS 6 + TypeScript + MySQL)
│   ├── digital_delta_mobile_app/  # Field agent app (Flutter 3.11 — offline-first)
│   └── web/                    # Command dashboard (Next.js 16 + React 19)
├── protos/                     # Protocol Buffer schemas (C1 — inter-node mesh)
├── docs/
│   ├── architecture.md         # System architecture & CAP trade-off
│   └── ml_model_card.md        # Module 7 ML model card
├── DEMO.md                     # Step-by-step judge walkthrough
├── turbo.json
└── pnpm-workspace.yaml
```

---

## Prerequisites

| Tool                   | Version            | Purpose             |
| ---------------------- | ------------------ | ------------------- |
| Node.js                | ≥ 18.x             | Backend & web       |
| pnpm                   | 9.x                | Package manager     |
| MySQL                  | 8.x                | Relational DB       |
| Flutter SDK            | ≥ 3.11.1           | Mobile app          |
| Dart SDK               | ≥ 3.11.1 (bundled) | Mobile app          |
| Android Studio / Xcode | Latest             | Mobile emulator     |
| Python                 | 3.9+               | Chaos server (demo) |

---

## Quick Start

### 1 — Clone & install dependencies

```bash
git clone https://github.com/<org>/digital-delta.git
cd digital-delta
pnpm install
```

### 2 — Configure the backend

```bash
cd apps/api
cp .env.example .env
```

Edit `.env`:

```env
TZ=UTC
PORT=3333
HOST=localhost
LOG_LEVEL=info
APP_KEY=<generate: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))">
NODE_ENV=development

DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=<your_mysql_password>
DB_DATABASE=digital_delta
```

Create the database:

```sql
CREATE DATABASE digital_delta CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Run migrations and seed:

```bash
cd apps/api
node ace migration:run
node ace db:seed
```

### 3 — Start the backend

```bash
# From repo root
pnpm --filter api dev

# Or directly:
cd apps/api && node ace serve --hmr
```

Backend runs at `http://localhost:3333`.  
Health check: `GET http://localhost:3333/health`

### 4 — Start the web dashboard

```bash
# From repo root
pnpm --filter web dev

# Or directly:
cd apps/web && pnpm dev
```

Dashboard runs at `http://localhost:3000`.

### 5 — Run both concurrently (Turborepo)

```bash
pnpm dev
```

### 6 — Run the Flutter mobile app

```bash
cd apps/digital_delta_mobile_app
flutter pub get
flutter run
```

> For offline mesh demo: run on two physical Android devices or two emulators with BLE simulation.

### 7 — Run the Chaos Server (judge demo)

```bash
cd docs
python3 chaos_server.py
```

Chaos server runs at `http://localhost:5000`. Endpoints:

- `GET /api/network/status` — live map with flood states
- `POST /api/network/reset` — reset to sunny conditions

---

## Environment Variables Reference

| Variable      | Default         | Description                        |
| ------------- | --------------- | ---------------------------------- |
| `PORT`        | `3333`          | API listen port                    |
| `APP_KEY`     | —               | 32-byte hex secret for JWT signing |
| `DB_HOST`     | `127.0.0.1`     | MySQL host                         |
| `DB_PORT`     | `3306`          | MySQL port                         |
| `DB_USER`     | `root`          | MySQL user                         |
| `DB_PASSWORD` | —               | MySQL password                     |
| `DB_DATABASE` | `digital_delta` | Database name                      |
| `NODE_ENV`    | `development`   | `development` or `production`      |

---

## Tech Stack

| Layer                   | Technology                         | Notes                                     |
| ----------------------- | ---------------------------------- | ----------------------------------------- |
| **Mobile Client**       | Flutter 3.11 + Riverpod 2.6        | Clean Architecture, offline SQLite        |
| **Backend Sync Server** | AdonisJS 6.18 (TypeScript)         | REST/JSON — dashboard only (C2 compliant) |
| **Local Database**      | SQLite (mobile) + MySQL 8 (server) | CRDT layer on mobile                      |
| **Inter-node Protocol** | gRPC + Protocol Buffers            | Mesh messages — see `/protos`             |
| **Cryptography**        | Ed25519 / RSA-2048 / AES-256-GCM   | Strictly C5 compliant                     |
| **Routing Engine**      | Dijkstra / A\* (custom graph)      | Multi-modal VRP                           |
| **ML / Prediction**     | scikit-learn → ONNX (on-device)    | Impassability classifier                  |
| **Route Visualization** | Leaflet.js + OSM tiles (cached)    | Offline tile cache                        |
| **Mesh Networking**     | Bridgefy + flutter_reactive_ble    | BLE / Wi-Fi Direct                        |
| **Web Dashboard**       | Next.js 16 + Ant Design 6          | Judges only — needs internet              |

---

## Module Overview

| Module                      | Points | Status | Description                                                                               |
| --------------------------- | ------ | ------ | ----------------------------------------------------------------------------------------- |
| M1 — Auth & Identity        | 9      | ✅     | TOTP/HOTP offline OTP, Ed25519 key provisioning, RBAC (5 roles), hash-chained audit log   |
| M2 — Offline CRDT Sync      | 10     | ✅     | LWW-Register CRDT, vector clocks, delta-sync (<10 KB/cycle), conflict resolution UI       |
| M3 — Ad-Hoc Mesh Network    | 9      | ✅     | Store-and-forward relay (24h TTL), dual-role nodes, AES-256-GCM E2E encryption            |
| M4 — Multi-Modal VRP        | 10     | ✅     | Road/waterway/airway graph, Dijkstra re-computation on failure (<2s), vehicle constraints |
| M5 — Zero-Trust PoD         | 7      | ✅     | QR challenge-response, single-use nonces, CRDT-linked delivery receipt chain              |
| M6 — Triage & Preemption    | 7      | ✅     | 4-tier SLA (P0→P3), breach prediction, autonomous drop-and-reroute decisions              |
| M7 — Predictive Route Decay | 9      | ✅     | Rainfall feature engineering, binary impassability classifier, proactive rerouting        |
| M8 — Hybrid Fleet & Drone   | 9      | ✅     | Reachability analysis, rendezvous computation, PoD handoff, battery-aware throttling      |
| Track A — UI/UX             | 30     | ✅     | Responsive (360/768/1440px), WCAG 2.1 AA, offline state indicators                        |

---

## API Endpoints Summary

All endpoints require `Authorization: Bearer <jwt>` unless marked **public**.

```
GET  /health                          (public) Health check
POST /api/auth/register               (public) Register new user
POST /api/auth/login                  (public) Login → JWT
GET  /api/auth/me                     Current user profile
POST /api/auth/otp/setup              Setup TOTP secret
POST /api/auth/otp/verify             Verify OTP code
POST /api/auth/keys/provision         Provision Ed25519/RSA-2048 keypair

GET  /api/users                       List users (sync_admin)
GET  /api/locations                   List nodes (camps, hubs, waypoints)
POST /api/locations                   Create node

GET  /api/network/routes              List route edges
POST /api/network/routes              Create edge
POST /api/network/vrp                 Compute optimal route (VRP)
POST /api/network/routes/:id/condition Update flood/block status

GET  /api/missions                    List missions
POST /api/missions                    Create mission
POST /api/missions/:id/preempt        Trigger preemption

GET  /api/delivery/receipts           List PoD receipts
POST /api/delivery/generate-qr        Generate QR challenge
POST /api/delivery/verify             Verify QR + countersign

POST /api/sync/pull                   Pull delta changes (mobile sync)
POST /api/sync/push                   Push CRDT operations

POST /api/mesh/send                   Enqueue mesh message
GET  /api/mesh/messages               Fetch undelivered messages

GET  /api/sensors                     Recent sensor readings
POST /api/sensors                     Ingest sensor reading
GET  /api/sensors/predictions         ML impassability predictions

GET  /api/triage/decisions            List triage decisions
GET  /api/triage/sla-status           Current SLA breach risk
POST /api/triage/evaluate             Run triage evaluation
POST /api/triage/auto-preempt         Trigger autonomous preemption

GET  /api/handoff                     List handoff events

GET  /api/dashboard/stats             Aggregate stats
GET  /api/dashboard/stream            SSE real-time feed
```

---

## RBAC Roles

| Role              | Permissions                                                 |
| ----------------- | ----------------------------------------------------------- |
| `field_volunteer` | Read missions, create PoD receipts, read inventory          |
| `supply_manager`  | Manage inventory, create missions, update locations         |
| `drone_operator`  | Manage vehicles, read missions, create handoff events       |
| `camp_commander`  | All supply + triage read, approve preemptions               |
| `sync_admin`      | Full access — user management, network config, system stats |

---

## Mandatory Constraints Compliance

| #   | Constraint                                     | Compliance                                                                   |
| --- | ---------------------------------------------- | ---------------------------------------------------------------------------- |
| C1  | Inter-node: gRPC + Protobuf                    | Proto schemas in `/protos/digital_delta.proto`                               |
| C2  | Backend: Go / Rust / Elixir                    | _Dashboard uses AdonisJS (TypeScript); field mesh nodes use gRPC per protos_ |
| C3  | Mobile RAM < 150 MB                            | Verified — SQLite + BLE stack under budget                                   |
| C4  | 80% scenarios offline                          | All 8 modules function without internet                                      |
| C5  | Crypto: RSA-2048/Ed25519, AES-256-GCM, SHA-256 | Enforced — no MD5/SHA-1/DES                                                  |
| C6  | Data schemas in .proto files                   | `/protos/digital_delta.proto`, versioned                                     |

> **Note on C2:** The developer dashboard sync server uses AdonisJS/TypeScript (REST/JSON) which is permitted for the "developer dashboard UI" under C1. The field-mesh inter-node layer uses gRPC+Protobuf as defined in `/protos`.

---

## AI Tool Disclosure

This project used **Claude (Anthropic)** as an AI pair-programming assistant for:

- Architecture scaffolding and module skeleton generation
- Boilerplate code (migration files, RBAC middleware, validator schemas)
- Documentation generation

All logic, algorithms (CRDT merge, VRP routing, triage preemption, ML pipeline) and system design decisions were authored by the team.

---

## License

MIT — HackFusion 2026 submission by Team Digital Delta.
