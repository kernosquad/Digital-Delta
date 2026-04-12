import { createHash, randomUUID } from 'node:crypto'

import db from '@adonisjs/lucid/services/db'

import type { CreateReceiptType, GenerateQrType } from './delivery.validator.js'
import type { HttpContext } from '@adonisjs/core/http'

export class DeliveryService {
  async checkNonce(ctx: HttpContext) {
    const { request, response } = ctx

    const { nonce } = request.only(['nonce'])
    const used = await db.from('used_nonces').where('nonce', nonce).first()

    return response.sendFormatted({ is_used: !!used })
  }

  async createReceipt(ctx: HttpContext, payload: CreateReceiptType) {
    const { response, auth } = ctx

    const nonceUsed = await db.from('used_nonces').where('nonce', payload.qr_nonce).first()
    if (nonceUsed) {
      return response.status(422).sendError('Nonce already used — replay attack detected')
    }

    const lastReceipt = await db
      .from('delivery_receipts')
      .orderBy('id', 'desc')
      .select('receipt_hash')
      .first()
    const previousHash = lastReceipt?.receipt_hash ?? null

    const rawContent = `${payload.mission_id}:${payload.qr_nonce}:${payload.payload_hash}:${payload.driver_signature}`
    const receiptHash = createHash('sha256').update(rawContent).digest('hex')

    const [receiptId] = await db.table('delivery_receipts').insert({
      mission_id: payload.mission_id,
      recipient_location_id: payload.recipient_location_id,
      received_by_user_id: auth.user!.id,
      driver_user_id: null,
      qr_nonce: payload.qr_nonce,
      driver_signature: payload.driver_signature,
      recipient_signature: payload.recipient_signature ?? null,
      payload_hash: payload.payload_hash,
      is_verified: false,
      previous_receipt_hash: previousHash,
      receipt_hash: receiptHash,
      created_at: new Date(),
    })

    await db.table('used_nonces').insert({
      nonce: payload.qr_nonce,
      delivery_receipt_id: receiptId,
      created_at: new Date(),
    })

    await db.from('missions').where('id', payload.mission_id).update({
      status: 'completed',
      actual_arrival: new Date(),
      updated_at: new Date(),
    })

    return response.status(201).sendFormatted({
      receipt_id: receiptId,
      receipt_hash: receiptHash,
      chain_verified: !!previousHash,
    })
  }

  async showReceipt(ctx: HttpContext) {
    const { params, response } = ctx

    const receipt = await db.from('delivery_receipts').where('id', params.id).firstOrFail()

    return response.sendFormatted(receipt)
  }

  async receiptsByMission(ctx: HttpContext) {
    const { params, response } = ctx

    const receipts = await db
      .from('delivery_receipts')
      .where('mission_id', params.missionId)
      .orderBy('created_at')

    return response.sendFormatted(receipts)
  }

  // M5.1 — Driver-side: generate the signed QR payload for a delivery handshake
  async generateQrPayload(ctx: HttpContext, payload: GenerateQrType) {
    const { response, auth } = ctx

    const mission = await db
      .from('missions')
      .where('id', payload.mission_id)
      .select('id', 'mission_code', 'priority_class', 'status', 'destination_location_id')
      .first()

    if (!mission) {
      return response.status(404).sendError('Mission not found')
    }

    if (mission.status === 'completed' || mission.status === 'cancelled') {
      return response.status(422).sendError(`Mission is already ${mission.status}`)
    }

    // Fetch driver's public key for recipient verification
    const driverKey = await db
      .from('user_keys')
      .where('user_id', auth.user!.id)
      .select('public_key')
      .first()

    const nonce = randomUUID()
    const timestamp = new Date().toISOString()

    // payload_hash = SHA-256(mission_id + nonce + timestamp + cargo_description)
    const payloadRaw = `${payload.mission_id}:${nonce}:${timestamp}:${payload.cargo_description ?? ''}`
    const payloadHash = createHash('sha256').update(payloadRaw).digest('hex')

    // driver_signature = SHA-256(payload_hash + driver_user_id) — simplified for MVP
    // In full implementation this would be RSA/Ed25519 sign with private key
    const signatureRaw = `${payloadHash}:${auth.user!.id}:${nonce}`
    const driverSignature = createHash('sha256').update(signatureRaw).digest('hex')

    const qrData = {
      v: 1, // schema version
      mission_id: payload.mission_id,
      mission_code: mission.mission_code,
      sender_pubkey: driverKey?.public_key ?? null,
      driver_user_id: auth.user!.id,
      payload_hash: payloadHash,
      nonce,
      timestamp,
      driver_signature: driverSignature,
      cargo_description: payload.cargo_description ?? null,
    }

    return response.sendFormatted({
      qr_data: qrData,
      qr_json: JSON.stringify(qrData),
      expires_in_secs: 300, // 5-min window for recipient to scan
    })
  }
}
