import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm'

import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import type { DateTime } from 'luxon'

import SyncNode from '#models/sync_node'

export type CrdtOpType = 'increment' | 'decrement' | 'set' | 'delete' | 'merge'

export default class CrdtOperation extends BaseModel {
  static table = 'crdt_operations'
  static updatedAt = false as const

  @column({ isPrimary: true })
  declare id: number

  @column()
  declare operationUuid: string

  @column()
  declare syncNodeId: number

  @column()
  declare opType: CrdtOpType

  @column()
  declare entityType: string

  @column()
  declare entityId: number

  @column()
  declare fieldName: string

  @column({
    prepare: (v: unknown) => (v !== null && v !== undefined ? JSON.stringify(v) : null),
    consume: (v: unknown) => (typeof v === 'string' ? JSON.parse(v) : v),
  })
  declare oldValue: unknown | null

  @column({
    prepare: (v: unknown) => JSON.stringify(v),
    consume: (v: unknown) => (typeof v === 'string' ? JSON.parse(v) : v),
  })
  declare newValue: unknown

  @column({
    prepare: (v: unknown) => JSON.stringify(v),
    consume: (v: unknown) => (typeof v === 'string' ? JSON.parse(v) : v),
  })
  declare vectorClock: Record<string, number>

  @column()
  declare isConflicted: boolean

  @column()
  declare isResolved: boolean

  @column.dateTime()
  declare createdAt: DateTime

  @column.dateTime()
  declare syncedAt: DateTime | null

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => SyncNode)
  declare syncNode: BelongsTo<typeof SyncNode>
}
