import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import Location from '#models/location';
import Mission from '#models/mission';
import Route from '#models/route';

export type LegStatus = 'pending' | 'active' | 'completed' | 'skipped';

export default class MissionRouteLeg extends BaseModel {
  static table = 'mission_route_legs';

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare missionId: number;

  @column()
  declare seqOrder: number;

  @column()
  declare fromLocationId: number;

  @column()
  declare toLocationId: number;

  @column()
  declare routeId: number;

  @column()
  declare estimatedMins: number;

  @column()
  declare status: LegStatus;

  @column.dateTime()
  declare createdAt: DateTime;

  @column.dateTime()
  declare updatedAt: DateTime | null;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Mission)
  declare mission: BelongsTo<typeof Mission>;

  @belongsTo(() => Location, { foreignKey: 'fromLocationId' })
  declare fromLocation: BelongsTo<typeof Location>;

  @belongsTo(() => Location, { foreignKey: 'toLocationId' })
  declare toLocation: BelongsTo<typeof Location>;

  @belongsTo(() => Route)
  declare route: BelongsTo<typeof Route>;
}
