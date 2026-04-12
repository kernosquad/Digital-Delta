import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import User from '#models/user';

export type AuthEventType =
  | 'login_success'
  | 'login_fail'
  | 'logout'
  | 'otp_success'
  | 'otp_fail'
  | 'key_provision'
  | 'key_rotation'
  | 'role_change'
  | 'session_expire';

export default class AuthLog extends BaseModel {
  static table = 'auth_logs';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare userId: number | null;

  @column()
  declare eventType: AuthEventType;

  @column()
  declare deviceId: string | null;

  @column()
  declare ipAddress: string | null;

  @column()
  declare payload: Record<string, unknown> | null;

  @column()
  declare previousHash: string | null;

  @column()
  declare eventHash: string;

  @column.dateTime()
  declare createdAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => User)
  declare user: BelongsTo<typeof User>;
}
