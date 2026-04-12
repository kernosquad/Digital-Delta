import { BaseSchema } from '@adonisjs/lucid/schema';

/**
 * Group 9 — Drone Handoffs & Autonomous Triage Decisions
 * Tables: handoff_events, triage_decisions
 *
 * Offline sync: NO (server-computed and server-recorded; pushed to mobile as mission updates)
 * Covers: Module 8 (M8.1 Reachability, M8.2 Rendezvous, M8.3 Handoff PoD, M8.4 Throttling)
 *         Module 6 (M6.2 SLA Breach Prediction, M6.3 Autonomous Drop-and-Reroute)
 */
export default class extends BaseSchema {
  async up() {
    // --------------------------------------------------------- handoff_events
    // Records a ground-vehicle ↔ drone payload transfer event (M8.2 + M8.3).
    // The engine computes the optimal rendezvous lat/lng (may differ from a fixed
    // location node) using M8.2 logic, then a PoD receipt is generated on handoff.
    this.schema.createTable('handoff_events', (table) => {
      table.increments('id').notNullable();
      table
        .integer('mission_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('missions')
        .onDelete('CASCADE');
      table
        .integer('drone_vehicle_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('vehicles')
        .onDelete('RESTRICT');
      table
        .integer('ground_vehicle_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('vehicles')
        .onDelete('RESTRICT');
      // Nearest named node used as meeting point (may be null for open-field rendezvous)
      table
        .integer('rendezvous_location_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('locations')
        .onDelete('SET NULL');
      // Precise GPS coordinates computed by M8.2 (may differ from node centre)
      table.decimal('rendezvous_lat', 10, 7).notNullable();
      table.decimal('rendezvous_lng', 10, 7).notNullable();
      table
        .enum('status', ['scheduled', 'in_progress', 'completed', 'failed'])
        .notNullable()
        .defaultTo('scheduled');
      // PoD receipt generated at handoff moment (M8.3 ties into Module 5)
      table
        .bigInteger('delivery_receipt_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('delivery_receipts')
        .onDelete('SET NULL');
      table.datetime('scheduled_at').notNullable();
      table.datetime('completed_at').nullable();
      table.datetime('created_at').notNullable();

      table.index(['mission_id'], 'idx_handoff_mission');
      table.index(['drone_vehicle_id', 'status'], 'idx_handoff_drone_status');
      table.index(['ground_vehicle_id', 'status'], 'idx_handoff_ground_status');
    });

    // ------------------------------------------------------- triage_decisions
    // Immutable log of every autonomous rerouting/preemption decision (M6.2 + M6.3).
    // old_route / new_route: JSON arrays of route leg IDs for before/after.
    // preempted_mission_id: the mission that was dropped to free the vehicle for
    // a higher-priority run.
    this.schema.createTable('triage_decisions', (table) => {
      table.increments('id').notNullable();
      table
        .integer('mission_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('missions')
        .onDelete('CASCADE');
      table
        .enum('triggered_by', [
          'sla_breach_predicted',
          'sla_breached',
          'route_failure',
          'priority_preemption',
          'ml_high_risk',
          'manual_override',
        ])
        .notNullable();
      table.json('old_route').nullable(); // array of route_id integers
      table.json('new_route').nullable(); // array of route_id integers
      table.text('rationale').notNullable(); // human-readable decision explanation
      table
        .integer('preempted_mission_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('missions')
        .onDelete('SET NULL');
      table.datetime('created_at').notNullable();

      table.index(['mission_id', 'created_at'], 'idx_triage_mission_time');
      table.index(['triggered_by', 'created_at'], 'idx_triage_trigger_time');
    });
  }

  async down() {
    this.schema.dropTableIfExists('triage_decisions');
    this.schema.dropTableIfExists('handoff_events');
  }
}
