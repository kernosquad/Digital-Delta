import { BaseModel, column, hasMany } from '@adonisjs/lucid/orm';

import type { HasMany } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import Inventory from '#models/inventory';
import MissionCargo from '#models/mission_cargo';

export type SupplyCategory = 'medical' | 'food' | 'water' | 'shelter' | 'equipment' | 'other';
export type PriorityClass = 'p0_critical' | 'p1_high' | 'p2_standard' | 'p3_low';

export default class SupplyItem extends BaseModel {
  static table = 'supply_items';

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare name: string;

  @column()
  declare category: SupplyCategory;

  @column()
  declare unit: string;

  @column()
  declare weightPerUnitKg: number;

  @column()
  declare priorityClass: PriorityClass;

  @column()
  declare slaHours: number;

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime;

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  declare updatedAt: DateTime | null;

  // ── Relations ──────────────────────────────────────────────────────────
  @hasMany(() => Inventory, { foreignKey: 'supplyItemId' })
  declare inventory: HasMany<typeof Inventory>;

  @hasMany(() => MissionCargo, { foreignKey: 'supplyItemId' })
  declare missionCargo: HasMany<typeof MissionCargo>;
}
