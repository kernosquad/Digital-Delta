import { BaseSeeder } from '@adonisjs/lucid/seeders';
import { DateTime } from 'luxon';

import Inventory from '#models/inventory';
import Location from '#models/location';
import SupplyItem from '#models/supply_item';

/**
 * Seed the M6 priority taxonomy supply catalog and initial inventory.
 *
 * Priority tiers (Module 6 — M6.1):
 *   P0 Critical  — antivenom, blood bags          → SLA 2 h
 *   P1 High      — medicines, purified water       → SLA 6 h
 *   P2 Standard  — food rations, tarpaulins        → SLA 24 h
 *   P3 Low       — tools, generator fuel           → SLA 72 h
 *
 * Inventory is seeded at N1 (Central Command) as the primary stock node.
 * N2 (camp) and N4 (supply drop) receive forward stock.
 */
export default class SupplySeeder extends BaseSeeder {
  async run() {
    // ── Catalog ────────────────────────────────────────────────────────────
    const [
      antivenom,
      bloodBags,
      oralRehydration,
      antibiotics,
      purifiedWater,
      foodRation,
      tarpaulin,
      blanket,
      firstAidKit,
      generator,
      generatorFuel,
      rope,
    ] = await SupplyItem.createMany([
      // P0 Critical
      {
        name: 'Snake Antivenom (polyvalent)',
        category: 'medical',
        unit: 'vials',
        weightPerUnitKg: 0.05,
        priorityClass: 'p0_critical',
        slaHours: 2,
        createdAt: DateTime.now(),
      },
      {
        name: 'Blood Bags (O+)',
        category: 'medical',
        unit: 'units',
        weightPerUnitKg: 0.3,
        priorityClass: 'p0_critical',
        slaHours: 2,
        createdAt: DateTime.now(),
      },
      // P1 High
      {
        name: 'Oral Rehydration Salts',
        category: 'medical',
        unit: 'sachets',
        weightPerUnitKg: 0.02,
        priorityClass: 'p1_high',
        slaHours: 6,
        createdAt: DateTime.now(),
      },
      {
        name: 'Antibiotics (Amoxicillin 500 mg)',
        category: 'medical',
        unit: 'boxes',
        weightPerUnitKg: 0.15,
        priorityClass: 'p1_high',
        slaHours: 6,
        createdAt: DateTime.now(),
      },
      {
        name: 'Purified Drinking Water',
        category: 'water',
        unit: 'liters',
        weightPerUnitKg: 1.0,
        priorityClass: 'p1_high',
        slaHours: 6,
        createdAt: DateTime.now(),
      },
      // P2 Standard
      {
        name: 'Emergency Food Ration (1-day)',
        category: 'food',
        unit: 'packs',
        weightPerUnitKg: 0.8,
        priorityClass: 'p2_standard',
        slaHours: 24,
        createdAt: DateTime.now(),
      },
      {
        name: 'Waterproof Tarpaulin (4×6 m)',
        category: 'shelter',
        unit: 'pcs',
        weightPerUnitKg: 2.5,
        priorityClass: 'p2_standard',
        slaHours: 24,
        createdAt: DateTime.now(),
      },
      {
        name: 'Emergency Blanket (mylar)',
        category: 'shelter',
        unit: 'pcs',
        weightPerUnitKg: 0.1,
        priorityClass: 'p2_standard',
        slaHours: 24,
        createdAt: DateTime.now(),
      },
      {
        name: 'First Aid Kit (standard)',
        category: 'medical',
        unit: 'kits',
        weightPerUnitKg: 1.2,
        priorityClass: 'p2_standard',
        slaHours: 24,
        createdAt: DateTime.now(),
      },
      // P3 Low
      {
        name: 'Portable Generator (2 kW)',
        category: 'equipment',
        unit: 'units',
        weightPerUnitKg: 25.0,
        priorityClass: 'p3_low',
        slaHours: 72,
        createdAt: DateTime.now(),
      },
      {
        name: 'Generator Fuel (petrol)',
        category: 'equipment',
        unit: 'liters',
        weightPerUnitKg: 0.75,
        priorityClass: 'p3_low',
        slaHours: 72,
        createdAt: DateTime.now(),
      },
      {
        name: 'Heavy-Duty Rope (50 m)',
        category: 'equipment',
        unit: 'coils',
        weightPerUnitKg: 3.5,
        priorityClass: 'p3_low',
        slaHours: 72,
        createdAt: DateTime.now(),
      },
    ]);

    // ── Inventory ─────────────────────────────────────────────────────────
    const n1 = await Location.findByOrFail('nodeCode', 'N1');
    const n2 = await Location.findByOrFail('nodeCode', 'N2');
    const n4 = await Location.findByOrFail('nodeCode', 'N4');

    // Central Command (N1) — main stockpile
    const n1Stock = [
      [antivenom.id, 200],
      [bloodBags.id, 100],
      [oralRehydration.id, 5000],
      [antibiotics.id, 500],
      [purifiedWater.id, 10000],
      [foodRation.id, 3000],
      [tarpaulin.id, 800],
      [blanket.id, 2000],
      [firstAidKit.id, 300],
      [generator.id, 10],
      [generatorFuel.id, 500],
      [rope.id, 50],
    ];

    // Relief Camp Alpha (N2) — forward stock (smaller)
    const n2Stock = [
      [antivenom.id, 40],
      [bloodBags.id, 20],
      [oralRehydration.id, 1200],
      [antibiotics.id, 150],
      [purifiedWater.id, 3000],
      [foodRation.id, 1500],
      [tarpaulin.id, 300],
      [blanket.id, 800],
      [firstAidKit.id, 100],
    ];

    // Supply Drop (N4) — minimal staging stock
    const n4Stock = [
      [purifiedWater.id, 500],
      [foodRation.id, 400],
      [tarpaulin.id, 100],
      [blanket.id, 250],
    ];

    const inventoryRows: {
      locationId: number;
      supplyItemId: number;
      quantity: number;
      reservedQuantity: number;
      crdtVectorClock: Record<string, number>;
      lastUpdatedNode: string;
      lastSyncedAt: DateTime;
    }[] = [];

    const now = DateTime.now();
    const nodeId = 'server-N1';

    for (const [itemId, qty] of n1Stock) {
      inventoryRows.push({
        locationId: n1.id,
        supplyItemId: itemId as number,
        quantity: qty as number,
        reservedQuantity: 0,
        crdtVectorClock: { [nodeId]: 1 },
        lastUpdatedNode: nodeId,
        lastSyncedAt: now,
      });
    }

    for (const [itemId, qty] of n2Stock) {
      inventoryRows.push({
        locationId: n2.id,
        supplyItemId: itemId as number,
        quantity: qty as number,
        reservedQuantity: 0,
        crdtVectorClock: { 'server-N2': 1 },
        lastUpdatedNode: 'server-N2',
        lastSyncedAt: now,
      });
    }

    for (const [itemId, qty] of n4Stock) {
      inventoryRows.push({
        locationId: n4.id,
        supplyItemId: itemId as number,
        quantity: qty as number,
        reservedQuantity: 0,
        crdtVectorClock: { 'server-N4': 1 },
        lastUpdatedNode: 'server-N4',
        lastSyncedAt: now,
      });
    }

    await Inventory.createMany(inventoryRows);
  }
}
