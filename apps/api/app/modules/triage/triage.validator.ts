import vine from '@vinejs/vine';

import type { Infer } from '@vinejs/vine/types';

export const evaluateTriageValidator = vine.compile(
  vine.object({
    triggered_by: vine.enum([
      'sla_breach_predicted',
      'sla_breached',
      'route_failure',
      'priority_preemption',
      'ml_high_risk',
      'manual_override',
    ] as const),
    rationale: vine.string(),
    preempted_mission_id: vine.number().min(0).optional(),
    old_route: vine.array(vine.number()).optional(),
    new_route: vine.array(vine.number()).optional(),
  })
);
export type EvaluateTriageType = Infer<typeof evaluateTriageValidator>;
