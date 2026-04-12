import { BaseModel, belongsTo, column, hasMany, hasOne } from '@adonisjs/lucid/orm';

import type { BelongsTo, HasMany, HasOne } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import HandoffEvent from '#models/handoff_event';
import Location from '#models/location';
import Mission from '#models/mission';
import UsedNonce from '#models/used_nonce';
import User from '#models/user';

export default class DeliveryReceipt extends BaseModel {
  static table = 'delivery_receipts';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare missionId: number;

  @column()
  declare recipientLocationId: number;

  @column()
  declare receivedByUserId: number | null;

  @column()
  declare driverUserId: number | null;

  @column()
  declare qrNonce: string;

  @column()
  declare driverSignature: string;

  @column()
  declare recipientSignature: string | null;

  @column()
  declare payloadHash: string;

  @column()
  declare isVerified: boolean;

  @column.dateTime()
  declare verifiedAt: DateTime | null;

  @column()
  declare crdtSequence: number | null;

  @column()
  declare previousReceiptHash: string | null;

  @column()
  declare receiptHash: string;

  @column.dateTime()
  declare createdAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Mission)
  declare mission: BelongsTo<typeof Mission>;

  @belongsTo(() => Location, { foreignKey: 'recipientLocationId' })
  declare recipientLocation: BelongsTo<typeof Location>;

  @belongsTo(() => User, { foreignKey: 'receivedByUserId' })
  declare receivedBy: BelongsTo<typeof User>;

  @belongsTo(() => User, { foreignKey: 'driverUserId' })
  declare driver: BelongsTo<typeof User>;

  @hasMany(() => UsedNonce)
  declare usedNonces: HasMany<typeof UsedNonce>;

  @hasOne(() => HandoffEvent, { foreignKey: 'deliveryReceiptId' })
  declare handoffEvent: HasOne<typeof HandoffEvent>;
}
