import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import User from '#models/user';

export type KeyType = 'rsa_2048' | 'ed25519';

export default class UserKey extends BaseModel {
  static table = 'user_keys';

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare userId: number;

  @column()
  declare deviceId: string;

  @column()
  declare publicKey: string;

  @column()
  declare keyType: KeyType;

  @column()
  declare isActive: boolean;

  @column.dateTime()
  declare createdAt: DateTime;

  @column.dateTime()
  declare revokedAt: DateTime | null;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => User)
  declare user: BelongsTo<typeof User>;
}
