/*
|--------------------------------------------------------------------------
| Routes — Digital Delta API
|--------------------------------------------------------------------------
|
| Each module owns its own route file: app/modules/{name}/{name}.route.ts
| Routes are registered as side-effect imports — all prefix, JWT, and RBAC
| middleware is declared inside the module's route file, not here.
|
| Modules and their prefixes:
|   auth        /api/auth          — login, register (public) + me, OTP, keys (JWT)
|   users       /api/users         — user management (sync_admin only)
|   locations   /api/locations     — camp/hub/waypoint nodes
|   network     /api/network       — route graph edges + VRP compute
|   vehicles    /api/vehicles      — fleet management
|   supply      /api/supply        — supply catalog + inventory
|   missions    /api/missions      — mission lifecycle + preemption
|   delivery    /api/delivery      — proof-of-delivery + nonce replay protection
|   sync        /api/sync          — delta sync (mobile to server)
|   mesh        /api/mesh          — store-and-forward encrypted mesh messages
|   sensors     /api/sensors       — environmental sensor readings + ML predictions
|   triage      /api/triage        — SLA management + autonomous triage decisions
|   handoff     /api/handoff       — drone to ground vehicle handoff events
|   dashboard   /api/dashboard     — stats aggregation + SSE real-time stream
|
*/

import router from '@adonisjs/core/services/router'

// ── Module routes (each file self-registers with prefix + middleware) ──────
import '#modules/auth/auth.route'
import '#modules/web_auth/web_auth.route'
import '#modules/users/users.route'
import '#modules/locations/locations.route'
import '#modules/network/network.route'
import '#modules/vehicles/vehicles.route'
import '#modules/supply/supply.route'
import '#modules/missions/missions.route'
import '#modules/delivery/delivery.route'
import '#modules/sync/sync.route'
import '#modules/mesh/mesh.route'
import '#modules/sensors/sensors.route'
import '#modules/triage/triage.route'
import '#modules/handoff/handoff.route'
import '#modules/dashboard/dashboard.route'

router.get('/', async ({ response }) => {
  return response.ok({ Digital: 'Delta' })
})
// ── Health check (public, no auth) ────────────────────────────────────────
router.get('/health', async ({ response }) => {
  return response.ok({ status: 'ok', timestamp: new Date().toISOString() })
})
