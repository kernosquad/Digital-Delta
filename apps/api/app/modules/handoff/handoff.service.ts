import db from '@adonisjs/lucid/services/db';

import type { StoreHandoffType, CompleteHandoffType } from './handoff.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

import { EventBus } from '#services/event_bus';

export class HandoffService {
  async index(ctx: HttpContext) {
    const { request, response } = ctx;

    const status = request.input('status');
    const missionId = request.input('mission_id');

    const query = db
      .from('handoff_events as h')
      .join('missions as m', 'm.id', 'h.mission_id')
      .join('vehicles as dv', 'dv.id', 'h.drone_vehicle_id')
      .join('vehicles as gv', 'gv.id', 'h.ground_vehicle_id')
      .select(
        'h.*',
        'm.mission_code',
        'dv.name as drone_name',
        'dv.identifier as drone_identifier',
        'gv.name as ground_name',
        'gv.identifier as ground_identifier'
      )
      .orderBy('h.scheduled_at', 'desc');

    if (status) query.where('h.status', status);
    if (missionId) query.where('h.mission_id', missionId);

    const data = await query;

    return response.ok({ data });
  }

  async show(ctx: HttpContext) {
    const { params, response } = ctx;

    const handoff = await db
      .from('handoff_events as h')
      .join('missions as m', 'm.id', 'h.mission_id')
      .join('vehicles as dv', 'dv.id', 'h.drone_vehicle_id')
      .join('vehicles as gv', 'gv.id', 'h.ground_vehicle_id')
      .leftJoin('locations as loc', 'loc.id', 'h.rendezvous_location_id')
      .where('h.id', params.id)
      .select(
        'h.*',
        'm.mission_code',
        'm.status as mission_status',
        'm.priority_class',
        'dv.name as drone_name',
        'dv.identifier as drone_identifier',
        'dv.type as drone_type',
        'gv.name as ground_name',
        'gv.identifier as ground_identifier',
        'gv.type as ground_type',
        'loc.name as rendezvous_location_name'
      )
      .first();

    if (!handoff) {
      return response.notFound({ message: 'Handoff event not found' });
    }

    return response.ok(handoff);
  }

  async store(ctx: HttpContext, payload: StoreHandoffType) {
    const { response } = ctx;

    // Validate both vehicles are registered
    const droneVehicle = await db.from('vehicles').where('id', payload.drone_vehicle_id).first();
    if (!droneVehicle) {
      return response.unprocessableEntity({ message: 'Drone vehicle not found' });
    }

    const groundVehicle = await db.from('vehicles').where('id', payload.ground_vehicle_id).first();
    if (!groundVehicle) {
      return response.unprocessableEntity({ message: 'Ground vehicle not found' });
    }

    const [handoffId] = await db.table('handoff_events').insert({
      mission_id: payload.mission_id,
      drone_vehicle_id: payload.drone_vehicle_id,
      ground_vehicle_id: payload.ground_vehicle_id,
      rendezvous_location_id: payload.rendezvous_location_id ?? null,
      rendezvous_lat: payload.rendezvous_lat,
      rendezvous_lng: payload.rendezvous_lng,
      scheduled_at: new Date(payload.scheduled_at),
      status: 'scheduled',
      created_at: new Date(),
    });

    EventBus.publish('mission_update', {
      type: 'handoff_scheduled',
      handoffId,
      missionId: payload.mission_id,
    });

    return response.created({ handoff_id: handoffId });
  }

  async complete(ctx: HttpContext, payload: CompleteHandoffType) {
    const { params, response } = ctx;

    const handoffId = Number(params.id);

    const handoff = await db.from('handoff_events').where('id', handoffId).first();
    if (!handoff) {
      return response.notFound({ message: 'Handoff event not found' });
    }

    await db
      .from('handoff_events')
      .where('id', handoffId)
      .update({
        status: 'completed',
        completed_at: payload.completed_at ? new Date(payload.completed_at) : new Date(),
        ...(payload.delivery_receipt_id !== undefined && {
          delivery_receipt_id: payload.delivery_receipt_id,
        }),
      });

    EventBus.publish('mission_update', {
      type: 'handoff_completed',
      handoffId,
    });

    return response.ok({ message: 'Handoff marked as completed', handoff_id: handoffId });
  }
}
