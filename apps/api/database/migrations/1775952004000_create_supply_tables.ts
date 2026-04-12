import { BaseSchema } from '@adonisjs/lucid/schema';

/**
 * Group 4 — Supplies & Inventory
 * Tables: supply_items, inventory
 *
 * Offline sync: YES (both tables synced to mobile SQLite)
 *   - supply_items: read-only catalog cache
 *   - inventory: CRDT-synced (LWW-Register + G-Counter hybrid)
 * Covers: Module 2 (M2.1 CRDT Data Model), Module 6 (M6.1 Priority Taxonomy)
 */
export default class extends BaseSchema {
  async up() {
    // ---------------------------------------------------------- supply_items
    // Catalog of relief supply types. Static reference data — seeded once.
    // priority_class and sla_hours define the M6 triage taxonomy:
    //   P0 Critical (medical antivenom) → 2 hrs
    //   P1 High (medicine/water)       → 6 hrs
    //   P2 Standard (food/shelter)     → 24 hrs
    //   P3 Low (equipment/misc)        → 72 hrs
    this.schema.createTable('supply_items', (table) => {
      table.increments('id').notNullable();
      table.string('name', 150).notNullable();
      table
        .enum('category', ['medical', 'food', 'water', 'shelter', 'equipment', 'other'])
        .notNullable();
      table.string('unit', 50).notNullable(); // kg, liters, pcs, boxes
      table.decimal('weight_per_unit_kg', 8, 3).notNullable().defaultTo(0);
      table
        .enum('priority_class', ['p0_critical', 'p1_high', 'p2_standard', 'p3_low'])
        .notNullable()
        .defaultTo('p2_standard');
      table.integer('sla_hours').unsigned().notNullable(); // max acceptable delivery time
      table.datetime('created_at').notNullable();
      table.datetime('updated_at').nullable();

      table.index(['priority_class'], 'idx_supply_items_priority');
      table.index(['category'], 'idx_supply_items_category');
    });

    // --------------------------------------------------------------- inventory
    // Current stock of each supply_item at each location.
    // Uses CRDT for offline-safe concurrent updates:
    //   crdt_vector_clock — JSON map of { node_uuid: counter } for causal ordering
    //   last_updated_node — which device performed the last write (LWW tiebreak)
    // On merge conflict: vector clock determines winner; server logs to sync_conflicts.
    this.schema.createTable('inventory', (table) => {
      table.increments('id').notNullable();
      table
        .integer('location_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('locations')
        .onDelete('CASCADE');
      table
        .integer('supply_item_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('supply_items')
        .onDelete('CASCADE');
      table.decimal('quantity', 10, 3).notNullable().defaultTo(0);
      table.decimal('reserved_quantity', 10, 3).notNullable().defaultTo(0); // locked for active missions
      table.json('crdt_vector_clock').nullable(); // { "node-uuid": counter, ... }
      table.string('last_updated_node', 100).nullable(); // node_uuid of last writer
      table.datetime('last_synced_at').nullable();
      table.datetime('updated_at').nullable();

      table.unique(['location_id', 'supply_item_id'], {
        indexName: 'uq_inventory_location_item',
      });
      table.index(['supply_item_id', 'quantity'], 'idx_inventory_item_qty');
      table.index(['location_id'], 'idx_inventory_location');
    });
  }

  async down() {
    this.schema.dropTableIfExists('inventory');
    this.schema.dropTableIfExists('supply_items');
  }
}
