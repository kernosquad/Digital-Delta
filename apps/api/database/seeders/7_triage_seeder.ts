import { BaseSeeder } from '@adonisjs/lucid/seeders'
import { DateTime } from 'luxon'

import Mission from '#models/mission'
import Route from '#models/route'
import TriageDecision from '#models/triage_decision'

/**
 * Seed autonomous triage decisions (Module 6).
 *
 * M6.2 — SLA breach prediction: decisions triggered by breach forecasts
 * M6.3 — Autonomous drop-and-reroute: preemption and reroute decisions logged
 *
 * Each decision captures:
 *   - triggeredBy: reason the triage engine fired
 *   - oldRoute / newRoute: route leg IDs before and after rerouting
 *   - rationale: human-readable audit trail
 *   - preemptedMissionId: mission dropped to free a vehicle (preemption only)
 */
export default class TriageSeeder extends BaseSeeder {
  async run() {
    const now = DateTime.now()

    const missions = await Mission.all()
    const routes = await Route.all()

    const missionMap = new Map(missions.map((m) => [m.missionCode, m]))
    const routeMap = new Map(routes.map((r) => [r.edgeCode, r]))

    const m1 = missionMap.get('MSN-2026-0001')!
    const m2 = missionMap.get('MSN-2026-0002')!
    const m3 = missionMap.get('MSN-2026-0003')!
    const m4 = missionMap.get('MSN-2026-0004')!
    const m8 = missionMap.get('MSN-2026-0008')!

    const e3 = routeMap.get('E3')
    const e4 = routeMap.get('E4')
    const e5 = routeMap.get('E5')

    await TriageDecision.createMany([
      // ── M6.2: SLA breach predicted — MSN-0001 (P0, 22 min ETA, 8% breach prob) ──
      {
        missionId: m1.id,
        triggeredBy: 'sla_breach_predicted',
        oldRoute: null,
        newRoute: null,
        rationale: 'ETA within P0 SLA (2h). No intervention required.',
        preemptedMissionId: null,
        createdAt: now.minus({ minutes: 28 }),
      },

      // ── M6.2: ML flagged E3 river route as critical — MSN-0003 ───────────────
      {
        missionId: m3.id,
        triggeredBy: 'ml_high_risk',
        oldRoute: e3 ? [e3.id] : null,
        newRoute: null,
        rationale:
          'River route E3 flagged critical (82% impassability). Monitor water-level delta at N4. No reroute actioned — mission continues under elevated risk.',
        preemptedMissionId: null,
        createdAt: now.minus({ minutes: 45 }),
      },

      // ── M6.2: SLA breached — MSN-0004 rerouted via E5 airway ─────────────────
      {
        missionId: m4.id,
        triggeredBy: 'sla_breached',
        oldRoute: e4 ? [e4.id] : null,
        newRoute: e5 ? [e5.id] : null,
        rationale:
          'SLA already breached. Road E4 partial flood added 90 min delay. Rerouting via E5 airway to minimise further SLA violation.',
        preemptedMissionId: null,
        createdAt: now.minus({ minutes: 60 }),
      },

      // ── M6.3: Priority preemption — MSN-0002 triggered drop of MSN-0008 ──────
      {
        missionId: m2.id,
        triggeredBy: 'priority_preemption',
        oldRoute: null,
        newRoute: null,
        rationale:
          'P2 cargo (MSN-0008) preempted. Drone D2 redirected to critical P0 blood delivery (MSN-0002). P2 cargo safe-stored at N2.',
        preemptedMissionId: m8.id,
        createdAt: now.minus({ hours: 3 }),
      },
    ])
  }
}
