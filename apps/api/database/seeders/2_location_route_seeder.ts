import { BaseSeeder } from '@adonisjs/lucid/seeders';
import { DateTime } from 'luxon';

import Location from '#models/location';
import Route from '#models/route';

/**
 * Seed the Sylhet district disaster-response network graph.
 *
 * Nodes (N1–N6) and edges (E1–E7) mirror the `sylhet_map.json` topology
 * described in the HackFusion 2026 problem statement (Module 4).
 *
 * Real Sylhet co-ordinates used so the frontend map renders correctly.
 *
 *   N1  Central Command — Sylhet City (HQ)
 *   N2  Relief Camp Alpha — Companiganj
 *   N3  Shahjalal Hospital — Sylhet
 *   N4  Supply Drop — Sunamganj
 *   N5  Drone Base — Ratargul Wetland
 *   N6  Waypoint — Jaintiapur
 */
export default class LocationRouteSeeder extends BaseSeeder {
  async run() {
    // ── Locations ──────────────────────────────────────────────────────────
    const [n1, n2, n3, n4, n5, n6] = await Location.createMany([
      {
        nodeCode: 'N1',
        name: 'Central Command — Sylhet City',
        type: 'central_command',
        latitude: 24.8949,
        longitude: 91.8687,
        isActive: true,
        isFlooded: false,
        capacity: null,
        currentOccupancy: 0,
        notes: 'Disaster response HQ. Always online hub for sync operations.',
        createdAt: DateTime.now(),
      },
      {
        nodeCode: 'N2',
        name: 'Relief Camp Alpha — Companiganj',
        type: 'relief_camp',
        latitude: 24.994,
        longitude: 91.644,
        isActive: true,
        isFlooded: false,
        capacity: 3000,
        currentOccupancy: 1200,
        notes: 'Primary evacuation camp. River access available.',
        createdAt: DateTime.now(),
      },
      {
        nodeCode: 'N3',
        name: 'Shahjalal Hospital — Sylhet',
        type: 'hospital',
        latitude: 24.9045,
        longitude: 91.866,
        isActive: true,
        isFlooded: false,
        capacity: 500,
        currentOccupancy: 320,
        notes: 'Trauma centre. P0/P1 medical supply priority.',
        createdAt: DateTime.now(),
      },
      {
        nodeCode: 'N4',
        name: 'Supply Drop Point — Sunamganj',
        type: 'supply_drop',
        latitude: 25.0666,
        longitude: 91.3993,
        isActive: true,
        isFlooded: true,
        capacity: null,
        currentOccupancy: 0,
        notes: 'Partially flooded. River-only access currently.',
        createdAt: DateTime.now(),
      },
      {
        nodeCode: 'N5',
        name: 'Drone Base — Ratargul Wetland',
        type: 'drone_base',
        latitude: 25.0219,
        longitude: 91.9572,
        isActive: true,
        isFlooded: false,
        capacity: null,
        currentOccupancy: 0,
        notes: 'Drone launch/charging hub. Airway routes only.',
        createdAt: DateTime.now(),
      },
      {
        nodeCode: 'N6',
        name: 'Waypoint — Jaintiapur',
        type: 'waypoint',
        latitude: 25.1379,
        longitude: 92.1138,
        isActive: true,
        isFlooded: false,
        capacity: null,
        currentOccupancy: 0,
        notes: 'Road junction relay point.',
        createdAt: DateTime.now(),
      },
    ]);

    // ── Routes (edges) ─────────────────────────────────────────────────────
    await Route.createMany([
      {
        edgeCode: 'E1',
        sourceLocationId: n1.id,
        targetLocationId: n2.id,
        routeType: 'road',
        baseTravelMins: 90,
        currentTravelMins: 120, // degraded — partial flooding
        isFlooded: false,
        isBlocked: false,
        riskScore: 0.35,
        maxPayloadKg: 5000,
        allowedVehicles: ['truck'],
        createdAt: DateTime.now(),
      },
      {
        edgeCode: 'E2',
        sourceLocationId: n1.id,
        targetLocationId: n3.id,
        routeType: 'road',
        baseTravelMins: 25,
        currentTravelMins: 25,
        isFlooded: false,
        isBlocked: false,
        riskScore: 0.05,
        maxPayloadKg: 5000,
        allowedVehicles: ['truck'],
        createdAt: DateTime.now(),
      },
      {
        edgeCode: 'E3',
        sourceLocationId: n2.id,
        targetLocationId: n4.id,
        routeType: 'river',
        baseTravelMins: 120,
        currentTravelMins: 150, // current surge
        isFlooded: true,
        isBlocked: false,
        riskScore: 0.65,
        maxPayloadKg: 2000,
        allowedVehicles: ['speedboat'],
        createdAt: DateTime.now(),
      },
      {
        edgeCode: 'E4',
        sourceLocationId: n3.id,
        targetLocationId: n5.id,
        routeType: 'road',
        baseTravelMins: 60,
        currentTravelMins: 75,
        isFlooded: false,
        isBlocked: false,
        riskScore: 0.2,
        maxPayloadKg: 3000,
        allowedVehicles: ['truck'],
        createdAt: DateTime.now(),
      },
      {
        edgeCode: 'E5',
        sourceLocationId: n4.id,
        targetLocationId: n5.id,
        routeType: 'airway',
        baseTravelMins: 30,
        currentTravelMins: 30,
        isFlooded: false,
        isBlocked: false,
        riskScore: 0.1,
        maxPayloadKg: 25, // drone payload limit
        allowedVehicles: ['drone'],
        createdAt: DateTime.now(),
      },
      {
        edgeCode: 'E6',
        sourceLocationId: n2.id,
        targetLocationId: n5.id,
        routeType: 'airway',
        baseTravelMins: 35,
        currentTravelMins: 35,
        isFlooded: false,
        isBlocked: false,
        riskScore: 0.1,
        maxPayloadKg: 25,
        allowedVehicles: ['drone'],
        createdAt: DateTime.now(),
      },
      {
        edgeCode: 'E7',
        sourceLocationId: n1.id,
        targetLocationId: n6.id,
        routeType: 'road',
        baseTravelMins: 75,
        currentTravelMins: 90,
        isFlooded: false,
        isBlocked: false,
        riskScore: 0.25,
        maxPayloadKg: 5000,
        allowedVehicles: ['truck'],
        createdAt: DateTime.now(),
      },
    ]);
  }
}
