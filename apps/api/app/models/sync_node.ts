import { BaseModel, belongsTo, column, hasMany } from '@adonisjs/lucid/orm';

import type { BelongsTo, HasMany } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import CrdtOperation from '#models/crdt_operation';
import MeshMessage from '#models/mesh_message';
import User from '#models/user';

export type NodeType = 'mobile' | 'relay' | 'base_station';

export default class SyncNode extends BaseModel {
  static table = 'sync_nodes';

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare nodeUuid: string;

  @column()
  declare userId: number | null;

  @column()
  declare nodeType: NodeType;

  @column()
  declare publicKey: string;

  @column()
  declare batteryLevel: number | null;

  @column()
  declare isRelay: boolean;

  @column.dateTime()
  declare lastSeenAt: DateTime | null;

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime;

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  declare updatedAt: DateTime | null;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => User)
  declare user: BelongsTo<typeof User>;

  @hasMany(() => CrdtOperation, { foreignKey: 'syncNodeId' })
  declare crdtOperations: HasMany<typeof CrdtOperation>;

  @hasMany(() => MeshMessage, { foreignKey: 'senderNodeId' })
  declare sentMessages: HasMany<typeof MeshMessage>;

  @hasMany(() => MeshMessage, { foreignKey: 'recipientNodeId' })
  declare receivedMessages: HasMany<typeof MeshMessage>;
}
