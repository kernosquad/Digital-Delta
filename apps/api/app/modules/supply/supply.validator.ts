import vine from '@vinejs/vine';

import type { Infer } from '@vinejs/vine/types';

export const storeItemValidator = vine.compile(
  vine.object({
    name: vine.string().maxLength(150).trim(),
    category: vine.enum(['medical', 'food', 'water', 'shelter', 'equipment', 'other'] as const),
    unit: vine.string().maxLength(50),
    weight_per_unit_kg: vine.number().min(0),
    priority_class: vine.enum(['p0_critical', 'p1_high', 'p2_standard', 'p3_low'] as const),
    sla_hours: vine.number().min(0),
  })
);
export type StoreItemType = Infer<typeof storeItemValidator>;

export const updateStockValidator = vine.compile(
  vine.object({
    quantity: vine.number().min(0),
    crdt_vector_clock: vine.record(vine.number()).optional(),
    last_updated_node: vine.string().maxLength(100).optional(),
  })
);
export type UpdateStockType = Infer<typeof updateStockValidator>;
