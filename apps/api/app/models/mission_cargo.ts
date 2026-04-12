import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import Mission from '#models/mission';
import SupplyItem from '#models/supply_item';

export default class MissionCargo extends BaseModel {
  static table = 'mission_cargo';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare missionId: number;

  @column()
  declare supplyItemId: number;

  @column()
  declare quantity: number;

  @column()
  declare deliveredQuantity: number;

  @column.dateTime()
  declare createdAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Mission)
  declare mission: BelongsTo<typeof Mission>;

  @belongsTo(() => SupplyItem)
  declare supplyItem: BelongsTo<typeof SupplyItem>;
}
