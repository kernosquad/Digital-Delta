import { BaseSchema } from '@adonisjs/lucid/schema';

/**
 * Group 8 — Environmental Sensors & ML Predictions
 * Tables: sensor_readings, route_ml_predictions
 *
 * Offline sync:
 *   sensor_readings      → NO  (server ingests; mobile reads latest snapshot)
 *   route_ml_predictions → PARTIAL (latest active prediction per route is cached on mobile)
 *
 * Covers: Module 7 (M7.1 Rainfall Ingestion, M7.2 Impassability Classifier,
 *                   M7.3 Proactive Rerouting, M7.4 Confidence Display)
 */
export default class extends BaseSchema {
  async up() {
    // ------------------------------------------------------ sensor_readings
    // Time-series environmental data ingested at 1 Hz or higher (M7.1).
    // Feeds the feature engineering pipeline for the ML model.
    // location_id links the reading to the nearest network node.
    this.schema.createTable('sensor_readings', (table) => {
      table.bigIncrements('id').notNullable();
      table
        .integer('location_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('locations')
        .onDelete('RESTRICT');
      table
        .enum('reading_type', [
          'rainfall_mm',
          'water_level_cm',
          'wind_speed_kmh',
          'soil_saturation_pct',
          'temperature_c',
        ])
        .notNullable();
      table.decimal('value', 10, 4).notNullable();
      table.datetime('recorded_at').notNullable(); // sensor timestamp
      table.enum('source', ['sensor', 'mock_api', 'manual']).notNullable().defaultTo('sensor');
      table.datetime('created_at').notNullable();

      // Composite: most queries filter by location + type + time range
      table.index(['location_id', 'reading_type', 'recorded_at'], 'idx_sensor_loc_type_time');
      table.index(['recorded_at'], 'idx_sensor_time');
    });

    // ------------------------------------------------- route_ml_predictions
    // Output of the impassability classification model (M7.2).
    // One row per prediction run per route.
    // is_active = true marks the latest prediction (used by VRP engine + mobile cache).
    // features_snapshot: JSON of the exact feature vector used — required for M7.4 display.
    // model_version: tracks which model checkpoint produced this prediction.
    this.schema.createTable('route_ml_predictions', (table) => {
      table.bigIncrements('id').notNullable();
      table
        .integer('route_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('routes')
        .onDelete('CASCADE');
      table.datetime('predicted_at').notNullable();
      table.decimal('impassability_prob', 5, 4).notNullable(); // 0.0000–1.0000
      table.integer('predicted_travel_mins').unsigned().notNullable();
      table.enum('risk_level', ['low', 'medium', 'high', 'critical']).notNullable();
      table.json('features_snapshot').notNullable(); // feature vector at prediction time (M7.4)
      table.string('model_version', 50).notNullable(); // e.g. "v1.2-logistic"
      // When a new prediction is made, previous row is set is_active = false
      table.boolean('is_active').notNullable().defaultTo(true);
      table.datetime('created_at').notNullable();

      table.index(['route_id', 'is_active'], 'idx_ml_pred_route_active');
      table.index(['predicted_at'], 'idx_ml_pred_time');
      table.index(['impassability_prob'], 'idx_ml_pred_prob');
      table.index(['risk_level', 'is_active'], 'idx_ml_pred_risk_active');
    });
  }

  async down() {
    this.schema.dropTableIfExists('route_ml_predictions');
    this.schema.dropTableIfExists('sensor_readings');
  }
}
