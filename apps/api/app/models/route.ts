import { BaseModel, belongsTo, column, hasMany } from '@adonisjs/lucid/orm'

import type { BelongsTo, HasMany } from '@adonisjs/lucid/types/relations'
import type { DateTime } from 'luxon'

import Location from '#models/location'
import RouteConditionLog from '#models/route_condition_log'
import RouteMLPrediction from '#models/route_ml_prediction'

export type RouteType = 'road' | 'river' | 'airway'

export default class Route extends BaseModel {
  static table = 'routes'

  @column({ isPrimary: true })
  declare id: number

  @column()
  declare edgeCode: string

  @column()
  declare sourceLocationId: number

  @column()
  declare targetLocationId: number

  @column()
  declare routeType: RouteType

  @column()
  declare baseTravelMins: number

  @column()
  declare currentTravelMins: number

  @column()
  declare isFlooded: boolean

  @column()
  declare isBlocked: boolean

  @column()
  declare riskScore: number

  @column()
  declare maxPayloadKg: number | null

  @column({
    prepare: (v: string[] | null) => (v !== null ? JSON.stringify(v) : null),
    consume: (v: unknown) => {
      if (v === null || v === undefined) return null
      if (Array.isArray(v)) return v as string[]
      return JSON.parse(v as string) as string[]
    },
  })
  declare allowedVehicles: string[] | null

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  declare updatedAt: DateTime | null

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Location, { foreignKey: 'sourceLocationId' })
  declare sourceLocation: BelongsTo<typeof Location>

  @belongsTo(() => Location, { foreignKey: 'targetLocationId' })
  declare targetLocation: BelongsTo<typeof Location>

  @hasMany(() => RouteConditionLog, { foreignKey: 'routeId' })
  declare conditionLogs: HasMany<typeof RouteConditionLog>

  @hasMany(() => RouteMLPrediction, { foreignKey: 'routeId' })
  declare mlPredictions: HasMany<typeof RouteMLPrediction>
}
