import vine from '@vinejs/vine';

import type { Infer } from '@vinejs/vine/types';

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
);
export type StoreHandoffType = Infer<typeof storeHandoffValidator>;

export const completeHandoffValidator = vine.compile(
  vine.object({
    delivery_receipt_id: vine.number().min(0).optional(),
    completed_at: vine.string().optional(),
  })
);
export type CompleteHandoffType = Infer<typeof completeHandoffValidator>;
