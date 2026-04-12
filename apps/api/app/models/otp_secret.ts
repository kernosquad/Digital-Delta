import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import User from '#models/user';

export type OtpAlgorithm = 'totp' | 'hotp';

export default class OtpSecret extends BaseModel {
  static table = 'otp_secrets';

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare userId: number;

  @column()
  declare deviceId: string;

  @column()
  declare secret: string;

  @column()
  declare algorithm: OtpAlgorithm;

  @column()
  declare hotpCounter: number;

  @column()
  declare isActive: boolean;

  @column.dateTime()
  declare createdAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => User)
  declare user: BelongsTo<typeof User>;
}
