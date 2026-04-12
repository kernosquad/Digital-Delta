import { BaseModel, column, hasMany } from '@adonisjs/lucid/orm';

import type { HasMany } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import Inventory from '#models/inventory';
import Route from '#models/route';
import SensorReading from '#models/sensor_reading';
import Vehicle from '#models/vehicle';

export type LocationType =
  | 'central_command'
  | 'supply_drop'
  | 'relief_camp'
  | 'waypoint'
  | 'hospital'
  | 'drone_base';

export default class Location extends BaseModel {
  static table = 'locations';

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare nodeCode: string;

  @column()
  declare name: string;

  @column()
  declare type: LocationType;

  @column()
  declare latitude: number;

  @column()
  declare longitude: number;

  @column()
  declare isActive: boolean;

  @column()
  declare isFlooded: boolean;

  @column()
  declare capacity: number | null;

  @column()
  declare currentOccupancy: number;

  @column()
  declare notes: string | null;

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime;

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  declare updatedAt: DateTime | null;

  // ── Relations ──────────────────────────────────────────────────────────
  @hasMany(() => Route, { foreignKey: 'sourceLocationId' })
  declare outboundRoutes: HasMany<typeof Route>;

  @hasMany(() => Route, { foreignKey: 'targetLocationId' })
  declare inboundRoutes: HasMany<typeof Route>;

  @hasMany(() => Vehicle, { foreignKey: 'currentLocationId' })
  declare vehicles: HasMany<typeof Vehicle>;

  @hasMany(() => Inventory, { foreignKey: 'locationId' })
  declare inventory: HasMany<typeof Inventory>;

  @hasMany(() => SensorReading, { foreignKey: 'locationId' })
  declare sensorReadings: HasMany<typeof SensorReading>;
}
