import { BaseSeeder } from '@adonisjs/lucid/seeders'
import { DateTime } from 'luxon'

import Location from '#models/location'
import Mission from '#models/mission'
import MissionCargo from '#models/mission_cargo'
import SupplyItem from '#models/supply_item'
import User from '#models/user'
import Vehicle from '#models/vehicle'

/**
 * Seed realistic disaster-response missions with full SLA lifecycle.
 *
 * Covers M6.1 priority taxonomy:
 *   P0 — antivenom / blood (SLA 2 h) — 2 active missions
 *   P1 — medicines / water (SLA 6 h) — 2 active missions
 *   P2 — food / shelter (SLA 24 h)   — 2 planned missions
 *   P3 — equipment (SLA 72 h)         — 1 planned
 *
 * Also demonstrates:
 *   - 1 SLA-breached mission (for M6.2 breach prediction demo)
 *   - 1 preempted mission (for M6.3 autonomous reroute demo)
 *   - 1 completed mission (full chain)
 */
export default class MissionSeeder extends BaseSeeder {
  async run() {
    const now = DateTime.now()

    const n1 = await Location.findByOrFail('nodeCode', 'N1')
    const n2 = await Location.findByOrFail('nodeCode', 'N2')
    const n3 = await Location.findByOrFail('nodeCode', 'N3')
    const n4 = await Location.findByOrFail('nodeCode', 'N4')
    const n5 = await Location.findByOrFail('nodeCode', 'N5')
    const n6 = await Location.findByOrFail('nodeCode', 'N6')

    const truck1 = await Vehicle.findByOrFail('identifier', 'DHK-TRUCK-001')
    const truck2 = await Vehicle.findByOrFail('identifier', 'DHK-TRUCK-002')
    const boat1 = await Vehicle.findByOrFail('identifier', 'SYL-BOAT-001')
    const drone1 = await Vehicle.findByOrFail('identifier', 'DRONE-D1')
    const drone2 = await Vehicle.findByOrFail('identifier', 'DRONE-D2')

    const commander = await User.findByOrFail('email', 'commander@digitaldelta.io')
    const supplyMgr = await User.findByOrFail('email', 'supply@digitaldelta.io')
    const droneOp = await User.findByOrFail('email', 'drone@digitaldelta.io')

    const antivenom = await SupplyItem.findByOrFail('name', 'Snake Antivenom (polyvalent)')
    const blood = await SupplyItem.findByOrFail('name', 'Blood Bags (O+)')
    const ors = await SupplyItem.findByOrFail('name', 'Oral Rehydration Salts')
    const antibiotics = await SupplyItem.findByOrFail('name', 'Antibiotics (Amoxicillin 500 mg)')
    const water = await SupplyItem.findByOrFail('name', 'Purified Drinking Water')
    const food = await SupplyItem.findByOrFail('name', 'Emergency Food Ration (1-day)')
    const tarpaulin = await SupplyItem.findByOrFail('name', 'Waterproof Tarpaulin (4×6 m)')
    const blanket = await SupplyItem.findByOrFail('name', 'Emergency Blanket (mylar)')
    const generator = await SupplyItem.findByOrFail('name', 'Portable Generator (2 kW)')
    const genFuel = await SupplyItem.findByOrFail('name', 'Generator Fuel (petrol)')

    // ── 1. P0 Active — antivenom rush to Shahjalal Hospital ──────────────────
    const m1 = await Mission.create({
      missionCode: 'MSN-2026-0001',
      priorityClass: 'p0_critical',
      status: 'active',
      originLocationId: n1.id,
      destinationLocationId: n3.id,
      vehicleId: truck1.id,
      driverId: commander.id,
      createdById: commander.id,
      totalPayloadKg: 4.0,
      slaDeadline: now.plus({ hours: 1, minutes: 30 }),
      slaBreached: false,
      notes: 'CRITICAL: Antivenom shortage at Shahjalal Hospital. 3 snakebite cases admitted.',
      createdAt: now.minus({ hours: 1 }),
    })
    await truck1.merge({ status: 'in_mission', currentLocationId: n1.id }).save()

    await MissionCargo.createMany([
      { missionId: m1.id, supplyItemId: antivenom.id, quantity: 40, deliveredQuantity: 0 },
      { missionId: m1.id, supplyItemId: blood.id, quantity: 20, deliveredQuantity: 0 },
    ])

    // ── 2. P0 Active — blood bags aerial drop to Sunamganj ──────────────────
    const m2 = await Mission.create({
      missionCode: 'MSN-2026-0002',
      priorityClass: 'p0_critical',
      status: 'active',
      originLocationId: n5.id,
      destinationLocationId: n4.id,
      vehicleId: drone1.id,
      driverId: droneOp.id,
      createdById: commander.id,
      totalPayloadKg: 4.5,
      slaDeadline: now.plus({ hours: 2 }),
      slaBreached: false,
      notes: 'Drone drop: blood bags to flooded supply point. Ground access impossible.',
      createdAt: now.minus({ minutes: 45 }),
    })
    await drone1.merge({ status: 'in_mission' }).save()

    await MissionCargo.create({
      missionId: m2.id,
      supplyItemId: blood.id,
      quantity: 15,
      deliveredQuantity: 0,
    })

    // ── 3. P1 Active — ORS + antibiotics to Companiganj relief camp ─────────
    const m3 = await Mission.create({
      missionCode: 'MSN-2026-0003',
      priorityClass: 'p1_high',
      status: 'active',
      originLocationId: n1.id,
      destinationLocationId: n2.id,
      vehicleId: boat1.id,
      driverId: supplyMgr.id,
      createdById: commander.id,
      totalPayloadKg: 2050.0,
      slaDeadline: now.plus({ hours: 4, minutes: 30 }),
      slaBreached: false,
      notes: 'River route. Water levels elevated but navigable. Relief camp at 40% capacity.',
      createdAt: now.minus({ hours: 2 }),
    })
    await boat1.merge({ status: 'in_mission' }).save()

    await MissionCargo.createMany([
      { missionId: m3.id, supplyItemId: ors.id, quantity: 500, deliveredQuantity: 0 },
      { missionId: m3.id, supplyItemId: antibiotics.id, quantity: 80, deliveredQuantity: 0 },
      { missionId: m3.id, supplyItemId: water.id, quantity: 2000, deliveredQuantity: 0 },
    ])

    // ── 4. P1 SLA-BREACHED — water delivery delayed (demonstrates M6.2) ────
    const m4 = await Mission.create({
      missionCode: 'MSN-2026-0004',
      priorityClass: 'p1_high',
      status: 'active',
      originLocationId: n3.id,
      destinationLocationId: n5.id,
      vehicleId: truck2.id,
      driverId: commander.id,
      createdById: commander.id,
      totalPayloadKg: 1000.0,
      slaDeadline: now.minus({ hours: 1 }), // already breached
      slaBreached: true,
      notes: 'DELAYED: Road E4 flooded segment caused 90-min delay. Auto-reroute triggered.',
      createdAt: now.minus({ hours: 8 }),
    })
    await truck2.merge({ status: 'in_mission', currentLocationId: n3.id }).save()

    await MissionCargo.createMany([
      { missionId: m4.id, supplyItemId: water.id, quantity: 1000, deliveredQuantity: 0 },
      { missionId: m4.id, supplyItemId: ors.id, quantity: 200, deliveredQuantity: 0 },
    ])

    // ── 5. P2 Planned — food + shelter to Companiganj ────────────────────────
    const m5 = await Mission.create({
      missionCode: 'MSN-2026-0005',
      priorityClass: 'p2_standard',
      status: 'planned',
      originLocationId: n1.id,
      destinationLocationId: n2.id,
      createdById: supplyMgr.id,
      totalPayloadKg: 1890.0,
      slaDeadline: now.plus({ hours: 20 }),
      slaBreached: false,
      notes: 'Awaiting truck availability after MSN-0001 completes.',
      createdAt: now.minus({ minutes: 30 }),
    })

    await MissionCargo.createMany([
      { missionId: m5.id, supplyItemId: food.id, quantity: 800, deliveredQuantity: 0 },
      { missionId: m5.id, supplyItemId: tarpaulin.id, quantity: 150, deliveredQuantity: 0 },
      { missionId: m5.id, supplyItemId: blanket.id, quantity: 500, deliveredQuantity: 0 },
    ])

    // ── 6. P2 Planned — shelter supplies to Jaintiapur ────────────────────────
    const m6 = await Mission.create({
      missionCode: 'MSN-2026-0006',
      priorityClass: 'p2_standard',
      status: 'planned',
      originLocationId: n1.id,
      destinationLocationId: n6.id,
      createdById: commander.id,
      totalPayloadKg: 350.0,
      slaDeadline: now.plus({ hours: 22 }),
      slaBreached: false,
      notes: 'Waypoint relay to outlying areas. Pending route clearance for E7.',
      createdAt: now.minus({ minutes: 15 }),
    })

    await MissionCargo.createMany([
      { missionId: m6.id, supplyItemId: blanket.id, quantity: 300, deliveredQuantity: 0 },
      { missionId: m6.id, supplyItemId: food.id, quantity: 400, deliveredQuantity: 0 },
    ])

    // ── 7. P3 Planned — generator + fuel to Drone Base ───────────────────────
    const m7 = await Mission.create({
      missionCode: 'MSN-2026-0007',
      priorityClass: 'p3_low',
      status: 'planned',
      originLocationId: n1.id,
      destinationLocationId: n5.id,
      createdById: supplyMgr.id,
      totalPayloadKg: 125.0,
      slaDeadline: now.plus({ hours: 65 }),
      slaBreached: false,
      notes: 'Drone base power backup. Low priority — defer if P0/P1 vehicle demand increases.',
      createdAt: now.minus({ minutes: 10 }),
    })

    await MissionCargo.createMany([
      { missionId: m7.id, supplyItemId: generator.id, quantity: 2, deliveredQuantity: 0 },
      { missionId: m7.id, supplyItemId: genFuel.id, quantity: 100, deliveredQuantity: 0 },
    ])

    // ── 8. PREEMPTED — P2 mission preempted to rush P0 (demonstrates M6.3) ──
    const m8 = await Mission.create({
      missionCode: 'MSN-2026-0008',
      priorityClass: 'p2_standard',
      status: 'preempted',
      originLocationId: n2.id,
      destinationLocationId: n6.id,
      createdById: supplyMgr.id,
      totalPayloadKg: 240.0,
      slaDeadline: now.plus({ hours: 18 }),
      slaBreached: false,
      preemptionReason:
        'Drone D2 redirected to P0 blood delivery (MSN-0002). Cargo safe-stored at N2.',
      notes: 'PREEMPTED by autonomous triage engine (M6.3).',
      createdAt: now.minus({ hours: 3 }),
    })

    await MissionCargo.create({
      missionId: m8.id,
      supplyItemId: food.id,
      quantity: 300,
      deliveredQuantity: 0,
    })

    // ── 9. COMPLETED — successful P1 delivery (full PoD chain) ───────────────
    const m9 = await Mission.create({
      missionCode: 'MSN-2026-0009',
      priorityClass: 'p1_high',
      status: 'completed',
      originLocationId: n1.id,
      destinationLocationId: n3.id,
      vehicleId: drone2.id,
      driverId: droneOp.id,
      createdById: commander.id,
      totalPayloadKg: 37.5,
      slaDeadline: now.minus({ hours: 2 }),
      slaBreached: false,
      actualArrival: now.minus({ hours: 2, minutes: 20 }),
      notes: 'Completed on time. PoD signed and logged to CRDT ledger.',
      createdAt: now.minus({ hours: 5 }),
    })

    await MissionCargo.createMany([
      {
        missionId: m9.id,
        supplyItemId: antibiotics.id,
        quantity: 50,
        deliveredQuantity: 50,
      },
      {
        missionId: m9.id,
        supplyItemId: ors.id,
        quantity: 200,
        deliveredQuantity: 200,
      },
    ])
  }
}
