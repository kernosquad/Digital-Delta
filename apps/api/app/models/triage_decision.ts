import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import Mission from '#models/mission';

export type TriageTriggeredBy =
  | 'sla_breach_predicted'
  | 'sla_breached'
  | 'route_failure'
  | 'priority_preemption'
  | 'ml_high_risk'
  | 'manual_override';

export default class TriageDecision extends BaseModel {
  static table = 'triage_decisions';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare missionId: number;

  @column()
  declare triggeredBy: TriageTriggeredBy;

  @column()
  declare oldRoute: number[] | null;

  @column()
  declare newRoute: number[] | null;

  @column()
  declare rationale: string;

  @column()
  declare preemptedMissionId: number | null;

  @column.dateTime()
  declare createdAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Mission)
  declare mission: BelongsTo<typeof Mission>;

  @belongsTo(() => Mission, { foreignKey: 'preemptedMissionId' })
  declare preemptedMission: BelongsTo<typeof Mission>;
}
