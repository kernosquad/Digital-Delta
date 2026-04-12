import vine from '@vinejs/vine'
import type { Infer } from '@vinejs/vine/types'

export const storeHandoffValidator = vine.compile(
  vine.object({
    mission_id: vine.number().unsigned(),
    drone_vehicle_id: vine.number().unsigned(),
    ground_vehicle_id: vine.number().unsigned(),
    rendezvous_location_id: vine.number().unsigned().optional(),
    rendezvous_lat: vine.number().min(-90).max(90),
    rendezvous_lng: vine.number().min(-180).max(180),
    scheduled_at: vine.string(),
  })
)
export type StoreHandoffType = Infer<typeof storeHandoffValidator>

export const completeHandoffValidator = vine.compile(
  vine.object({
    delivery_receipt_id: vine.number().unsigned().optional(),
    completed_at: vine.string().optional(),
  })
)
export type CompleteHandoffType = Infer<typeof completeHandoffValidator>
