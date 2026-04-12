import { BaseSchema } from '@adonisjs/lucid/schema';

/**
 * Group 2 — Network Graph (Nodes & Edges)
 * Tables: locations, routes, route_condition_logs
 *
 * Offline sync: YES — locations + routes are fully cached on mobile SQLite
 *               route_condition_logs is server-only (too large; ML predictions used offline instead)
 * Covers: Module 4 (M4.1 Graph Representation, M4.2 Dynamic Rerouting, M4.3 Vehicle Constraints)
 *         Module 7 (route decay prediction feeds into current_travel_mins)
 */
export default class extends BaseSchema {
  async up() {
    // ------------------------------------------------------------ locations
    // Network nodes: camps, hubs, hospitals, waypoints, supply drops.
    // Mirrors the `nodes` array in sylhet_map.json.
    this.schema.createTable('locations', (table) => {
      table.increments('id').notNullable();
      table.string('node_code', 20).notNullable().unique(); // e.g. "N1", "N2"
      table.string('name', 150).notNullable();
      table
        .enum('type', [
          'central_command',
          'supply_drop',
          'relief_camp',
          'waypoint',
          'hospital',
          'drone_base',
        ])
        .notNullable();
      table.decimal('latitude', 10, 7).notNullable();
      table.decimal('longitude', 10, 7).notNullable();
      table.boolean('is_active').notNullable().defaultTo(true);
      table.boolean('is_flooded').notNullable().defaultTo(false);
      table.integer('capacity').unsigned().nullable(); // max persons (camps/hospitals)
      table.integer('current_occupancy').unsigned().notNullable().defaultTo(0);
      table.text('notes').nullable();
      table.datetime('created_at').notNullable();
      table.datetime('updated_at').nullable();

      table.index(['type', 'is_active'], 'idx_locations_type_active');
      table.index(['is_flooded'], 'idx_locations_flooded');
      table.index(['latitude', 'longitude'], 'idx_locations_coords');
    });

    // --------------------------------------------------------------- routes
    // Network edges: roads, rivers, airways between locations.
    // Mirrors the `edges` array in sylhet_map.json.
    // current_travel_mins is updated live by the chaos engine and ML predictions.
    this.schema.createTable('routes', (table) => {
      table.increments('id').notNullable();
      table.string('edge_code', 20).notNullable().unique(); // e.g. "E1", "E7"
      table
        .integer('source_location_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('locations')
        .onDelete('RESTRICT');
      table
        .integer('target_location_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('locations')
        .onDelete('RESTRICT');
      table.enum('route_type', ['road', 'river', 'airway']).notNullable();
      table.integer('base_travel_mins').unsigned().notNullable(); // static baseline
      table.integer('current_travel_mins').unsigned().notNullable(); // live (updated by chaos/ML)
      table.boolean('is_flooded').notNullable().defaultTo(false);
      table.boolean('is_blocked').notNullable().defaultTo(false);
      table.decimal('risk_score', 4, 3).notNullable().defaultTo(0.0); // 0.000–1.000
      table.decimal('max_payload_kg', 8, 2).nullable(); // weight limit for this edge
      // JSON array of allowed vehicle types: ["truck","speedboat","drone"]
      table.json('allowed_vehicles').nullable();
      table.datetime('created_at').notNullable();
      table.datetime('updated_at').nullable();

      table.index(['source_location_id', 'target_location_id'], 'idx_routes_source_target');
      table.index(['route_type', 'is_flooded', 'is_blocked'], 'idx_routes_type_status');
      table.index(['risk_score'], 'idx_routes_risk');
    });

    // ------------------------------------------------- route_condition_logs
    // Immutable history of every route-weight or flood-status change.
    // Source of truth for audit trail and ML training data.
    this.schema.createTable('route_condition_logs', (table) => {
      table.bigIncrements('id').notNullable();
      table
        .integer('route_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('routes')
        .onDelete('CASCADE');
      table
        .integer('changed_by_user_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('users')
        .onDelete('SET NULL'); // NULL = system / ML trigger
      table.integer('old_travel_mins').unsigned().notNullable();
      table.integer('new_travel_mins').unsigned().notNullable();
      table.decimal('old_risk_score', 4, 3).notNullable();
      table.decimal('new_risk_score', 4, 3).notNullable();
      table.boolean('is_flooded').notNullable();
      table
        .enum('reason', ['flood', 'recede', 'ml_prediction', 'manual_override', 'chaos_engine'])
        .notNullable();
      table.datetime('created_at').notNullable();

      table.index(['route_id', 'created_at'], 'idx_rcl_route_time');
      table.index(['reason', 'created_at'], 'idx_rcl_reason_time');
    });
  }

  async down() {
    this.schema.dropTableIfExists('route_condition_logs');
    this.schema.dropTableIfExists('routes');
    this.schema.dropTableIfExists('locations');
  }
}
