import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm'

import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import type { DateTime } from 'luxon'

import Route from '#models/route'

export type RiskLevel = 'low' | 'medium' | 'high' | 'critical'

export default class RouteMLPrediction extends BaseModel {
  static table = 'route_ml_predictions'
  static updatedAt = false as const

  @column({ isPrimary: true })
  declare id: number

  @column()
  declare routeId: number

  @column.dateTime()
  declare predictedAt: DateTime

  @column()
  declare impassabilityProb: number

  @column()
  declare predictedTravelMins: number

  @column()
  declare riskLevel: RiskLevel

  @column({
    prepare: (v: unknown) => JSON.stringify(v),
    consume: (v: unknown) => (typeof v === 'string' ? JSON.parse(v) : v),
  })
  declare featuresSnapshot: Record<string, unknown>

  @column()
  declare modelVersion: string

  @column()
  declare isActive: boolean

  @column.dateTime()
  declare createdAt: DateTime

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Route)
  declare route: BelongsTo<typeof Route>
}
