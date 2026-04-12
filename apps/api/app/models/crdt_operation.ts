import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import SyncNode from '#models/sync_node';

export type CrdtOpType = 'increment' | 'decrement' | 'set' | 'delete' | 'merge';

export default class CrdtOperation extends BaseModel {
  static table = 'crdt_operations';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare operationUuid: string;

  @column()
  declare syncNodeId: number;

  @column()
  declare opType: CrdtOpType;

  @column()
  declare entityType: string;

  @column()
  declare entityId: number;

  @column()
  declare fieldName: string;

  @column()
  declare oldValue: unknown | null;

  @column()
  declare newValue: unknown;

  @column()
  declare vectorClock: Record<string, number>;

  @column()
  declare isConflicted: boolean;

  @column()
  declare isResolved: boolean;

  @column.dateTime()
  declare createdAt: DateTime;

  @column.dateTime()
  declare syncedAt: DateTime | null;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => SyncNode)
  declare syncNode: BelongsTo<typeof SyncNode>;
}
