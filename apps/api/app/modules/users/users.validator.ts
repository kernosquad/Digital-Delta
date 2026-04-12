import vine from '@vinejs/vine'

import type { Infer } from '@vinejs/vine/types'

export const updateRoleValidator = vine.compile(
  vine.object({
    role: vine.enum([
      'field_volunteer',
      'supply_manager',
      'drone_operator',
      'camp_commander',
      'sync_admin',
    ] as const),
  })
)
export type UpdateRoleType = Infer<typeof updateRoleValidator>

export const updateStatusValidator = vine.compile(
  vine.object({
    status: vine.enum(['active', 'inactive', 'suspended'] as const),
  })
)
export type UpdateStatusType = Infer<typeof updateStatusValidator>
