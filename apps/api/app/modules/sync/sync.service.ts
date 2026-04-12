import db from '@adonisjs/lucid/services/db';

import type { PushType, ResolveConflictType, RegisterNodeType } from './sync.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

import { EventBus } from '#services/event_bus';

export class SyncService {
  private async applyOperation(op: {
    op_type: string;
    entity_type: string;
    entity_id: number;
    field_name: string;
    new_value?: any;
  }) {
    if (op.new_value === undefined) return;
    const table = op.entity_type;
    const allowedTables = ['inventory', 'missions', 'delivery_receipts', 'vehicles', 'locations'];
    if (!allowedTables.includes(table)) return;
    const value = typeof op.new_value === 'object' ? JSON.stringify(op.new_value) : op.new_value;
    await db
      .from(table)
      .where('id', op.entity_id)
      .update({ [op.field_name]: value });
  }

  async push(ctx: HttpContext, payload: PushType) {
    const { response } = ctx;

    const node = await db.from('sync_nodes').where('node_uuid', payload.node_uuid).first();
    if (!node) {
      return response.notFound({
        error: 'Node not registered. Call POST /api/sync/nodes/register first.',
      });
    }

    let accepted = 0;
    let skipped = 0;
    let conflictsCreated = 0;
    const now = new Date();

    for (const op of payload.operations) {
      const exists = await db
        .from('crdt_operations')
        .where('operation_uuid', op.operation_uuid)
        .first();
      if (exists) {
        skipped++;
        continue;
      }

      const [opId] = await db.table('crdt_operations').insert({
        operation_uuid: op.operation_uuid,
        sync_node_id: node.id,
        op_type: op.op_type,
        entity_type: op.entity_type,
        entity_id: op.entity_id,
        field_name: op.field_name,
        old_value: JSON.stringify(op.old_value ?? null),
        new_value: JSON.stringify(op.new_value),
        vector_clock: JSON.stringify(op.vector_clock),
        is_conflicted: false,
        is_resolved: false,
        created_at: new Date(op.created_at),
        synced_at: now,
      });

      await this.applyOperation(op);

      const concurrent = await db
        .from('crdt_operations')
        .where('entity_type', op.entity_type)
        .where('entity_id', op.entity_id)
        .where('field_name', op.field_name)
        .whereNot('operation_uuid', op.operation_uuid)
        .whereNot('sync_node_id', node.id)
        .where('is_conflicted', false)
        .first();

      if (concurrent) {
        await db.table('sync_conflicts').insert({
          op_a_id: opId,
          op_b_id: concurrent.id,
          entity_type: op.entity_type,
          entity_id: op.entity_id,
          field_name: op.field_name,
          value_a: JSON.stringify(op.new_value),
          value_b: concurrent.new_value,
          resolution: null,
          created_at: now,
        });
        await db
          .from('crdt_operations')
          .whereIn('id', [opId, concurrent.id])
          .update({ is_conflicted: true });
        EventBus.publish('conflict_detected', {
          entityType: op.entity_type,
          entityId: op.entity_id,
          field: op.field_name,
        });
        conflictsCreated++;
      }

      accepted++;
    }

    return response.ok({ accepted, skipped, conflicts_created: conflictsCreated });
  }

  async pull(ctx: HttpContext) {
    const { request, response } = ctx;

    const nodeUuid = request.input('node_uuid');
    const vcRaw = request.input('vc', '{}');

    if (!nodeUuid) {
      return response.badRequest({ error: 'node_uuid is required' });
    }

    let vectorClock: Record<string, number> = {};
    try {
      vectorClock = JSON.parse(vcRaw);
    } catch {
      return response.badRequest({ error: 'vc must be valid JSON' });
    }

    const isFirstSync = Object.keys(vectorClock).length === 0;
    const allNodes = await db.from('sync_nodes').select('id', 'node_uuid');
    const deltaOps: any[] = [];

    for (const node of allNodes) {
      const knownCounter = vectorClock[node.node_uuid] ?? 0;
      const ops = await db
        .from('crdt_operations')
        .where('sync_node_id', node.id)
        .where('id', '>', knownCounter)
        .select('*');
      deltaOps.push(...ops);
    }

    const result: Record<string, any> = {
      operations: deltaOps,
      server_time: new Date().toISOString(),
    };

    if (isFirstSync) {
      result.bootstrap = {
        locations: await db.from('locations').where('is_active', true),
        routes: await db.from('routes'),
        supply_items: await db.from('supply_items'),
        sync_nodes: await db.from('sync_nodes').select('id', 'node_uuid', 'public_key', 'is_relay'),
      };
    }

    return response.ok(result);
  }

  async conflicts(ctx: HttpContext) {
    const { response } = ctx;
    return response.ok({
      data: await db.from('sync_conflicts').whereNull('resolution').orderBy('created_at', 'desc'),
    });
  }

  async resolveConflict(ctx: HttpContext, payload: ResolveConflictType) {
    const { params, auth, response } = ctx;

    const conflict = await db.from('sync_conflicts').where('id', params.id).first();

    await db
      .from('sync_conflicts')
      .where('id', params.id)
      .update({
        resolution: payload.resolution,
        resolved_value: payload.resolved_value ? JSON.stringify(payload.resolved_value) : null,
        resolved_by_user_id: auth.user!.id,
        resolved_at: new Date(),
      });

    if (conflict) {
      await db
        .from('crdt_operations')
        .whereIn('id', [conflict.op_a_id, conflict.op_b_id])
        .update({ is_resolved: true });
    }

    return response.ok({ message: 'Conflict resolved' });
  }

  async nodes(ctx: HttpContext) {
    const { response } = ctx;
    return response.ok({
      data: await db
        .from('sync_nodes')
        .select('id', 'node_uuid', 'node_type', 'is_relay', 'last_seen_at', 'battery_level'),
    });
  }

  async registerNode(ctx: HttpContext, payload: RegisterNodeType) {
    const { auth, response } = ctx;

    const existing = await db.from('sync_nodes').where('node_uuid', payload.node_uuid).first();
    if (existing) {
      await db
        .from('sync_nodes')
        .where('node_uuid', payload.node_uuid)
        .update({ last_seen_at: new Date(), updated_at: new Date() });
      return response.ok({ message: 'Node already registered, last_seen_at updated' });
    }

    const [id] = await db.table('sync_nodes').insert({
      node_uuid: payload.node_uuid,
      user_id: auth.user!.id,
      node_type: payload.node_type ?? 'mobile',
      public_key: payload.public_key,
      battery_level: null,
      is_relay: false,
      last_seen_at: new Date(),
      created_at: new Date(),
      updated_at: new Date(),
    });

    return response.created({ id, node_uuid: payload.node_uuid });
  }
}
