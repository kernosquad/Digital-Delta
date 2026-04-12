import vine from '@vinejs/vine'

import type { Infer } from '@vinejs/vine/types'

export const createReceiptValidator = vine.compile(
  vine.object({
    mission_id: vine.number().min(0),
    recipient_location_id: vine.number().min(0),
    qr_nonce: vine.string().maxLength(128),
    driver_signature: vine.string(),
    recipient_signature: vine.string().optional(),
    payload_hash: vine.string().fixedLength(64),
  })
)
export type CreateReceiptType = Infer<typeof createReceiptValidator>

// M5.1 — Driver generates a signed QR payload before physical handoff
export const generateQrValidator = vine.compile(
  vine.object({
    mission_id: vine.number().min(1),
    cargo_description: vine.string().maxLength(500).optional(),
  })
)
export type GenerateQrType = Infer<typeof generateQrValidator>
