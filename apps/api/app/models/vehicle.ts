import { BaseModel, belongsTo, column, hasMany } from '@adonisjs/lucid/orm';

import type { BelongsTo, HasMany } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import Location from '#models/location';
import Mission from '#models/mission';
import User from '#models/user';

export type VehicleType = 'truck' | 'speedboat' | 'drone';
export type VehicleStatus = 'idle' | 'in_mission' | 'maintenance' | 'offline';

export default class Vehicle extends BaseModel {
  static table = 'vehicles';

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare name: string;

  @column()
  declare type: VehicleType;

  @column()
  declare identifier: string;

  @column()
  declare maxPayloadKg: number;

  @column()
  declare batteryLevel: number | null;

  @column()
  declare fuelLevel: number | null;

  @column()
  declare status: VehicleStatus;

  @column()
  declare currentLocationId: number | null;

  @column()
  declare operatorId: number | null;

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime;

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  declare updatedAt: DateTime | null;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Location, { foreignKey: 'currentLocationId' })
  declare currentLocation: BelongsTo<typeof Location>;

  @belongsTo(() => User, { foreignKey: 'operatorId' })
  declare operator: BelongsTo<typeof User>;

  @hasMany(() => Mission, { foreignKey: 'vehicleId' })
  declare missions: HasMany<typeof Mission>;
}
