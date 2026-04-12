import { BaseModel, belongsTo, column, hasMany } from '@adonisjs/lucid/orm';

import type { BelongsTo, HasMany } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import MeshRelayLog from '#models/mesh_relay_log';
import SyncNode from '#models/sync_node';

export type MeshMessageType =
  | 'crdt_delta'
  | 'delivery_receipt'
  | 'mission_update'
  | 'alert'
  | 'sync_ack';

export default class MeshMessage extends BaseModel {
  static table = 'mesh_messages';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare messageUuid: string;

  @column()
  declare senderNodeId: number;

  @column()
  declare recipientNodeId: number;

  @column()
  declare messageType: MeshMessageType;

  @column()
  declare encryptedPayload: Buffer;

  @column()
  declare payloadHash: string;

  @column()
  declare ttlHours: number;

  @column()
  declare hopCount: number;

  @column()
  declare maxHops: number;

  @column()
  declare isDelivered: boolean;

  @column.dateTime()
  declare deliveredAt: DateTime | null;

  @column.dateTime()
  declare createdAt: DateTime;

  @column.dateTime()
  declare expiresAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => SyncNode, { foreignKey: 'senderNodeId' })
  declare senderNode: BelongsTo<typeof SyncNode>;

  @belongsTo(() => SyncNode, { foreignKey: 'recipientNodeId' })
  declare recipientNode: BelongsTo<typeof SyncNode>;

  @hasMany(() => MeshRelayLog, { foreignKey: 'meshMessageId' })
  declare relayLogs: HasMany<typeof MeshRelayLog>;
}
