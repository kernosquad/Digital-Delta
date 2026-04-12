import { BaseSchema } from '@adonisjs/lucid/schema';

/**
 * Group 3 — Fleet
 * Tables: vehicles
 *
 * Offline sync: PARTIAL — the vehicle assigned to the logged-in operator is
 *               synced to their local SQLite. Full fleet list is server-only.
 * Covers: Module 4 (M4.3 Vehicle Constraints), Module 8 (Drone Handoff)
 */
export default class extends BaseSchema {
  async up() {
    // --------------------------------------------------------------- vehicles
    // Trucks (road only), speedboats (river only), drones (airway only).
    // battery_level and fuel_level are updated in near-real-time via CRDT sync.
    this.schema.createTable('vehicles', (table) => {
      table.increments('id').notNullable();
      table.string('name', 100).notNullable();
      table.enum('type', ['truck', 'speedboat', 'drone']).notNullable();
      table.string('identifier', 50).notNullable().unique(); // license plate / drone ID
      table.decimal('max_payload_kg', 8, 2).notNullable();
      table.decimal('battery_level', 5, 2).nullable(); // 0–100, drones only
      table.decimal('fuel_level', 5, 2).nullable(); // 0–100, trucks/speedboats
      table
        .enum('status', ['idle', 'in_mission', 'maintenance', 'offline'])
        .notNullable()
        .defaultTo('idle');
      table
        .integer('current_location_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('locations')
        .onDelete('SET NULL');
      table
        .integer('operator_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('users')
        .onDelete('SET NULL');
      table.datetime('created_at').notNullable();
      table.datetime('updated_at').nullable();

      table.index(['type', 'status'], 'idx_vehicles_type_status');
      table.index(['operator_id'], 'idx_vehicles_operator');
      table.index(['current_location_id'], 'idx_vehicles_location');
    });
  }

  async down() {
    this.schema.dropTableIfExists('vehicles');
  }
}
