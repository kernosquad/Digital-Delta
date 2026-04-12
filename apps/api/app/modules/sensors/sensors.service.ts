import db from '@adonisjs/lucid/services/db'

import type { IngestSensorType } from './sensors.validator.js'
import type { HttpContext } from '@adonisjs/core/http'

import { EventBus } from '#services/event_bus'

export class SensorsService {
  async ingest(ctx: HttpContext, payload: IngestSensorType) {
    const { response } = ctx

    const rows = payload.readings.map((r) => ({
      location_id: r.location_id,
      reading_type: r.reading_type,
      value: r.value,
      recorded_at: new Date(r.recorded_at),
      source: r.source ?? 'sensor',
      created_at: new Date(),
    }))

    await db.table('sensor_readings').multiInsert(rows)

    EventBus.publish('sensor_update', { count: payload.readings.length })

    return response.status(201).sendFormatted({ inserted: rows.length })
  }

  async readings(ctx: HttpContext) {
    const { request, response } = ctx

    const locationId = request.input('location_id')
    const type = request.input('type')
    const since = request.input('since')

    const query = db.from('sensor_readings').orderBy('recorded_at', 'desc').limit(500)

    if (locationId) query.where('location_id', locationId)
    if (type) query.where('reading_type', type)
    if (since) query.where('recorded_at', '>', new Date(since))

    const data = await query

    return response.sendFormatted(data)
  }

  async predictions(ctx: HttpContext) {
    const { response } = ctx

    const data = await db
      .from('route_ml_predictions as p')
      .join('routes as r', 'r.id', 'p.route_id')
      .where('p.is_active', true)
      .select('p.*', 'r.edge_code')
      .orderBy('p.impassability_prob', 'desc')

    return response.sendFormatted(data)
  }

  // M7.1 — Rainfall feature engineering per route edge
  async rainfallFeatures(ctx: HttpContext) {
    const { response } = ctx

    const since = new Date(Date.now() - 2 * 3_600_000) // last 2 hours
    const readings = await db
      .from('sensor_readings')
      .where('recorded_at', '>', since)
      .whereIn('reading_type', ['rainfall_mm', 'water_level_cm', 'soil_saturation_pct'])
      .orderBy('recorded_at', 'asc')

    // Group by location
    const byLocation = new Map<
      number,
      { rainfall: number[]; water_level: number[]; soil_sat: number[] }
    >()
    for (const r of readings) {
      if (!byLocation.has(r.location_id)) {
        byLocation.set(r.location_id, { rainfall: [], water_level: [], soil_sat: [] })
      }
      const loc = byLocation.get(r.location_id)!
      if (r.reading_type === 'rainfall_mm') loc.rainfall.push(Number(r.value))
      else if (r.reading_type === 'water_level_cm') loc.water_level.push(Number(r.value))
      else if (r.reading_type === 'soil_saturation_pct') loc.soil_sat.push(Number(r.value))
    }

    const routes = await db
      .from('routes')
      .select(
        'id',
        'edge_code',
        'route_type',
        'source_location_id',
        'current_travel_mins',
        'is_flooded'
      )

    const features = routes.map((route) => {
      const src = byLocation.get(route.source_location_id) ?? {
        rainfall: [],
        water_level: [],
        soil_sat: [],
      }
      const cumRainfall = src.rainfall.reduce((s: number, v: number) => s + v, 0)
      const rateOfChange =
        src.rainfall.length >= 2 ? src.rainfall[src.rainfall.length - 1] - src.rainfall[0] : 0
      const elevationProxy =
        route.route_type === 'road' ? 5.0 : route.route_type === 'river' ? 0.5 : 50.0

      return {
        route_id: route.id,
        edge_code: route.edge_code,
        route_type: route.route_type,
        is_flooded: route.is_flooded,
        features: {
          cumulative_rainfall_mm: Math.round(cumRainfall * 10) / 10,
          rate_of_change_mm_per_2h: Math.round(rateOfChange * 10) / 10,
          water_level_cm: Math.round((src.water_level.at(-1) ?? 0) * 10) / 10,
          soil_saturation_pct: Math.round((src.soil_sat.at(-1) ?? 0) * 10) / 10,
          elevation_proxy_m: elevationProxy,
          reading_count: src.rainfall.length,
        },
      }
    })

    return response.sendFormatted({
      computed_at: new Date().toISOString(),
      route_count: features.length,
      features,
    })
  }

  // M7.2 — Generate impassability predictions (logistic regression simulation)
  // M7.3 — Penalizes high-risk edges in routing engine (weight update)
  async generatePredictions(ctx: HttpContext) {
    const { response } = ctx
    const MODEL_VERSION = 'v1.0-logistic-sim'
    const SIGMOID = (x: number) => 1 / (1 + Math.exp(-x))
    // Weights: bias=-3.0, rainfall=2.5, water_level=2.0, soil_sat=1.5, risk_score=1.0
    const W = { bias: -3.0, rainfall: 2.5, water: 2.0, soil: 1.5, risk: 1.0 }

    const since = new Date(Date.now() - 2 * 3_600_000)
    const readings = await db
      .from('sensor_readings')
      .where('recorded_at', '>', since)
      .whereIn('reading_type', ['rainfall_mm', 'water_level_cm', 'soil_saturation_pct'])
      .orderBy('recorded_at', 'asc')

    const byLocation = new Map<number, { rainfall: number[]; water: number[]; soil: number[] }>()
    for (const r of readings) {
      if (!byLocation.has(r.location_id))
        byLocation.set(r.location_id, { rainfall: [], water: [], soil: [] })
      const loc = byLocation.get(r.location_id)!
      if (r.reading_type === 'rainfall_mm') loc.rainfall.push(Number(r.value))
      else if (r.reading_type === 'water_level_cm') loc.water.push(Number(r.value))
      else if (r.reading_type === 'soil_saturation_pct') loc.soil.push(Number(r.value))
    }

    const routes = await db
      .from('routes')
      .select(
        'id',
        'edge_code',
        'route_type',
        'source_location_id',
        'base_travel_mins',
        'is_flooded',
        'risk_score'
      )

    const now = new Date()
    const predictions: any[] = []

    for (const route of routes) {
      const loc = byLocation.get(route.source_location_id) ?? { rainfall: [], water: [], soil: [] }
      const cumRainfall = loc.rainfall.reduce((s: number, v: number) => s + v, 0)

      // Normalize features (max expected: rainfall=100mm, water=200cm, soil=100%)
      const fRainfall = Math.min(cumRainfall / 100.0, 1.0)
      const fWater = Math.min((loc.water.at(-1) ?? 0) / 200.0, 1.0)
      const fSoil = Math.min((loc.soil.at(-1) ?? 0) / 100.0, 1.0)
      const fRisk = Math.min((route.risk_score ?? 0) / 100.0, 1.0)

      const logit = route.is_flooded
        ? 3.5
        : W.bias + W.rainfall * fRainfall + W.water * fWater + W.soil * fSoil + W.risk * fRisk

      const prob = Math.round(SIGMOID(logit) * 10000) / 10000
      const riskLevel: 'low' | 'medium' | 'high' | 'critical' =
        prob < 0.3 ? 'low' : prob < 0.5 ? 'medium' : prob < 0.7 ? 'high' : 'critical'
      const predictedTravelMins = Math.round((route.base_travel_mins ?? 60) * (1 + prob * 2))

      const featuresSnapshot = {
        cumulative_rainfall_mm: Math.round(cumRainfall * 10) / 10,
        water_level_cm: Math.round((loc.water.at(-1) ?? 0) * 10) / 10,
        soil_saturation_pct: Math.round((loc.soil.at(-1) ?? 0) * 10) / 10,
        risk_score: route.risk_score ?? 0,
        is_currently_flooded: route.is_flooded,
        f_rainfall: Math.round(fRainfall * 1000) / 1000,
        f_water: Math.round(fWater * 1000) / 1000,
        f_soil: Math.round(fSoil * 1000) / 1000,
      }

      // Deactivate previous active prediction for this route
      await db
        .from('route_ml_predictions')
        .where('route_id', route.id)
        .where('is_active', true)
        .update({ is_active: false })

      await db.table('route_ml_predictions').insert({
        route_id: route.id,
        predicted_at: now,
        impassability_prob: prob,
        predicted_travel_mins: predictedTravelMins,
        risk_level: riskLevel,
        features_snapshot: JSON.stringify(featuresSnapshot),
        model_version: MODEL_VERSION,
        is_active: true,
        created_at: now,
      })

      // M7.3 — Penalize high-risk (>0.7) edges so Dijkstra avoids them
      if (prob > 0.7) {
        await db
          .from('routes')
          .where('id', route.id)
          .update({
            risk_score: Math.min(100, Math.round(prob * 100)),
            current_travel_mins: predictedTravelMins,
            updated_at: now,
          })
        EventBus.publish('route_update', {
          routeId: route.id,
          edgeCode: route.edge_code,
          riskLevel,
          impassabilityProb: prob,
          source: 'ml_prediction',
        })
      }

      predictions.push({
        route_id: route.id,
        edge_code: route.edge_code,
        impassability_prob: prob,
        risk_level: riskLevel,
        predicted_travel_mins: predictedTravelMins,
        features_snapshot: featuresSnapshot,
      })
    }

    const highRisk = predictions.filter((p) => p.impassability_prob > 0.7).length
    EventBus.publish('sensor_update', {
      event: 'ml_predictions_updated',
      count: routes.length,
      high_risk: highRisk,
    })

    return response.status(201).sendFormatted({
      metrics: {
        model_version: MODEL_VERSION,
        routes_evaluated: routes.length,
        high_risk_routes: highRisk,
        simulated_precision: 0.87,
        simulated_recall: 0.82,
        simulated_f1: 0.84,
        note: 'Metrics simulated. Real training requires labeled historical flood data.',
      },
      predictions,
    })
  }

  async prediction(ctx: HttpContext) {
    const { params, response } = ctx

    const prediction = await db
      .from('route_ml_predictions as p')
      .join('routes as r', 'r.id', 'p.route_id')
      .where('p.route_id', params.routeId)
      .where('p.is_active', true)
      .select('p.*', 'r.edge_code')
      .orderBy('p.predicted_at', 'desc')
      .first()

    if (!prediction) {
      return response.status(404).sendError('No active prediction found for this route')
    }

    return response.sendFormatted(prediction)
  }
}
