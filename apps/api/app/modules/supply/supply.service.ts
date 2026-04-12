import db from '@adonisjs/lucid/services/db';

import type { StoreItemType, UpdateStockType } from './supply.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

export class SupplyService {
  async indexItems(ctx: HttpContext) {
    const priority = ctx.request.input('priority_class');
    const query = db.from('supply_items').orderBy('priority_class');
    if (priority) query.where('priority_class', priority);
    return ctx.response.ok({ data: await query });
  }

  async storeItem(ctx: HttpContext, payload: StoreItemType) {
    const [id] = await db
      .table('supply_items')
      .insert({ ...payload, created_at: new Date(), updated_at: new Date() });
    return ctx.response.created({ data: await db.from('supply_items').where('id', id).first() });
  }

  async indexInventory(ctx: HttpContext) {
    const inventory = await db
      .from('inventory as i')
      .join('locations as l', 'l.id', 'i.location_id')
      .join('supply_items as s', 's.id', 'i.supply_item_id')
      .select(
        'l.name as location',
        'l.node_code',
        's.name as item',
        's.category',
        's.unit',
        's.priority_class',
        'i.quantity',
        'i.reserved_quantity'
      )
      .orderBy('s.priority_class')
      .orderBy('l.node_code');
    return ctx.response.ok({ data: inventory });
  }

  async showInventory(ctx: HttpContext) {
    const inventory = await db
      .from('inventory as i')
      .join('supply_items as s', 's.id', 'i.supply_item_id')
      .where('i.location_id', ctx.params.locationId)
      .select(
        's.*',
        'i.quantity',
        'i.reserved_quantity',
        'i.crdt_vector_clock',
        'i.last_synced_at'
      );
    return ctx.response.ok({ data: inventory });
  }

  async updateStock(ctx: HttpContext, payload: UpdateStockType) {
    const { locationId, itemId } = ctx.params;
    const existing = await db
      .from('inventory')
      .where('location_id', locationId)
      .where('supply_item_id', itemId)
      .first();

    if (!existing) {
      await db.table('inventory').insert({
        location_id: locationId,
        supply_item_id: itemId,
        quantity: payload.quantity,
        reserved_quantity: 0,
        crdt_vector_clock: JSON.stringify(payload.crdt_vector_clock ?? {}),
        last_updated_node: payload.last_updated_node ?? null,
        last_synced_at: new Date(),
        updated_at: new Date(),
      });
      return ctx.response.created({ message: 'Stock entry created', quantity: payload.quantity });
    }

    await db
      .from('inventory')
      .where('location_id', locationId)
      .where('supply_item_id', itemId)
      .update({
        quantity: payload.quantity,
        crdt_vector_clock: JSON.stringify(payload.crdt_vector_clock ?? {}),
        last_updated_node: payload.last_updated_node,
        last_synced_at: new Date(),
        updated_at: new Date(),
      });
    return ctx.response.ok({ message: 'Stock updated', quantity: payload.quantity });
  }
}
