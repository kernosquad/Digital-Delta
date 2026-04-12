import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import MeshMessage from '#models/mesh_message';
import SyncNode from '#models/sync_node';

export default class MeshRelayLog extends BaseModel {
  static table = 'mesh_relay_logs';
  static createdAt = false as const;
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare meshMessageId: number;

  @column()
  declare relayNodeId: number;

  @column.dateTime()
  declare relayedAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => MeshMessage)
  declare meshMessage: BelongsTo<typeof MeshMessage>;

  @belongsTo(() => SyncNode, { foreignKey: 'relayNodeId' })
  declare relayNode: BelongsTo<typeof SyncNode>;
}
