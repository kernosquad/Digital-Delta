import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import Route from '#models/route';
import User from '#models/user';

export type ConditionReason =
  | 'flood'
  | 'recede'
  | 'ml_prediction'
  | 'manual_override'
  | 'chaos_engine';

export default class RouteConditionLog extends BaseModel {
  static table = 'route_condition_logs';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare routeId: number;

  @column()
  declare changedByUserId: number | null;

  @column()
  declare oldTravelMins: number;

  @column()
  declare newTravelMins: number;

  @column()
  declare oldRiskScore: number;

  @column()
  declare newRiskScore: number;

  @column()
  declare isFlooded: boolean;

  @column()
  declare reason: ConditionReason;

  @column.dateTime()
  declare createdAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Route)
  declare route: BelongsTo<typeof Route>;

  @belongsTo(() => User, { foreignKey: 'changedByUserId' })
  declare changedBy: BelongsTo<typeof User>;
}
