import { randomUUID } from 'node:crypto';

import db from '@adonisjs/lucid/services/db';

import type { SendType } from './mesh.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

export class MeshService {
  async send(ctx: HttpContext, payload: SendType) {
    const { auth, response } = ctx;

    const senderNode = await db.from('sync_nodes').where('user_id', auth.user!.id).first();
    if (!senderNode) {
      return response.status(404).sendError('Sender node not registered');
    }

    const recipientNode = await db
      .from('sync_nodes')
      .where('node_uuid', payload.recipient_node_uuid)
      .first();
    if (!recipientNode) {
      return response.status(404).sendError('Recipient node not registered');
    }

    const ttlHours = payload.ttl_hours ?? 24;
    const expiresAt = new Date(Date.now() + ttlHours * 60 * 60 * 1000);
    const messageUuid = randomUUID();
    const payloadBuffer = Buffer.from(payload.encrypted_payload_b64, 'base64');

    const [id] = await db.table('mesh_messages').insert({
      message_uuid: messageUuid,
      sender_node_id: senderNode.id,
      recipient_node_id: recipientNode.id,
      message_type: payload.message_type,
      encrypted_payload: payloadBuffer,
      payload_hash: payload.payload_hash,
      ttl_hours: ttlHours,
      hop_count: 0,
      max_hops: 10,
      is_delivered: false,
      created_at: new Date(),
      expires_at: expiresAt,
    });

    return response.status(201).sendFormatted({ id, message_uuid: messageUuid, expires_at: expiresAt });
  }

  async pending(ctx: HttpContext) {
    const { auth, response } = ctx;

    const node = await db.from('sync_nodes').where('user_id', auth.user!.id).first();
    if (!node) {
      return response.sendFormatted([]);
    }

    const messages = await db
      .from('mesh_messages')
      .where('recipient_node_id', node.id)
      .where('is_delivered', false)
      .where('expires_at', '>', new Date())
      .select(
        'id',
        'message_uuid',
        'sender_node_id',
        'message_type',
        'encrypted_payload',
        'payload_hash',
        'hop_count',
        'created_at',
        'expires_at'
      );

    const serialized = messages.map((m: any) => ({
      ...m,
      encrypted_payload: Buffer.from(m.encrypted_payload).toString('base64'),
    }));

    return response.sendFormatted(serialized);
  }

  async acknowledge(ctx: HttpContext) {
    const { params, auth, response } = ctx;

    const node = await db.from('sync_nodes').where('user_id', auth.user!.id).first();
    const msg = await db.from('mesh_messages').where('message_uuid', params.uuid).firstOrFail();

    if (msg.recipient_node_id !== node?.id) {
      return response.status(403).sendError('Not the intended recipient');
    }

    await db
      .from('mesh_messages')
      .where('message_uuid', params.uuid)
      .update({ is_delivered: true, delivered_at: new Date() });

    return response.sendFormatted('Acknowledged');
  }

  async relay(ctx: HttpContext) {
    const { params, auth, response } = ctx;

    const msg = await db.from('mesh_messages').where('message_uuid', params.uuid).firstOrFail();

    if (msg.hop_count >= msg.max_hops) {
      return response.status(422).sendError('Max hops reached — message dropped');
    }

    if (new Date(msg.expires_at) < new Date()) {
      return response.status(422).sendError('Message expired');
    }

    const relayNode = await db.from('sync_nodes').where('user_id', auth.user!.id).first();
    if (!relayNode) {
      return response.status(404).sendError('Relay node not registered');
    }

    await db
      .from('mesh_messages')
      .where('message_uuid', params.uuid)
      .update({ hop_count: msg.hop_count + 1 });

    await db.table('mesh_relay_logs').insert({
      mesh_message_id: msg.id,
      relay_node_id: relayNode.id,
      relayed_at: new Date(),
    });

    return response.sendFormatted({ hop_count: msg.hop_count + 1 });
  }
}
