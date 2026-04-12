import vine from '@vinejs/vine'
import type { Infer } from '@vinejs/vine/types'

export const webLoginSchema = vine.compile(
  vine.object({
    email: vine.string().email().trim().toLowerCase(),
    password: vine.string().minLength(8),
  })
)

export type WebLoginType = Infer<typeof webLoginSchema>
