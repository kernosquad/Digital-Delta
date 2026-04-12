import db from '@adonisjs/lucid/services/db';

import type { StoreLocationType, UpdateLocationStatusType } from './locations.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

import { EventBus } from '#services/event_bus';

export class LocationsService {
  async index(ctx: HttpContext) {
    const { request, response } = ctx;
    const type = request.input('type');
    const isFlooded = request.input('is_flooded');

    const query = db.from('locations').where('is_active', true);
    if (type) query.where('type', type);
    if (isFlooded !== undefined) query.where('is_flooded', isFlooded === 'true');

    return response.sendFormatted(await query.select('*').orderBy('node_code'));
  }

  async show(ctx: HttpContext) {
    const { params, response } = ctx;

    const location = await db.from('locations').where('id', params.id).firstOrFail();
    const inventory = await db
      .from('inventory as i')
      .join('supply_items as s', 's.id', 'i.supply_item_id')
      .where('i.location_id', params.id)
      .select('s.name', 's.category', 's.unit', 'i.quantity', 'i.reserved_quantity');

    return response.sendFormatted({ ...location, inventory });
  }

  async store(ctx: HttpContext, payload: StoreLocationType) {
    const { response } = ctx;

    const [id] = await db.table('locations').insert({
      ...payload,
      is_active: true,
      is_flooded: false,
      current_occupancy: 0,
      created_at: new Date(),
      updated_at: new Date(),
    });

    return response.status(201).sendFormatted(await db.from('locations').where('id', id).first());
  }

  async updateStatus(ctx: HttpContext, payload: UpdateLocationStatusType) {
    const { params, response } = ctx;

    await db
      .from('locations')
      .where('id', params.id)
      .update({ ...payload, updated_at: new Date() });

    EventBus.publish('route_update', { locationId: Number(params.id), ...payload });

    return response.sendFormatted(await db.from('locations').where('id', params.id).first());
  }
}
