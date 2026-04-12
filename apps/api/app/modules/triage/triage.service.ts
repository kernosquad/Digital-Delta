import db from '@adonisjs/lucid/services/db'

import type { EvaluateTriageType } from './triage.validator.js'
import type { HttpContext } from '@adonisjs/core/http'

import { EventBus } from '#services/event_bus'

const SLA_HOURS: Record<string, number> = {
  p0_critical: 2,
  p1_high: 6,
  p2_standard: 24,
  p3_low: 72,
}

// Priority taxonomy for M6.1
export const PRIORITY_TAXONOMY = [
  {
    class: 'p0_critical',
    label: 'P0 Critical',
    sla_hours: 2,
    color: 'red',
    example: 'Antivenom, blood, oxygen',
  },
  {
    class: 'p1_high',
    label: 'P1 High',
    sla_hours: 6,
    color: 'orange',
    example: 'Surgical kits, IV fluids',
  },
  {
    class: 'p2_standard',
    label: 'P2 Standard',
    sla_hours: 24,
    color: 'yellow',
    example: 'Food, blankets, medicine',
  },
  {
    class: 'p3_low',
    label: 'P3 Low',
    sla_hours: 72,
    color: 'green',
    example: 'Non-urgent supplies',
  },
]

export class TriageService {
  async decisions(ctx: HttpContext) {
    const { response } = ctx

    const data = await db
      .from('triage_decisions as td')
      .join('missions as m', 'm.id', 'td.mission_id')
      .select('td.*', 'm.mission_code')
      .orderBy('td.created_at', 'desc')

    return response.sendFormatted(data)
  }

  async slaStatus(ctx: HttpContext) {
    const { params, response } = ctx

    const mission = await db
      .from('missions')
      .where('id', params.id)
      .select('id', 'status', 'priority_class', 'sla_deadline', 'sla_breached')
      .first()

    if (!mission) {
      return response.status(404).sendError('Mission not found')
    }

    const now = new Date()
    const deadline = new Date(mission.sla_deadline)
    const slaHours = SLA_HOURS[mission.priority_class] ?? 24
    const totalSlaMs = slaHours * 60 * 60 * 1000

    const msRemaining = deadline.getTime() - now.getTime()
    const minsRemaining = Math.round(msRemaining / 60_000)
    const pctRemaining = msRemaining / totalSlaMs

    const isCompleted = mission.status === 'completed'
    const isBreached = !isCompleted && deadline < now

    let urgencyLevel: 'ok' | 'warning' | 'critical' | 'breached'
    if (isBreached || mission.sla_breached) {
      urgencyLevel = 'breached'
    } else if (pctRemaining < 0.05) {
      urgencyLevel = 'critical'
    } else if (pctRemaining < 0.2) {
      urgencyLevel = 'warning'
    } else {
      urgencyLevel = 'ok'
    }

    return response.sendFormatted({
      mission_id: mission.id,
      priority_class: mission.priority_class,
      sla_deadline: mission.sla_deadline,
      status: mission.status,
      is_breached: isBreached,
      time_remaining_mins: minsRemaining,
      urgency_level: urgencyLevel,
    })
  }

  // M6.1 — Priority taxonomy reference
  async taxonomy(ctx: HttpContext) {
    return ctx.response.sendFormatted(PRIORITY_TAXONOMY)
  }

  // M6.2 — Predict SLA breach when routes slow by delay_factor (e.g. 1.3 = 30% slower)
  async predictSlaBreach(ctx: HttpContext) {
    const { request, response } = ctx
    const delayFactor = Math.max(1.0, Number.parseFloat(request.input('delay_factor', '1.3')))

    const missions = await db
      .from('missions')
      .whereIn('status', ['pending', 'in_progress'])
      .select(
        'id',
        'mission_code',
        'priority_class',
        'sla_deadline',
        'status',
        'estimated_duration_mins'
      )

    const now = new Date()
    const predictions = missions.map((m) => {
      const deadline = new Date(m.sla_deadline)
      const slaHours = SLA_HOURS[m.priority_class] ?? 24
      const totalSlaMs = slaHours * 3_600_000
      const msRemaining = deadline.getTime() - now.getTime()
      const minsRemaining = Math.round(msRemaining / 60_000)

      // Apply delay factor to base estimated duration
      const baseEta = m.estimated_duration_mins ?? Math.round(slaHours * 20)
      const predictedEta = Math.round(baseEta * delayFactor)
      const willBreach = predictedEta > minsRemaining
      const pctRemaining = totalSlaMs > 0 ? msRemaining / totalSlaMs : 0

      return {
        mission_id: m.id,
        mission_code: m.mission_code,
        priority_class: m.priority_class,
        sla_deadline: m.sla_deadline,
        status: m.status,
        delay_factor_applied: delayFactor,
        base_eta_mins: baseEta,
        predicted_eta_mins: predictedEta,
        sla_mins_remaining: minsRemaining,
        will_breach_sla: willBreach,
        urgency: willBreach
          ? ['p0_critical', 'p1_high'].includes(m.priority_class)
            ? 'critical'
            : 'warning'
          : pctRemaining < 0.2
            ? 'warning'
            : 'ok',
      }
    })

    const atRisk = predictions.filter((p) => p.will_breach_sla)
    if (atRisk.length > 0) {
      EventBus.publish('sla_alert', { count: atRisk.length, delay_factor: delayFactor })
    }

    return response.sendFormatted({
      delay_factor: delayFactor,
      total_missions: predictions.length,
      at_risk: atRisk.length,
      predictions,
    })
  }

  // M6.3 — Autonomous drop-and-reroute decision
  async autoPreempt(ctx: HttpContext) {
    const { params, response } = ctx
    const missionId = Number(params.id)

    const mission = await db.from('missions').where('id', missionId).first()
    if (!mission) return response.status(404).sendError('Mission not found')

    const isCritical = ['p0_critical', 'p1_high'].includes(mission.priority_class)

    // Get cargo items for this mission
    const cargo = await db
      .from('mission_cargos as mc')
      .leftJoin('supply_items as si', 'si.id', 'mc.supply_item_id')
      .where('mc.mission_id', missionId)
      .select('mc.id', 'mc.quantity', 'si.name as item_name', 'si.category')

    const keepCargo = isCritical ? cargo : []
    const dropCargo = isCritical ? [] : cargo

    // Find nearest safe waypoint for drop-off
    const waypoint = await db
      .from('locations')
      .where('type', 'waypoint')
      .where('is_flooded', false)
      .orderBy('id')
      .first()

    const action = isCritical ? 'keep_priority' : 'drop_and_reroute'
    const rationale = isCritical
      ? `Mission ${mission.mission_code} is ${mission.priority_class} — retains full priority routing. No cargo drop required.`
      : `[AUTO] Mission ${mission.mission_code} (${mission.priority_class}) preempted by higher-priority cargo. ${cargo.length} item(s) deposited at ${waypoint?.name ?? 'safe waypoint'} (ID: ${waypoint?.id ?? 'N/A'}). Driver reroutes to P0/P1 delivery.`

    const [decisionId] = await db.table('triage_decisions').insert({
      mission_id: missionId,
      triggered_by: 'priority_preemption',
      rationale,
      preempted_mission_id: null,
      old_route: null,
      new_route: waypoint && !isCritical ? JSON.stringify([waypoint.id]) : null,
      created_at: new Date(),
    })

    EventBus.publish('triage_decision', { missionId, triggeredBy: 'priority_preemption', action })

    return response.status(201).sendFormatted({
      decision_id: decisionId,
      mission_id: missionId,
      mission_code: mission.mission_code,
      priority_class: mission.priority_class,
      action,
      keep_cargo: keepCargo,
      drop_cargo: dropCargo,
      drop_waypoint: !isCritical ? waypoint : null,
      rationale,
      logged_at: new Date().toISOString(),
    })
  }

  async evaluate(ctx: HttpContext, payload: EvaluateTriageType) {
    const { params, response } = ctx

    const missionId = Number(params.id)

    const [decisionId] = await db.table('triage_decisions').insert({
      mission_id: missionId,
      triggered_by: payload.triggered_by,
      rationale: payload.rationale,
      preempted_mission_id: payload.preempted_mission_id ?? null,
      old_route: payload.old_route ? JSON.stringify(payload.old_route) : null,
      new_route: payload.new_route ? JSON.stringify(payload.new_route) : null,
      created_at: new Date(),
    })

    EventBus.publish('triage_decision', {
      missionId,
      triggeredBy: payload.triggered_by,
    })

    const decision = await db.from('triage_decisions').where('id', decisionId).first()

    return response.status(201).sendFormatted(decision)
  }
}
