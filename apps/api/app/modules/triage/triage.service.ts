import db from '@adonisjs/lucid/services/db';

import type { EvaluateTriageType } from './triage.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

import { EventBus } from '#services/event_bus';

const SLA_HOURS: Record<string, number> = {
  p0_critical: 2,
  p1_high: 6,
  p2_standard: 24,
  p3_low: 72,
};

export class TriageService {
  async decisions(ctx: HttpContext) {
    const { response } = ctx;

    const data = await db
      .from('triage_decisions as td')
      .join('missions as m', 'm.id', 'td.mission_id')
      .select('td.*', 'm.mission_code')
      .orderBy('td.created_at', 'desc');

    return response.ok({ data });
  }

  async slaStatus(ctx: HttpContext) {
    const { params, response } = ctx;

    const mission = await db
      .from('missions')
      .where('id', params.id)
      .select('id', 'status', 'priority_class', 'sla_deadline', 'sla_breached')
      .first();

    if (!mission) {
      return response.notFound({ message: 'Mission not found' });
    }

    const now = new Date();
    const deadline = new Date(mission.sla_deadline);
    const slaHours = SLA_HOURS[mission.priority_class] ?? 24;
    const totalSlaMs = slaHours * 60 * 60 * 1000;

    const msRemaining = deadline.getTime() - now.getTime();
    const minsRemaining = Math.round(msRemaining / 60_000);
    const pctRemaining = msRemaining / totalSlaMs;

    const isCompleted = mission.status === 'completed';
    const isBreached = !isCompleted && deadline < now;

    let urgencyLevel: 'ok' | 'warning' | 'critical' | 'breached';
    if (isBreached || mission.sla_breached) {
      urgencyLevel = 'breached';
    } else if (pctRemaining < 0.05) {
      urgencyLevel = 'critical';
    } else if (pctRemaining < 0.2) {
      urgencyLevel = 'warning';
    } else {
      urgencyLevel = 'ok';
    }

    return response.ok({
      mission_id: mission.id,
      priority_class: mission.priority_class,
      sla_deadline: mission.sla_deadline,
      status: mission.status,
      is_breached: isBreached,
      time_remaining_mins: minsRemaining,
      urgency_level: urgencyLevel,
    });
  }

  async evaluate(ctx: HttpContext, payload: EvaluateTriageType) {
    const { params, response } = ctx;

    const missionId = Number(params.id);

    const [decisionId] = await db.table('triage_decisions').insert({
      mission_id: missionId,
      triggered_by: payload.triggered_by,
      rationale: payload.rationale,
      preempted_mission_id: payload.preempted_mission_id ?? null,
      old_route: payload.old_route ? JSON.stringify(payload.old_route) : null,
      new_route: payload.new_route ? JSON.stringify(payload.new_route) : null,
      created_at: new Date(),
    });

    EventBus.publish('triage_decision', {
      missionId,
      triggeredBy: payload.triggered_by,
    });

    const decision = await db.from('triage_decisions').where('id', decisionId).first();

    return response.created(decision);
  }
}
