import vine from '@vinejs/vine';

import type { Infer } from '@vinejs/vine/types';

export const storeVehicleValidator = vine.compile(
  vine.object({
    name: vine.string().maxLength(100).trim(),
    type: vine.enum(['truck', 'speedboat', 'drone'] as const),
    identifier: vine.string().maxLength(50).trim(),
    max_payload_kg: vine.number().positive(),
  })
);
export type StoreVehicleType = Infer<typeof storeVehicleValidator>;

export const updateVehicleValidator = vine.compile(
  vine.object({
    status: vine.enum(['idle', 'in_mission', 'maintenance', 'offline'] as const).optional(),
    current_location_id: vine.number().min(0).optional(),
    battery_level: vine.number().min(0).max(100).optional(),
    fuel_level: vine.number().min(0).max(100).optional(),
  })
);
export type UpdateVehicleType = Infer<typeof updateVehicleValidator>;
