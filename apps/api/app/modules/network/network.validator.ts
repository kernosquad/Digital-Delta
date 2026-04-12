import vine from '@vinejs/vine'
import type { Infer } from '@vinejs/vine/types'

export const storeEdgeValidator = vine.compile(
  vine.object({
    edge_code: vine.string().maxLength(20).toUpperCase(),
    source_location_id: vine.number().unsigned(),
    target_location_id: vine.number().unsigned(),
    route_type: vine.enum(['road', 'river', 'airway'] as const),
    base_travel_mins: vine.number().unsigned(),
    max_payload_kg: vine.number().optional(),
    allowed_vehicles: vine
      .array(vine.enum(['truck', 'speedboat', 'drone'] as const))
      .optional(),
  })
)
export type StoreEdgeType = Infer<typeof storeEdgeValidator>

export const edgeStatusValidator = vine.compile(
  vine.object({
    is_flooded: vine.boolean().optional(),
    is_blocked: vine.boolean().optional(),
    current_travel_mins: vine.number().unsigned().optional(),
    risk_score: vine.number().min(0).max(1).optional(),
    reason: vine
      .enum([
        'flood',
        'recede',
        'ml_prediction',
        'manual_override',
        'chaos_engine',
      ] as const)
      .optional(),
  })
)
export type EdgeStatusType = Infer<typeof edgeStatusValidator>
