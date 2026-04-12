import vine from '@vinejs/vine';

import type { Infer } from '@vinejs/vine/types';

export const storeLocationValidator = vine.compile(
  vine.object({
    node_code: vine.string().maxLength(20).toUpperCase(),
    name: vine.string().maxLength(150).trim(),
    type: vine.enum([
      'central_command',
      'supply_drop',
      'relief_camp',
      'waypoint',
      'hospital',
      'drone_base',
    ] as const),
    latitude: vine.number().min(-90).max(90),
    longitude: vine.number().min(-180).max(180),
    capacity: vine.number().min(0).optional(),
    notes: vine.string().optional(),
  })
);
export type StoreLocationType = Infer<typeof storeLocationValidator>;

export const updateLocationStatusValidator = vine.compile(
  vine.object({
    is_flooded: vine.boolean().optional(),
    is_active: vine.boolean().optional(),
    current_occupancy: vine.number().min(0).optional(),
  })
);
export type UpdateLocationStatusType = Infer<typeof updateLocationStatusValidator>;
