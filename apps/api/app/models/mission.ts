import { BaseModel, belongsTo, column, hasMany } from '@adonisjs/lucid/orm';

import type { BelongsTo, HasMany } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import Location from '#models/location';
import MissionCargo from '#models/mission_cargo';
import MissionRouteLeg from '#models/mission_route_leg';
import User from '#models/user';
import Vehicle from '#models/vehicle';

export type MissionStatus =
  | 'planned'
  | 'active'
  | 'paused'
  | 'completed'
  | 'failed'
  | 'preempted'
  | 'cancelled';

export type PriorityClass = 'p0_critical' | 'p1_high' | 'p2_standard' | 'p3_low';

export default class Mission extends BaseModel {
  static table = 'missions';

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare missionCode: string;

  @column()
  declare status: MissionStatus;

  @column()
  declare priorityClass: PriorityClass;

  @column()
  declare originLocationId: number;

  @column()
  declare destinationLocationId: number;

  @column()
  declare vehicleId: number;

  @column()
  declare driverId: number | null;

  @column()
  declare createdById: number | null;

  @column()
  declare totalPayloadKg: number;

  @column.dateTime()
  declare slaDeadline: DateTime;

  @column()
  declare slaBreached: boolean;

  @column.dateTime()
  declare estimatedArrival: DateTime | null;

  @column.dateTime()
  declare actualArrival: DateTime | null;

  @column()
  declare preemptionReason: string | null;

  @column()
  declare preemptedByMissionId: number | null;

  @column()
  declare notes: string | null;

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime;

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  declare updatedAt: DateTime | null;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Location, { foreignKey: 'originLocationId' })
  declare originLocation: BelongsTo<typeof Location>;

  @belongsTo(() => Location, { foreignKey: 'destinationLocationId' })
  declare destinationLocation: BelongsTo<typeof Location>;

  @belongsTo(() => Vehicle)
  declare vehicle: BelongsTo<typeof Vehicle>;

  @belongsTo(() => User, { foreignKey: 'driverId' })
  declare driver: BelongsTo<typeof User>;

  @belongsTo(() => User, { foreignKey: 'createdById' })
  declare createdBy: BelongsTo<typeof User>;

  @belongsTo(() => Mission, { foreignKey: 'preemptedByMissionId' })
  declare preemptedByMission: BelongsTo<typeof Mission>;

  @hasMany(() => MissionCargo)
  declare cargo: HasMany<typeof MissionCargo>;

  @hasMany(() => MissionRouteLeg)
  declare routeLegs: HasMany<typeof MissionRouteLeg>;
}
