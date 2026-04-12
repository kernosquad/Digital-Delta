import { BaseSeeder } from '@adonisjs/lucid/seeders'
import { DateTime } from 'luxon'

import Location from '#models/location'
import Route from '#models/route'
import RouteMLPrediction from '#models/route_ml_prediction'
import SensorReading from '#models/sensor_reading'

/**
 * Seed realistic sensor readings and ML route predictions (Module 7).
 *
 * M7.1 — Rainfall ingestion: simulated sensor readings (water level, rainfall, soil)
 * M7.2 — Impassability model: gradient-boosting predictions for each route edge
 * M7.3 — Proactive rerouting: edges with impassabilityProb > 0.7 flagged as critical
 * M7.4 — Prediction confidence display data
 *
 * Sensor placement:
 *   - Water level gauges at each location node
 *   - Rainfall gauges at N1 (city), N2 (camp), N5 (drone base)
 *   - Soil moisture sensors along major road corridors
 */
export default class SensorMlSeeder extends BaseSeeder {
  async run() {
    const now = DateTime.now()

    const locations = await Location.all()
    const routes = await Route.all()

    const locationMap = new Map(locations.map((l) => [l.nodeCode, l]))

    // ── Water level sensor readings (6 hourly readings per location) ──────────
    const sensorRows: {
      locationId: number
      readingType: 'water_level_cm' | 'rainfall_mm' | 'soil_saturation_pct'
      value: number
      source: 'sensor' | 'mock_api' | 'manual'
      recordedAt: DateTime
      createdAt: DateTime
    }[] = []

    const waterLevels: Record<string, { level: number; trend: string }> = {
      N1: { level: 3.2, trend: 'stable' },
      N2: { level: 5.8, trend: 'rising' },
      N3: { level: 2.9, trend: 'stable' },
      N4: { level: 9.4, trend: 'rising' }, // flooded zone
      N5: { level: 4.1, trend: 'stable' },
      N6: { level: 3.7, trend: 'falling' },
    }

    for (const [code, data] of Object.entries(waterLevels)) {
      const loc = locationMap.get(code)
      if (!loc) continue

      for (let i = 5; i >= 0; i--) {
        const variation = (Math.random() - 0.5) * 0.4
        const trendDelta =
          data.trend === 'rising' ? i * -0.15 : data.trend === 'falling' ? i * 0.1 : 0
        sensorRows.push({
          locationId: loc.id,
          readingType: 'water_level_cm',
          value: Math.max(0, data.level + variation + trendDelta),
          source: i === 0 ? 'sensor' : 'mock_api',
          recordedAt: now.minus({ hours: i }),
          createdAt: now.minus({ hours: i }),
        })
      }
    }

    // ── Rainfall readings (24 hourly readings for N1, N2, N5) ─────────────────
    const rainfallNodes = ['N1', 'N2', 'N5']
    const rainfallRates: Record<string, number> = { N1: 12.3, N2: 18.7, N5: 9.1 }

    for (const code of rainfallNodes) {
      const loc = locationMap.get(code)
      if (!loc) continue

      for (let i = 23; i >= 0; i--) {
        const variation = Math.random() * 5
        sensorRows.push({
          locationId: loc.id,
          readingType: 'rainfall_mm',
          value: Math.max(0, rainfallRates[code] + variation - (i > 6 ? 3 : 0)),
          source: 'mock_api',
          recordedAt: now.minus({ hours: i }),
          createdAt: now.minus({ hours: i }),
        })
      }
    }

    // ── Soil saturation readings (6 readings per node, every 4 hours) ──────────
    const soilNodes: Record<string, number> = { N1: 0.52, N2: 0.78, N3: 0.49, N4: 0.93, N5: 0.61 }

    for (const [code, baseSat] of Object.entries(soilNodes)) {
      const loc = locationMap.get(code)
      if (!loc) continue

      for (let i = 5; i >= 0; i--) {
        const variation = (Math.random() - 0.3) * 0.06
        sensorRows.push({
          locationId: loc.id,
          readingType: 'soil_saturation_pct',
          value: Math.min(1, Math.max(0, baseSat + variation)),
          source: 'sensor',
          recordedAt: now.minus({ hours: i * 4 }),
          createdAt: now.minus({ hours: i * 4 }),
        })
      }
    }

    await SensorReading.createMany(sensorRows)

    // ── ML Route Predictions (M7.2) ───────────────────────────────────────────
    // Predictions computed by simulated GradientBoost model.
    // riskLevel derived from impassabilityProb:
    //   < 0.25 → low | 0.25–0.5 → medium | 0.5–0.75 → high | > 0.75 → critical
    const edgePredictions: Record<
      string,
      {
        impassabilityProb: number
        travelMins: number
        features: Record<string, number>
        contributingFactors: string[]
      }
    > = {
      E1: {
        impassabilityProb: 0.38,
        travelMins: 55,
        features: {
          cumulative_rainfall_mm: 245,
          water_level_delta: 1.2,
          soil_saturation: 0.65,
          elevation_proxy: 4.2,
          route_type_road: 1,
        },
        contributingFactors: ['Moderate rainfall accumulation', 'Slight water rise'],
      },
      E2: {
        impassabilityProb: 0.12,
        travelMins: 30,
        features: {
          cumulative_rainfall_mm: 185,
          water_level_delta: 0.3,
          soil_saturation: 0.51,
          elevation_proxy: 5.8,
          route_type_road: 1,
        },
        contributingFactors: ['Low risk — urban road, good drainage'],
      },
      E3: {
        impassabilityProb: 0.82,
        travelMins: 150,
        features: {
          cumulative_rainfall_mm: 380,
          water_level_delta: 4.1,
          soil_saturation: 0.93,
          elevation_proxy: 1.1,
          route_type_river: 1,
        },
        contributingFactors: [
          'Active flood zone',
          'Rapid water-level rise (4.1m delta)',
          'Critical soil saturation (93%)',
        ],
      },
      E4: {
        impassabilityProb: 0.29,
        travelMins: 65,
        features: {
          cumulative_rainfall_mm: 210,
          water_level_delta: 0.8,
          soil_saturation: 0.56,
          elevation_proxy: 4.5,
          route_type_road: 1,
        },
        contributingFactors: ['Acceptable risk — slight degradation expected'],
      },
      E5: {
        impassabilityProb: 0.08,
        travelMins: 20,
        features: {
          cumulative_rainfall_mm: 180,
          water_level_delta: 0.2,
          soil_saturation: 0.42,
          elevation_proxy: 8.0,
          route_type_airway: 1,
        },
        contributingFactors: ['Low risk — airway route, wind speed nominal'],
      },
      E6: {
        impassabilityProb: 0.11,
        travelMins: 25,
        features: {
          cumulative_rainfall_mm: 175,
          water_level_delta: 0.4,
          soil_saturation: 0.45,
          elevation_proxy: 7.5,
          route_type_airway: 1,
        },
        contributingFactors: ['Low risk — airway route'],
      },
      E7: {
        impassabilityProb: 0.44,
        travelMins: 75,
        features: {
          cumulative_rainfall_mm: 260,
          water_level_delta: 1.5,
          soil_saturation: 0.69,
          elevation_proxy: 3.8,
          route_type_road: 1,
        },
        contributingFactors: ['Elevated rainfall — monitor closely', 'Road surface degrading'],
      },
    }

    const mlRows: {
      routeId: number
      impassabilityProb: number
      predictedTravelMins: number
      riskLevel: 'low' | 'medium' | 'high' | 'critical'
      featuresSnapshot: Record<string, unknown>
      modelVersion: string
      isActive: boolean
      predictedAt: DateTime
      createdAt: DateTime
    }[] = []

    for (const route of routes) {
      const pred = edgePredictions[route.edgeCode]
      if (!pred) continue

      const riskLevel =
        pred.impassabilityProb < 0.25
          ? ('low' as const)
          : pred.impassabilityProb < 0.5
            ? ('medium' as const)
            : pred.impassabilityProb < 0.75
              ? ('high' as const)
              : ('critical' as const)

      mlRows.push({
        routeId: route.id,
        impassabilityProb: pred.impassabilityProb,
        predictedTravelMins: pred.travelMins,
        riskLevel,
        featuresSnapshot: { ...pred.features, contributing_factors: pred.contributingFactors },
        modelVersion: 'GradientBoost-v1.2.0',
        isActive: true,
        predictedAt: now,
        createdAt: now,
      })
    }

    if (mlRows.length > 0) {
      await RouteMLPrediction.createMany(mlRows)
    }
  }
}
