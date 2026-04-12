import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm'

import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import type { DateTime } from 'luxon'

import CrdtOperation from '#models/crdt_operation'
import User from '#models/user'

export type ConflictResolution = 'a_wins' | 'b_wins' | 'merged' | 'manual'

export default class SyncConflict extends BaseModel {
  static table = 'sync_conflicts'
  static updatedAt = false as const

  @column({ isPrimary: true })
  declare id: number

  @column()
  declare opAId: number

  @column()
  declare opBId: number

  @column()
  declare entityType: string

  @column()
  declare entityId: number

  @column()
  declare fieldName: string

  @column({
    prepare: (v: unknown) => JSON.stringify(v),
    consume: (v: unknown) => (typeof v === 'string' ? JSON.parse(v) : v),
  })
  declare valueA: unknown

  @column({
    prepare: (v: unknown) => JSON.stringify(v),
    consume: (v: unknown) => (typeof v === 'string' ? JSON.parse(v) : v),
  })
  declare valueB: unknown

  @column()
  declare resolution: ConflictResolution | null

  @column({
    prepare: (v: unknown) => (v !== null && v !== undefined ? JSON.stringify(v) : null),
    consume: (v: unknown) => (typeof v === 'string' ? JSON.parse(v) : v),
  })
  declare resolvedValue: unknown | null

  @column()
  declare resolvedByUserId: number | null

  @column.dateTime()
  declare resolvedAt: DateTime | null

  @column.dateTime()
  declare createdAt: DateTime

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => CrdtOperation, { foreignKey: 'opAId' })
  declare operationA: BelongsTo<typeof CrdtOperation>

  @belongsTo(() => CrdtOperation, { foreignKey: 'opBId' })
  declare operationB: BelongsTo<typeof CrdtOperation>

  @belongsTo(() => User, { foreignKey: 'resolvedByUserId' })
  declare resolvedBy: BelongsTo<typeof User>
}
