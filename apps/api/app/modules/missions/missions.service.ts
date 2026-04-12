import db from '@adonisjs/lucid/services/db';

import type { StoreMissionType, UpdateStatusType, PreemptType } from './missions.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

import { EventBus } from '#services/event_bus';

const SLA_HOURS: Record<string, number> = {
  p0_critical: 2,
  p1_high: 6,
  p2_standard: 24,
  p3_low: 72,
};

export class MissionsService {
  async index(ctx: HttpContext) {
    const { request, response, auth } = ctx;

    const status = request.input('status');
    const priority = request.input('priority_class');

    const query = db
      .from('missions as m')
      .join('locations as o', 'o.id', 'm.origin_location_id')
      .join('locations as d', 'd.id', 'm.destination_location_id')
      .join('vehicles as v', 'v.id', 'm.vehicle_id')
      .select(
        'm.*',
        'o.name as origin_name',
        'd.name as destination_name',
        'v.name as vehicle_name',
        'v.type as vehicle_type'
      );

    if (auth.user!.role === 'field_volunteer') {
      query.where('m.driver_id', auth.user!.id);
    }
    if (status) query.where('m.status', status);
    if (priority) query.where('m.priority_class', priority);

    query.orderByRaw("FIELD(m.priority_class,'p0_critical','p1_high','p2_standard','p3_low')");

    return response.sendFormatted(await query);
  }

  async show(ctx: HttpContext) {
    const { params, response } = ctx;

    const mission = await db.from('missions').where('id', params.id).firstOrFail();

    const cargo = await db
      .from('mission_cargo as mc')
      .join('supply_items as s', 's.id', 'mc.supply_item_id')
      .where('mc.mission_id', params.id)
      .select('s.name', 's.priority_class', 'mc.quantity', 'mc.delivered_quantity');

    const legs = await db
      .from('mission_route_legs as l')
      .join('locations as f', 'f.id', 'l.from_location_id')
      .join('locations as t', 't.id', 'l.to_location_id')
      .join('routes as r', 'r.id', 'l.route_id')
      .where('l.mission_id', params.id)
      .orderBy('l.seq_order')
      .select('l.*', 'f.name as from_name', 't.name as to_name', 'r.route_type');

    return response.sendFormatted({ ...mission, cargo, legs });
  }

  async showRoute(ctx: HttpContext) {
    const { params, response } = ctx;

    const legs = await db
      .from('mission_route_legs as l')
      .join('routes as r', 'r.id', 'l.route_id')
      .where('l.mission_id', params.id)
      .orderBy('l.seq_order')
      .select('l.*', 'r.edge_code', 'r.route_type', 'r.current_travel_mins', 'r.is_flooded');

    return response.sendFormatted(legs);
  }

  async store(ctx: HttpContext, payload: StoreMissionType) {
    const { response, auth } = ctx;

    const itemIds = payload.cargo.map((c) => c.supply_item_id);
    const items = await db.from('supply_items').whereIn('id', itemIds);

    const totalKg = payload.cargo.reduce((sum, c) => {
      const item = items.find((i: any) => i.id === c.supply_item_id);
      return sum + (item?.weight_per_unit_kg ?? 0) * c.quantity;
    }, 0);

    const slaHours = SLA_HOURS[payload.priority_class] ?? 24;
    const slaDeadline = new Date(Date.now() + slaHours * 60 * 60 * 1000);
    const missionCode = `MSN-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`;

    const [missionId] = await db.table('missions').insert({
      mission_code: missionCode,
      status: 'planned',
      priority_class: payload.priority_class,
      origin_location_id: payload.origin_location_id,
      destination_location_id: payload.destination_location_id,
      vehicle_id: payload.vehicle_id,
      driver_id: payload.driver_id ?? null,
      total_payload_kg: totalKg,
      sla_deadline: slaDeadline,
      sla_breached: false,
      created_by_id: auth.user!.id,
      notes: payload.notes ?? null,
      created_at: new Date(),
      updated_at: new Date(),
    });

    const cargoRows = payload.cargo.map((c) => ({
      mission_id: missionId,
      supply_item_id: c.supply_item_id,
      quantity: c.quantity,
      delivered_quantity: 0,
      created_at: new Date(),
    }));
    await db.table('mission_cargo').multiInsert(cargoRows);

    EventBus.publish('mission_update', {
      missionId,
      status: 'planned',
      priority: payload.priority_class,
    });

    return response.status(201).sendFormatted({ mission_id: missionId, mission_code: missionCode });
  }

  async updateStatus(ctx: HttpContext, payload: UpdateStatusType) {
    const { params, response } = ctx;

    await db
      .from('missions')
      .where('id', params.id)
      .update({
        status: payload.status,
        ...(payload.status === 'completed' && { actual_arrival: new Date() }),
        updated_at: new Date(),
      });

    EventBus.publish('mission_update', { missionId: Number(params.id), status: payload.status });

    return response.sendFormatted('Mission status updated');
  }

  async reroute(ctx: HttpContext) {
    const { params, response } = ctx;

    EventBus.publish('mission_update', { missionId: Number(params.id), event: 'rerouted' });

    return response.sendFormatted('Reroute triggered — implement VRP engine here');
  }

  async preempt(ctx: HttpContext, payload: PreemptType) {
    const { params, response } = ctx;

    await db.from('missions').where('id', params.id).update({
      status: 'preempted',
      preempted_by_mission_id: payload.preempting_mission_id,
      preemption_reason: payload.reason,
      updated_at: new Date(),
    });

    await db.table('triage_decisions').insert({
      mission_id: params.id,
      triggered_by: 'priority_preemption',
      rationale: payload.reason ?? 'Higher-priority mission requires this vehicle.',
      preempted_mission_id: params.id,
      created_at: new Date(),
    });

    EventBus.publish('triage_decision', {
      missionId: Number(params.id),
      preemptedBy: payload.preempting_mission_id,
    });

    return response.sendFormatted('Mission preempted');
  }
}
