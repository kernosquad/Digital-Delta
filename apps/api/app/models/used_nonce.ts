import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import DeliveryReceipt from '#models/delivery_receipt';

export default class UsedNonce extends BaseModel {
  static table = 'used_nonces';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare nonce: string;

  @column()
  declare deliveryReceiptId: number;

  @column.dateTime()
  declare createdAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => DeliveryReceipt)
  declare deliveryReceipt: BelongsTo<typeof DeliveryReceipt>;
}
