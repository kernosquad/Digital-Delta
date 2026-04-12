import vine from '@vinejs/vine';

import type { Infer } from '@vinejs/vine/types';

export const sendValidator = vine.compile(
  vine.object({
    recipient_node_uuid: vine.string().maxLength(100),
    message_type: vine.enum([
      'crdt_delta',
      'delivery_receipt',
      'mission_update',
      'alert',
      'sync_ack',
    ] as const),
    encrypted_payload_b64: vine.string(),
    payload_hash: vine.string().fixedLength(64),
    ttl_hours: vine.number().min(0).max(72).optional(),
  })
);
export type SendType = Infer<typeof sendValidator>;
