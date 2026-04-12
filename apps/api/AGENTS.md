# Digital Delta — API Agent Guide

AdonisJS 6 backend for a disaster-response logistics system (HackFusion 2026 — Track B, 70 pts engineering).
Flood response in Bangladesh (Sylhet/Sunamganj/Netrokona). Offline-first, mesh-networked, multi-modal routing.

---

## Tech Stack

| Layer           | Choice                                                                                          |
| --------------- | ----------------------------------------------------------------------------------------------- |
| Framework       | AdonisJS 6 (Node.js ESM)                                                                        |
| ORM             | Lucid (MySQL via `mysql2`)                                                                      |
| Validation      | VineJS (`@vinejs/vine`)                                                                         |
| Auth            | JWT guard (`@adonisjs/auth`) — reads from `Authorization` header OR `jwt_token` httpOnly cookie |
| Real-time       | Server-Sent Events via Node.js `EventEmitter` singleton (`app/services/event_bus.ts`)           |
| Package manager | pnpm (workspace)                                                                                |

---

## Project Structure

```
apps/api/
├── app/
│   ├── modules/          ← ALL business logic lives here (modular structure)
│   │   ├── auth/
│   │   ├── users/
│   │   ├── locations/
│   │   ├── network/
│   │   ├── vehicles/
│   │   ├── supply/
│   │   ├── missions/
│   │   ├── delivery/
│   │   ├── sync/
│   │   ├── mesh/
│   │   ├── sensors/
│   │   ├── triage/
│   │   ├── handoff/
│   │   └── dashboard/
│   ├── middleware/        ← auth_middleware, role_middleware, guest_middleware
│   ├── models/            ← user.ts (Lucid model)
│   └── services/
│       └── event_bus.ts   ← EventBus singleton (EventEmitter)
├── database/migrations/   ← 9 migration files, 20 tables
├── start/
│   ├── routes.ts          ← side-effect imports of all module route files
│   └── kernel.ts          ← named middleware: auth, role, guest
└── package.json           ← Node imports: #modules/*, #models/*, #services/*, etc.
```

---

## Module Structure (ALWAYS follow this pattern)

Every feature is a self-contained module with exactly 4 files:

```
app/modules/{name}/
├── {name}.validator.ts   — vine.compile() schemas + Infer<> types
├── {name}.service.ts     — plain class with all business logic
├── {name}.controller.ts  — @inject() + DI, validates then delegates to service
└── {name}.route.ts       — router group with prefix + JWT + role middleware
```

### validator.ts

```typescript
import vine from '@vinejs/vine';
import type { Infer } from '@vinejs/vine/types';

export const createFooValidator = vine.compile(vine.object({ name: vine.string().maxLength(100) }));
export type CreateFooType = Infer<typeof createFooValidator>;
```

### service.ts

```typescript
import db from '@adonisjs/lucid/services/db';
import { EventBus } from '#services/event_bus';
import type { HttpContext } from '@adonisjs/core/http';
import type { CreateFooType } from './foo.validator.js';

export class FooService {
  async index({ response }: HttpContext) {
    return response.ok({ data: await db.from('foos') });
  }
  async store({ response }: HttpContext, payload: CreateFooType) {
    const [id] = await db.table('foos').insert({ ...payload, created_at: new Date() });
    EventBus.publish('mission_update', { fooId: id });
    return response.created({ id });
  }
}
```

### controller.ts

```typescript
import { inject } from '@adonisjs/core';
import { createFooValidator } from './foo.validator.js';
import type { FooService } from './foo.service.js';
import type { HttpContext } from '@adonisjs/core/http';

@inject()
export default class FooController {
  constructor(private fooService: FooService) {}

  async index(ctx: HttpContext) {
    return this.fooService.index(ctx);
  }
  async store(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(createFooValidator);
    return this.fooService.store(ctx, payload);
  }
}
```

### route.ts

```typescript
import router from '@adonisjs/core/services/router';
import { middleware } from '#start/kernel';

const FooController = () => import('./foo.controller.js');

router
  .group(() => {
    router.get('/', [FooController, 'index']); // all roles
    router
      .group(() => {
        router.post('/', [FooController, 'store']); // restricted
      })
      .use(middleware.role(['sync_admin', 'supply_manager']));
  })
  .prefix('/api/foos')
  .use(middleware.auth({ guards: ['jwt'] }));
```

### Adding a new module

1. Run `node ace make:module <name>` to scaffold the 4 files
2. Implement validator → service → controller → route
3. Add `import '#modules/<name>/<name>.route';` to `start/routes.ts`
4. No changes needed to `package.json` — `#modules/*` wildcard already covers it

---

## Key Rules

- **Controller is thin**: only validates input, then calls `this.service.method(ctx, payload)`. No DB calls in controllers.
- **Service receives full ctx**: destructure what you need `({ request, response, auth, params }: HttpContext)`.
- **Validate with `ctx.request.validateUsing(validator)`** — not `validator.validate(request.all())`.
- **GET/no-body methods**: controller calls `return this.service.method(ctx)` directly (no validation step).
- **Within-module imports use `.js` extension**: `from './foo.service.js'`
- **Non-relative imports use `#` aliases**: `from '#models/user'`, `from '#services/event_bus'`, `from '@adonisjs/lucid/services/db'`
- **Route files are self-contained**: each declares its own prefix, JWT auth, and role middleware — `start/routes.ts` is just a list of imports.

---

## Available Middleware (from `#start/kernel`)

```typescript
import { middleware } from '#start/kernel';

middleware.auth({ guards: ['jwt'] }); // JWT required (header OR cookie)
middleware.role(['sync_admin']); // RBAC — user.role must be in array
middleware.guest(); // redirects if already authenticated
```

### RBAC Roles

| Role              | Access                                |
| ----------------- | ------------------------------------- |
| `field_volunteer` | own missions only                     |
| `supply_manager`  | supply, inventory, missions, vehicles |
| `drone_operator`  | handoff events, vehicles              |
| `camp_commander`  | locations, missions, supply           |
| `sync_admin`      | full access + user management         |

---

## Database — Key Tables

| Table                  | Module     | Notes                                                                          |
| ---------------------- | ---------- | ------------------------------------------------------------------------------ |
| `users`                | auth/users | role enum, status enum, soft-delete via deleted_at                             |
| `user_keys`            | auth       | Ed25519/RSA public keys per device                                             |
| `otp_secrets`          | auth       | TOTP/HOTP secrets, encrypted at rest (TODO)                                    |
| `auth_logs`            | auth       | Immutable audit log (login, logout, role change, key provision)                |
| `locations`            | locations  | Network nodes: camp, hub, waypoint, hospital, drone_base                       |
| `routes`               | network    | Directed edges: road/river/airway, current_travel_mins updated by chaos engine |
| `route_condition_logs` | network    | ML training data — every edge status change                                    |
| `vehicles`             | vehicles   | truck/speedboat/drone, operator_id, battery_level                              |
| `supply_items`         | supply     | Catalog with priority_class (p0–p3) and sla_hours                              |
| `inventory`            | supply     | Stock per location, crdt_vector_clock for CRDT merge                           |
| `missions`             | missions   | Full lifecycle, SLA deadline auto-computed from priority_class                 |
| `mission_cargo`        | missions   | Line items per mission                                                         |
| `mission_route_legs`   | missions   | VRP route legs (seq_order)                                                     |
| `delivery_receipts`    | delivery   | SHA-256 hash-chained PoD records                                               |
| `used_nonces`          | delivery   | QR nonce replay protection                                                     |
| `sync_nodes`           | sync       | Registered devices/nodes in the mesh                                           |
| `crdt_operations`      | sync       | All CRDT ops with vector clocks                                                |
| `sync_conflicts`       | sync       | Concurrent ops on same entity+field                                            |
| `mesh_messages`        | mesh       | AES-256-GCM ciphertext (MEDIUMBLOB), TTL, hop_count                            |
| `mesh_relay_logs`      | mesh       | Per-hop relay audit trail                                                      |
| `sensor_readings`      | sensors    | Time-series: rainfall_mm, water_level_cm, wind_speed_kmh, etc.                 |
| `route_ml_predictions` | sensors    | Impassability classifier output, is_active = latest                            |
| `handoff_events`       | handoff    | Drone↔ground rendezvous with GPS coordinates                                   |
| `triage_decisions`     | triage     | Immutable log of autonomous reroute/preemption decisions                       |

---

## EventBus (SSE)

```typescript
import { EventBus } from '#services/event_bus';

// Publish an event (from any service)
EventBus.publish('route_update', { routeId: 7, isFlooded: true });

// Subscribe (dashboard SSE stream only)
EventBus.on('event', (busEvent: BusEvent) => {
  // busEvent = { type: EventType, data: Record<string, unknown>, timestamp: string }
});
EventBus.off('event', handler); // always clean up on connection close
```

**Event types**: `route_update`, `mission_update`, `sla_alert`, `triage_decision`, `vehicle_update`, `conflict_detected`, `sensor_update`

The SSE stream is at `GET /api/dashboard/stream` — implemented in `app/modules/dashboard/dashboard.service.ts`.

---

## Auth Flow

- **JWT generation**: `auth.use('jwt').generate(user)` → returns `{ token }`
- **JWT is set as**: response body (`token`) AND httpOnly cookie `jwt_token`
- **Reading**: `auth_middleware.ts` reads from `Authorization: Bearer <token>` OR `Cookie: jwt_token=<token>` — no client-specific handling needed
- **Current user**: `auth.user!` (guaranteed non-null inside JWT-protected routes)

---

## Module Reference

| Module    | Prefix           | Route file                             |
| --------- | ---------------- | -------------------------------------- |
| auth      | `/api/auth`      | `modules/auth/auth.route.ts`           |
| users     | `/api/users`     | `modules/users/users.route.ts`         |
| locations | `/api/locations` | `modules/locations/locations.route.ts` |
| network   | `/api/network`   | `modules/network/network.route.ts`     |
| vehicles  | `/api/vehicles`  | `modules/vehicles/vehicles.route.ts`   |
| supply    | `/api/supply`    | `modules/supply/supply.route.ts`       |
| missions  | `/api/missions`  | `modules/missions/missions.route.ts`   |
| delivery  | `/api/delivery`  | `modules/delivery/delivery.route.ts`   |
| sync      | `/api/sync`      | `modules/sync/sync.route.ts`           |
| mesh      | `/api/mesh`      | `modules/mesh/mesh.route.ts`           |
| sensors   | `/api/sensors`   | `modules/sensors/sensors.route.ts`     |
| triage    | `/api/triage`    | `modules/triage/triage.route.ts`       |
| handoff   | `/api/handoff`   | `modules/handoff/handoff.route.ts`     |
| dashboard | `/api/dashboard` | `modules/dashboard/dashboard.route.ts` |
