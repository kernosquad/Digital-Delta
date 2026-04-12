import vine from '@vinejs/vine'

import type { Infer } from '@vinejs/vine/types'

export const storeHandoffValidator = vine.compile(
  vine.object({
    mission_id: vine.number().min(0),
    drone_vehicle_id: vine.number().min(0),
    ground_vehicle_id: vine.number().min(0),
    rendezvous_location_id: vine.number().min(0).optional(),
    rendezvous_lat: vine.number().min(-90).max(90),
    rendezvous_lng: vine.number().min(-180).max(180),
    scheduled_at: vine.string(),
  })
)
export type StoreHandoffType = Infer<typeof storeHandoffValidator>

export const completeHandoffValidator = vine.compile(
  vine.object({
    delivery_receipt_id: vine.number().min(0).optional(),
    completed_at: vine.string().optional(),
  })
)
export type CompleteHandoffType = Infer<typeof completeHandoffValidator>

// M8.2 — Optimal Rendezvous Point Computation
export const rendezvousValidator = vine.compile(
  vine.object({
    boat_lat: vine.number().min(-90).max(90),
    boat_lng: vine.number().min(-180).max(180),
    drone_base_lat: vine.number().min(-90).max(90),
    drone_base_lng: vine.number().min(-180).max(180),
    dest_lat: vine.number().min(-90).max(90),
    dest_lng: vine.number().min(-180).max(180),
    boat_speed_kmh: vine.number().positive().optional(), // default 20
    drone_speed_kmh: vine.number().positive().optional(), // default 60
    drone_max_range_km: vine.number().positive().optional(), // default 50
    payload_kg: vine.number().positive().optional(),
    drone_max_payload_kg: vine.number().positive().optional(),
  })
)
export type RendezvousType = Infer<typeof rendezvousValidator>

// M8.3 — Simulate full handoff coordination protocol
export const simulateProtocolValidator = vine.compile(
  vine.object({
    handoff_id: vine.number().min(1),
    recipient_location_id: vine.number().min(1).optional(),
  })
)
export type SimulateProtocolType = Infer<typeof simulateProtocolValidator>
