import { BaseSchema } from '@adonisjs/lucid/schema';

/**
 * Group 5 — Missions
 * Tables: missions, mission_cargo, mission_route_legs
 *
 * Offline sync: YES (missions assigned to the current user are synced to SQLite)
 * Covers: Module 4 (VRP routing legs), Module 6 (M6.1–M6.3 triage & preemption)
 *         Module 5 (PoD — delivery_receipts links back to mission_id)
 */
export default class extends BaseSchema {
  async up() {
    // --------------------------------------------------------------- missions
    // A mission = one vehicle delivering cargo from origin → destination.
    // preempted_by_mission_id: when a higher-priority mission forces this one to
    // pause/drop cargo at a safe waypoint (M6.3 autonomous drop-and-reroute).
    this.schema.createTable('missions', (table) => {
      table.increments('id').notNullable();
      table.string('mission_code', 50).notNullable().unique(); // e.g. "MSN-2026-0042"
      table
        .enum('status', [
          'planned',
          'active',
          'paused',
          'completed',
          'failed',
          'preempted',
          'cancelled',
        ])
        .notNullable()
        .defaultTo('planned');
      table
        .enum('priority_class', ['p0_critical', 'p1_high', 'p2_standard', 'p3_low'])
        .notNullable()
        .defaultTo('p2_standard');
      table
        .integer('origin_location_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('locations')
        .onDelete('RESTRICT');
      table
        .integer('destination_location_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('locations')
        .onDelete('RESTRICT');
      table
        .integer('vehicle_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('vehicles')
        .onDelete('RESTRICT');
      table
        .integer('driver_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('users')
        .onDelete('SET NULL');
      table.decimal('total_payload_kg', 8, 2).notNullable().defaultTo(0);
      table.datetime('sla_deadline').notNullable();
      table.boolean('sla_breached').notNullable().defaultTo(false);
      table.datetime('estimated_arrival').nullable(); // ETA from VRP engine
      table.datetime('actual_arrival').nullable();
      table.text('preemption_reason').nullable();
      // Self-referencing FK: which higher-priority mission caused preemption
      table.integer('preempted_by_mission_id').unsigned().nullable();
      table
        .integer('created_by_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('users')
        .onDelete('SET NULL');
      table.text('notes').nullable();
      table.datetime('created_at').notNullable();
      table.datetime('updated_at').nullable();

      // Self-referencing FK defined after all columns
      table
        .foreign('preempted_by_mission_id')
        .references('id')
        .inTable('missions')
        .onDelete('SET NULL');

      table.index(['status', 'priority_class'], 'idx_missions_status_priority');
      table.index(['vehicle_id', 'status'], 'idx_missions_vehicle_status');
      table.index(['driver_id', 'status'], 'idx_missions_driver_status');
      table.index(['destination_location_id'], 'idx_missions_destination');
      table.index(['sla_deadline', 'sla_breached'], 'idx_missions_sla');
    });

    // --------------------------------------------------------- mission_cargo
    // Line items carried in a mission. Links supply_items to missions.
    this.schema.createTable('mission_cargo', (table) => {
      table.increments('id').notNullable();
      table
        .integer('mission_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('missions')
        .onDelete('CASCADE');
      table
        .integer('supply_item_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('supply_items')
        .onDelete('RESTRICT');
      table.decimal('quantity', 10, 3).notNullable();
      table.decimal('delivered_quantity', 10, 3).notNullable().defaultTo(0);
      table.datetime('created_at').notNullable();

      table.unique(['mission_id', 'supply_item_id'], {
        indexName: 'uq_mission_cargo_mission_item',
      });
    });

    // ----------------------------------------------------- mission_route_legs
    // Ordered route segments computed by the VRP engine (M4).
    // Each leg = one edge (route) in the network graph.
    // On route failure, the engine marks affected legs 'skipped' and inserts
    // new legs for the recalculated path.
    this.schema.createTable('mission_route_legs', (table) => {
      table.increments('id').notNullable();
      table
        .integer('mission_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('missions')
        .onDelete('CASCADE');
      table.tinyint('seq_order').unsigned().notNullable(); // 1-based ordering
      table
        .integer('from_location_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('locations')
        .onDelete('RESTRICT');
      table
        .integer('to_location_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('locations')
        .onDelete('RESTRICT');
      table
        .integer('route_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('routes')
        .onDelete('RESTRICT');
      table.integer('estimated_mins').unsigned().notNullable();
      table
        .enum('status', ['pending', 'active', 'completed', 'skipped'])
        .notNullable()
        .defaultTo('pending');
      table.datetime('created_at').notNullable();
      table.datetime('updated_at').nullable();

      table.index(['mission_id', 'seq_order'], 'idx_mrl_mission_seq');
      table.index(['route_id'], 'idx_mrl_route');
    });
  }

  async down() {
    this.schema.dropTableIfExists('mission_route_legs');
    this.schema.dropTableIfExists('mission_cargo');
    this.schema.dropTableIfExists('missions');
  }
}
