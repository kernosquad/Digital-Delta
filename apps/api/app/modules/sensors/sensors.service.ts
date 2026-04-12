import db from '@adonisjs/lucid/services/db';

import type { IngestSensorType } from './sensors.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

import { EventBus } from '#services/event_bus';

export class SensorsService {
  async ingest(ctx: HttpContext, payload: IngestSensorType) {
    const { response } = ctx;

    const rows = payload.readings.map((r) => ({
      location_id: r.location_id,
      reading_type: r.reading_type,
      value: r.value,
      recorded_at: new Date(r.recorded_at),
      source: r.source ?? 'sensor',
      created_at: new Date(),
    }));

    await db.table('sensor_readings').multiInsert(rows);

    EventBus.publish('sensor_update', { count: payload.readings.length });

    return response.created({ inserted: rows.length });
  }

  async readings(ctx: HttpContext) {
    const { request, response } = ctx;

    const locationId = request.input('location_id');
    const type = request.input('type');
    const since = request.input('since');

    const query = db.from('sensor_readings').orderBy('recorded_at', 'desc').limit(500);

    if (locationId) query.where('location_id', locationId);
    if (type) query.where('reading_type', type);
    if (since) query.where('recorded_at', '>', new Date(since));

    const data = await query;

    return response.ok({ data });
  }

  async predictions(ctx: HttpContext) {
    const { response } = ctx;

    const data = await db
      .from('route_ml_predictions as p')
      .join('routes as r', 'r.id', 'p.route_id')
      .where('p.is_active', true)
      .select('p.*', 'r.edge_code')
      .orderBy('p.impassability_prob', 'desc');

    return response.ok({ data });
  }

  async prediction(ctx: HttpContext) {
    const { params, response } = ctx;

    const prediction = await db
      .from('route_ml_predictions as p')
      .join('routes as r', 'r.id', 'p.route_id')
      .where('p.route_id', params.routeId)
      .where('p.is_active', true)
      .select('p.*', 'r.edge_code')
      .orderBy('p.predicted_at', 'desc')
      .first();

    if (!prediction) {
      return response.notFound({ message: 'No active prediction found for this route' });
    }

    return response.ok(prediction);
  }
}
