import vine from '@vinejs/vine'
import type { Infer } from '@vinejs/vine/types'

export const pushValidator = vine.compile(
  vine.object({
    node_uuid: vine.string().maxLength(100),
    operations: vine.array(
      vine.object({
        operation_uuid: vine.string().maxLength(100),
        op_type: vine.enum(['increment', 'decrement', 'set', 'delete', 'merge'] as const),
        entity_type: vine.string().maxLength(60),
        entity_id: vine.number(),
        field_name: vine.string().maxLength(100),
        old_value: vine.any().optional(),
        new_value: vine.any(),
        vector_clock: vine.record(vine.number()),
        created_at: vine.string(),
      })
    ),
  })
)
export type PushType = Infer<typeof pushValidator>

export const resolveConflictValidator = vine.compile(
  vine.object({
    resolution: vine.enum(['a_wins', 'b_wins', 'merged', 'manual'] as const),
    resolved_value: vine.any().optional(),
  })
)
export type ResolveConflictType = Infer<typeof resolveConflictValidator>

export const registerNodeValidator = vine.compile(
  vine.object({
    node_uuid: vine.string().maxLength(100),
    public_key: vine.string().optional(),
    node_type: vine.string().maxLength(50).optional(),
  })
)
export type RegisterNodeType = Infer<typeof registerNodeValidator>
