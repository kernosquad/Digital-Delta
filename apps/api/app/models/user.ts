import { withAuthFinder } from '@adonisjs/auth/mixins/lucid';
import { compose } from '@adonisjs/core/helpers';
import hash from '@adonisjs/core/services/hash';
import { BaseModel, column, hasMany } from '@adonisjs/lucid/orm';

import type { HasMany } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import AuthLog from '#models/auth_log';
import OtpSecret from '#models/otp_secret';
import UserKey from '#models/user_key';

const AuthFinder = withAuthFinder(() => hash.use('scrypt'), {
  uids: ['email'],
  passwordColumnName: 'password',
});

export type UserRole =
  | 'field_volunteer'
  | 'supply_manager'
  | 'drone_operator'
  | 'camp_commander'
  | 'sync_admin';

export type UserStatus = 'active' | 'inactive' | 'suspended';

export default class User extends compose(BaseModel, AuthFinder) {
  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare name: string;

  @column()
  declare email: string;

  @column()
  declare phone: string | null;

  @column({ serializeAs: null })
  declare password: string;

  @column()
  declare role: UserRole;

  @column()
  declare status: UserStatus;

  @column.dateTime()
  declare lastSeenAt: DateTime | null;

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime;

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  declare updatedAt: DateTime | null;

  @column.dateTime()
  declare deletedAt: DateTime | null;

  // ── Relations ──────────────────────────────────────────────────────────
  @hasMany(() => UserKey)
  declare userKeys: HasMany<typeof UserKey>;

  @hasMany(() => OtpSecret)
  declare otpSecrets: HasMany<typeof OtpSecret>;

  @hasMany(() => AuthLog)
  declare authLogs: HasMany<typeof AuthLog>;
}
