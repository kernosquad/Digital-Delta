# Digital Delta — System Architecture

> HackFusion 2026 | Track: Advanced Systems & Disaster Resilience

---

## 1. High-Level System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         INTERNET (Available < 10% uptime)                   │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │ REST/JSON (dashboard only, when online)
                    ┌──────────────▼──────────────┐
                    │     Web Dashboard (Next.js) │
                    │  Command & Control Center   │
                    │  localhost:3000             │
                    └──────────────┬──────────────┘
                                   │ REST/JSON (C1 permitted for dashboard)
                    ┌──────────────▼──────────────┐
                    │   Backend Sync Server       │
                    │   AdonisJS 6 + MySQL 8      │
                    │   localhost:3333            │
                    │   14 REST modules           │
                    └──────────────┬──────────────┘
                                   │ delta-sync (when reachable)
          ┌────────────────────────┼──────────────────────┐
          │                        │                       │
┌─────────▼──────┐       ┌────────▼───────┐     ┌────────▼───────┐
│  Field Device A│       │ Field Device B │     │ Field Device C │
│  (Flutter App) │       │  (Flutter App) │     │  (Flutter App) │
│  SQLite + CRDT │       │  SQLite + CRDT │     │  SQLite + CRDT │
│  Offline-first │       │  Offline-first │     │  Offline-first │
└────────┬───────┘       └────────┬───────┘     └────────┬───────┘
         │                        │                       │
         │         gRPC + Protobuf (MANDATORY — C1)       │
         │      ◄──── BLE / Wi-Fi Direct Mesh ────►       │
         │                        │                       │
         └────────────────────────┴───────────────────────┘
                    AD-HOC MESH NETWORK (No Wi-Fi router required)
```

---

## 2. Component Architecture

```mermaid
graph TB
    subgraph "Field Layer (Offline-First)"
        MA[Mobile App A<br/>Flutter 3.11]
        MB[Mobile App B<br/>Flutter 3.11]
        MC[Mobile App C<br/>Flutter 3.11]
        MA <-->|gRPC+Protobuf<br/>BLE/Wi-Fi Direct| MB
        MB <-->|gRPC+Protobuf<br/>BLE/Wi-Fi Direct| MC
        MA <-->|gRPC+Protobuf<br/>BLE/Wi-Fi Direct| MC
    end

    subgraph "Mobile App Architecture (Clean)"
        PRES[Presentation<br/>Riverpod Notifiers + Screens]
        DOM[Domain<br/>UseCases + Repository Interfaces]
        DATA[Data Layer<br/>Local SQLite + Remote Dio]
        CORE[Core<br/>Mesh + Crypto + CRDT]
        PRES --> DOM --> DATA
        DOM --> CORE
    end

    subgraph "Backend (Sync Server)"
        API[AdonisJS 6 API<br/>localhost:3333]
        subgraph "14 Modules"
            AUTH[auth / web_auth]
            USERS[users]
            LOC[locations]
            NET[network + VRP]
            VEH[vehicles]
            SUP[supply]
            MIS[missions]
            DEL[delivery + PoD]
            SYNC[sync + CRDT]
            MESH[mesh]
            SEN[sensors + ML]
            TRI[triage]
            HND[handoff]
            DASH[dashboard + SSE]
        end
        API --> AUTH & USERS & LOC & NET & VEH & SUP & MIS & DEL & SYNC & MESH & SEN & TRI & HND & DASH
        DB[(MySQL 8<br/>20 Tables)]
        API <--> DB
    end

    subgraph "Web Dashboard"
        WEB[Next.js 16<br/>React 19 + Ant Design]
        WEB -->|REST/JSON| API
    end

    subgraph "Infrastructure"
        CHAOS[Chaos Server<br/>Python Flask<br/>localhost:5000]
        CHAOS -->|flood events| NET
    end

    MA & MB & MC <-->|delta-sync<br/>REST/JSON| SYNC
    WEB -.->|admin only| USERS
```

---

## 3. Data Flow — Offline vs Online Modes

### Mode A: Fully Offline (80% of operation time)

```mermaid
sequenceDiagram
    participant FieldAgent as Field Agent (Mobile A)
    participant Relay as Relay Node (Mobile B)
    participant Target as Target Device (Mobile C)

    Note over FieldAgent,Target: No internet — BLE/Wi-Fi Direct mesh only

    FieldAgent->>FieldAgent: Encrypt payload (AES-256-GCM, C's pubkey)
    FieldAgent->>FieldAgent: Sign with Ed25519 private key
    FieldAgent->>Relay: gRPC MeshMessage (Protobuf)
    Note over Relay: Relay stores message (TTL=24h)
    Note over Target: Target offline — relay queues message

    Target-->>Relay: Target comes online (BLE ping)
    Relay->>Target: gRPC MeshMessage delivery
    Target->>Target: Verify signature + Decrypt
    Target->>Target: Apply CRDT operation to local SQLite
    Target->>FieldAgent: gRPC DeliveryAck (via relay if needed)
```

### Mode B: Online Sync (when internet available)

```mermaid
sequenceDiagram
    participant Mobile as Mobile App
    participant Server as Sync Server (AdonisJS)
    participant DB as MySQL

    Mobile->>Server: POST /api/sync/push (CRDT operations + vector clock)
    Server->>DB: Upsert crdt_operations (check vector clocks)
    Server->>Server: Detect conflicts (same entity, concurrent clocks)
    Server-->>Mobile: Response with conflicts[] + server_vector_clock

    Mobile->>Server: POST /api/sync/pull (last_vector_clock)
    Server->>DB: SELECT where vector_clock > last_sync
    Server-->>Mobile: Delta records (< 10 KB typical)
    Mobile->>Mobile: Merge into local SQLite (LWW / G-Counter)
```

---

## 4. Module Interaction Map

```mermaid
graph LR
    M1[M1 Auth & Identity<br/>JWT + OTP + Keys] -->|public keys| M3
    M1 -->|audit trail| M2
    M2[M2 CRDT Sync<br/>Vector Clocks] -->|receipt chain| M5
    M2 -->|conflict state| Dashboard
    M3[M3 Mesh Network<br/>Store & Forward] -->|encrypted relay| M2
    M4[M4 VRP Routing<br/>Dijkstra + Multi-Modal] -->|route conditions| M6
    M4 -->|edge weights| M7
    M5[M5 PoD<br/>QR Handshake] -->|receipt→CRDT| M2
    M5 -->|handoff receipt| M8
    M6[M6 Triage<br/>SLA + Preemption] -->|reroute trigger| M4
    M7[M7 ML Decay<br/>ONNX Classifier] -->|risk scores| M4
    M7 -->|breach prediction| M6
    M8[M8 Drone Handoff<br/>Rendezvous + Battery] -->|PoD protocol| M5
    M8 -->|reachability| M4
```

---

## 5. Database Schema Overview

```mermaid
erDiagram
    users ||--o{ user_keys : "has"
    users ||--o{ otp_secrets : "has"
    users ||--o{ auth_logs : "generates"

    locations ||--o{ routes : "connects"
    locations ||--o{ inventory : "holds"
    locations ||--o{ missions : "originates"
    locations ||--o{ missions : "destination"

    missions ||--o{ mission_cargo : "contains"
    missions ||--o{ mission_route_legs : "has"
    missions ||--o{ delivery_receipts : "fulfilled by"
    missions ||--o{ triage_decisions : "subject of"

    delivery_receipts ||--o{ used_nonces : "consumes"

    sync_nodes ||--o{ crdt_operations : "produces"
    crdt_operations ||--o{ sync_conflicts : "may cause"

    mesh_messages ||--o{ mesh_relay_logs : "tracked by"

    routes ||--o{ sensor_readings : "measured by"
    routes ||--o{ route_ml_predictions : "predicted for"
    routes ||--o{ route_condition_logs : "history"

    vehicles ||--o{ handoff_events : "participates"
    vehicles ||--o{ mission_route_legs : "assigned to"
```

---

## 6. Security Architecture

```mermaid
graph TB
    subgraph "Cryptographic Stack (C5 Compliant)"
        KP[Key Provisioning<br/>Ed25519 or RSA-2048<br/>On first login]
        OTP[Offline OTP<br/>TOTP/HOTP — RFC 6238/4226<br/>Works without internet]
        ENC[Payload Encryption<br/>AES-256-GCM<br/>Recipient pubkey]
        SIG[Message Signing<br/>Ed25519<br/>Sender privkey]
        HASH[Hash Chaining<br/>SHA-256<br/>Audit log tamper detection]
        TLS[Transport<br/>TLS 1.3<br/>All server connections]
    end

    subgraph "Zero-Trust PoD"
        QR[QR Challenge Generation<br/>delivery_id + sender_pubkey<br/>+ payload_hash + nonce + timestamp]
        CS[Counter-Signature<br/>Recipient signs challenge<br/>Mutual verification]
        NP[Nonce Protection<br/>Single-use UUIDs<br/>used_nonces table]
        RC[Receipt Chain<br/>CRDT-linked<br/>Reconstructable offline]
    end

    KP --> ENC
    KP --> SIG
    KP --> QR
    OTP --> AUTH_FLOW[Auth Flow<br/>JWT + OTP 2FA]
    ENC --> MESH[Mesh Messages<br/>E2E encrypted<br/>Relays cannot read]
    SIG --> QR
    QR --> CS --> NP --> RC
    HASH --> AUDIT[Immutable Audit Log<br/>auth_logs table<br/>Hash-chained rows]
```

---

## 7. CAP Theorem Trade-Off

Digital Delta operates as a distributed system across disconnected mobile devices. We explicitly chose:

### Decision: **AP (Availability + Partition Tolerance)**

> We sacrifice **Consistency** in favor of **Availability** and **Partition Tolerance**.

**Justification:**

In a disaster response scenario:

- **Network partitions are the norm**, not the exception — cellular infrastructure is collapsed
- **Availability is life-critical** — a field volunteer who cannot record a supply handoff because the system is "waiting for consensus" creates direct harm
- **Eventual consistency is acceptable** — supply inventory discrepancies are tolerable and resolvable; a 10-minute conflict window does not endanger lives

**How we achieve this with CRDT:**

| Challenge                                 | Solution                                                                             |
| ----------------------------------------- | ------------------------------------------------------------------------------------ |
| Concurrent writes on disconnected devices | LWW-Register (Last-Write-Wins) with vector clock timestamps                          |
| Conflicting inventory counts              | G-Counter CRDT for additive fields (only increments; never lose counts)              |
| Causal ordering                           | Lamport vector clocks on every `crdt_operation` record                               |
| Conflict detection                        | Server detects same `entity_id` + concurrent vector clocks on reconnect              |
| Resolution                                | UI surfaces both values; camp commander resolves; decision logged                    |
| Convergence guarantee                     | All nodes reach identical state after sync; mathematically proven by CRDT properties |

**CAP boundary:**

- During partition: **Available** (all CRUD works locally, mesh relays messages)
- On reconnect: **Eventually Consistent** (delta-sync merges diverged state)
- Never provides **Strong Consistency** — acceptable for this domain

---

## 8. Offline vs Online Feature Matrix

| Feature           | Fully Offline         | Mesh-Only          | Online Sync  |
| ----------------- | --------------------- | ------------------ | ------------ |
| Login (OTP)       | ✅ TOTP works offline | ✅                 | ✅           |
| Create mission    | ✅ SQLite             | ✅ via mesh relay  | ✅           |
| VRP routing       | ✅ cached graph       | ✅                 | ✅           |
| PoD handshake     | ✅ Ed25519 local      | ✅                 | ✅           |
| CRDT sync         | ✅ local merge        | ✅ delta over mesh | ✅ full sync |
| ML prediction     | ✅ ONNX on-device     | ✅                 | ✅           |
| Triage preemption | ✅ local engine       | ✅                 | ✅           |
| Drone rendezvous  | ✅ geometric compute  | ✅                 | ✅           |
| Dashboard charts  | ❌ requires browser   | ❌                 | ✅           |
| Audit log view    | ✅ local log          | limited            | ✅ full      |

---

## 9. Technology Stack Summary

| Layer               | Technology                  | Version         | Notes                    |
| ------------------- | --------------------------- | --------------- | ------------------------ |
| Mobile Client       | Flutter                     | 3.11.1          | iOS + Android            |
| State Management    | Riverpod                    | 2.6.1           | Provider + AsyncNotifier |
| Mobile DB           | SQLite                      | 3 (via sqflite) | CRDT layer on top        |
| Backend Framework   | AdonisJS                    | 6.18            | TypeScript, MVC          |
| Backend DB          | MySQL                       | 8.x             | 20 tables, 9 migrations  |
| ORM                 | Lucid (AdonisJS)            | 21.6            |                          |
| Web Framework       | Next.js                     | 16.2.3          | App Router               |
| UI Library          | Ant Design                  | 6.3.5           |                          |
| Inter-node Protocol | gRPC + Protobuf             | proto3          | C1 mandatory             |
| BLE Mesh            | flutter_reactive_ble        | 5.x             | + Bridgefy               |
| Crypto (mobile)     | pointycastle + cryptography | 3.9.1 / 2.8     |                          |
| ML Runtime          | ONNX Runtime (mobile)       | —               | On-device inference      |
| Route Visualization | Leaflet.js + OSM            | —               | Pre-cached tiles         |
| Monorepo            | Turborepo + pnpm            | 2.6.1 / 9       |                          |

---

## 10. Deployment Architecture (Local / Demo)

```
localhost:3333  →  AdonisJS API (REST/JSON, for dashboard)
localhost:3000  →  Next.js Dashboard
localhost:5000  →  Chaos Server (Python Flask)

Mobile App     →  Flutter (physical device or emulator)
Mesh Network   →  BLE + Wi-Fi Direct (device-to-device)
```

All components run **locally with no cloud dependency**. The system is designed for:

- 2 physical Android devices for BLE mesh demo
- 1 laptop running all server processes
- MySQL running locally (no Docker required for demo, optional)
