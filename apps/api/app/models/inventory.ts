import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import Location from '#models/location';
import SupplyItem from '#models/supply_item';

export default class Inventory extends BaseModel {
  static table = 'inventory';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare locationId: number;

  @column()
  declare supplyItemId: number;

  @column()
  declare quantity: number;

  @column()
  declare reservedQuantity: number;

  @column({
    prepare: (v: Record<string, number> | null) => (v !== null ? JSON.stringify(v) : null),
    consume: (v: string | null) => (v !== null ? (JSON.parse(v) as Record<string, number>) : null),
  })
  declare crdtVectorClock: Record<string, number> | null;

  @column()
  declare lastUpdatedNode: string | null;

  @column.dateTime()
  declare lastSyncedAt: DateTime | null;

  @column.dateTime()
  declare updatedAt: DateTime | null;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Location)
  declare location: BelongsTo<typeof Location>;

  @belongsTo(() => SupplyItem)
  declare supplyItem: BelongsTo<typeof SupplyItem>;
}
