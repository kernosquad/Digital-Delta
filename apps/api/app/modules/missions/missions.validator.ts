import vine from '@vinejs/vine'
import type { Infer } from '@vinejs/vine/types'

export const storeMissionValidator = vine.compile(
  vine.object({
    origin_location_id: vine.number().unsigned(),
    destination_location_id: vine.number().unsigned(),
    vehicle_id: vine.number().unsigned(),
    driver_id: vine.number().unsigned().optional(),
    priority_class: vine.enum(['p0_critical', 'p1_high', 'p2_standard', 'p3_low'] as const),
    notes: vine.string().optional(),
    cargo: vine.array(
      vine.object({
        supply_item_id: vine.number().unsigned(),
        quantity: vine.number().positive(),
      })
    ),
  })
)
export type StoreMissionType = Infer<typeof storeMissionValidator>

export const updateStatusValidator = vine.compile(
  vine.object({
    status: vine.enum([
      'planned',
      'active',
      'paused',
      'completed',
      'failed',
      'preempted',
      'cancelled',
    ] as const),
    notes: vine.string().optional(),
  })
)
export type UpdateStatusType = Infer<typeof updateStatusValidator>

export const preemptValidator = vine.compile(
  vine.object({
    preempting_mission_id: vine.number().unsigned(),
    reason: vine.string().optional(),
  })
)
export type PreemptType = Infer<typeof preemptValidator>
