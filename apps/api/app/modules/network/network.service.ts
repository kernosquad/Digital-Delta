import db from '@adonisjs/lucid/services/db';

import type { StoreEdgeType, EdgeStatusType } from './network.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

import { EventBus } from '#services/event_bus';

export class NetworkService {
  async graph(ctx: HttpContext) {
    const { response } = ctx;

    const nodes = await db
      .from('locations')
      .where('is_active', true)
      .select(
        'id',
        'node_code as code',
        'name',
        'type',
        'latitude as lat',
        'longitude as lng',
        'is_flooded',
        'capacity',
        'current_occupancy'
      );

    const edges = await db
      .from('routes')
      .select(
        'id',
        'edge_code as code',
        'source_location_id as source',
        'target_location_id as target',
        'route_type as type',
        'base_travel_mins',
        'current_travel_mins',
        'is_flooded',
        'is_blocked',
        'risk_score',
        'max_payload_kg',
        'allowed_vehicles'
      );

    return response.ok({ nodes, edges, fetched_at: new Date().toISOString() });
  }

  async edges(ctx: HttpContext) {
    const { request, response } = ctx;

    const routeType = request.input('type');
    const isFlooded = request.input('is_flooded');

    const query = db.from('routes');
    if (routeType) query.where('route_type', routeType);
    if (isFlooded !== undefined) query.where('is_flooded', isFlooded === 'true');

    return response.ok({ data: await query });
  }

  async showEdge(ctx: HttpContext) {
    const { params, response } = ctx;

    const edge = await db.from('routes').where('id', params.id).firstOrFail();
    const prediction = await db
      .from('route_ml_predictions')
      .where('route_id', params.id)
      .where('is_active', true)
      .first();

    return response.ok({ ...edge, prediction });
  }

  async compute(ctx: HttpContext) {
    const { request, response } = ctx;

    const fromCode = request.input('from');
    const toCode = request.input('to');
    const vehicle = request.input('vehicle', 'truck');

    if (!fromCode || !toCode) {
      return response.badRequest({ error: 'from and to query params are required' });
    }

    const allowedType = vehicle === 'truck' ? 'road' : vehicle === 'speedboat' ? 'river' : 'airway';

    const edges = await db
      .from('routes')
      .where('route_type', allowedType)
      .where('is_flooded', false)
      .where('is_blocked', false)
      .select(
        'id',
        'source_location_id',
        'target_location_id',
        'current_travel_mins as weight',
        'risk_score'
      );

    const fromNode = await db.from('locations').where('node_code', fromCode).first();
    const toNode = await db.from('locations').where('node_code', toCode).first();

    if (!fromNode || !toNode) {
      return response.notFound({ error: 'One or both locations not found' });
    }

    return response.ok({
      message: 'VRP compute — implement Dijkstra/A* here',
      from: fromNode,
      to: toNode,
      vehicle,
      available_edges: edges.length,
    });
  }

  async storeEdge(ctx: HttpContext, payload: StoreEdgeType) {
    const { response } = ctx;

    const [id] = await db.table('routes').insert({
      ...payload,
      allowed_vehicles: JSON.stringify(payload.allowed_vehicles ?? []),
      current_travel_mins: payload.base_travel_mins,
      is_flooded: false,
      is_blocked: false,
      risk_score: 0,
      created_at: new Date(),
      updated_at: new Date(),
    });

    return response.created({ data: await db.from('routes').where('id', id).first() });
  }

  async updateEdgeStatus(ctx: HttpContext, payload: EdgeStatusType) {
    const { params, auth, response } = ctx;

    const route = await db.from('routes').where('id', params.id).firstOrFail();

    await db.table('route_condition_logs').insert({
      route_id: params.id,
      changed_by_user_id: auth.user?.id ?? null,
      old_travel_mins: route.current_travel_mins,
      new_travel_mins: payload.current_travel_mins ?? route.current_travel_mins,
      old_risk_score: route.risk_score,
      new_risk_score: payload.risk_score ?? route.risk_score,
      is_flooded: payload.is_flooded ?? route.is_flooded,
      reason: payload.reason ?? 'manual_override',
      created_at: new Date(),
    });

    await db
      .from('routes')
      .where('id', params.id)
      .update({
        ...(payload.is_flooded !== undefined && { is_flooded: payload.is_flooded }),
        ...(payload.is_blocked !== undefined && { is_blocked: payload.is_blocked }),
        ...(payload.current_travel_mins && { current_travel_mins: payload.current_travel_mins }),
        ...(payload.risk_score !== undefined && { risk_score: payload.risk_score }),
        updated_at: new Date(),
      });

    EventBus.publish('route_update', {
      routeId: Number(params.id),
      edgeCode: route.edge_code,
      ...payload,
    });

    return response.ok({ message: 'Edge status updated' });
  }
}
