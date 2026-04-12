import { BaseSeeder } from '@adonisjs/lucid/seeders'
import { DateTime } from 'luxon'

import Location from '#models/location'
import User from '#models/user'
import Vehicle from '#models/vehicle'

/**
 * Seed the initial fleet:
 *   2 trucks (road/heavy cargo)
 *   2 speedboats (river/flood zones)
 *   3 drones (airway/light priority cargo)
 *
 * Vehicles start at Central Command (N1) unless otherwise noted.
 * Operators pre-assigned for demo purposes.
 */
export default class VehicleSeeder extends BaseSeeder {
  async run() {
    const n1 = await Location.findByOrFail('nodeCode', 'N1')
    const n5 = await Location.findByOrFail('nodeCode', 'N5')
    const droneOp = await User.findByOrFail('email', 'drone@digitaldelta.io')

    await Vehicle.createMany([
      {
        name: 'Truck Alpha',
        type: 'truck',
        identifier: 'DHK-TRUCK-001',
        maxPayloadKg: 5000,
        batteryLevel: null,
        fuelLevel: 85.0,
        status: 'idle',
        currentLocationId: n1.id,
        operatorId: null,
        createdAt: DateTime.now(),
      },
      {
        name: 'Truck Bravo',
        type: 'truck',
        identifier: 'DHK-TRUCK-002',
        maxPayloadKg: 5000,
        batteryLevel: null,
        fuelLevel: 60.0,
        status: 'idle',
        currentLocationId: n1.id,
        operatorId: null,
        createdAt: DateTime.now(),
      },
      {
        name: 'Speedboat One',
        type: 'speedboat',
        identifier: 'SYL-BOAT-001',
        maxPayloadKg: 2000,
        batteryLevel: null,
        fuelLevel: 90.0,
        status: 'idle',
        currentLocationId: n1.id,
        operatorId: null,
        createdAt: DateTime.now(),
      },
      {
        name: 'Speedboat Two',
        type: 'speedboat',
        identifier: 'SYL-BOAT-002',
        maxPayloadKg: 2000,
        batteryLevel: null,
        fuelLevel: 45.0,
        status: 'maintenance',
        currentLocationId: n1.id,
        operatorId: null,
        createdAt: DateTime.now(),
      },
      {
        name: 'Drone Delta-1',
        type: 'drone',
        identifier: 'DRONE-D1',
        maxPayloadKg: 25,
        batteryLevel: 100.0,
        fuelLevel: null,
        status: 'idle',
        currentLocationId: n5.id,
        operatorId: droneOp.id,
        createdAt: DateTime.now(),
      },
      {
        name: 'Drone Delta-2',
        type: 'drone',
        identifier: 'DRONE-D2',
        maxPayloadKg: 25,
        batteryLevel: 72.5,
        fuelLevel: null,
        status: 'idle',
        currentLocationId: n5.id,
        operatorId: droneOp.id,
        createdAt: DateTime.now(),
      },
      {
        name: 'Drone Delta-3',
        type: 'drone',
        identifier: 'DRONE-D3',
        maxPayloadKg: 25,
        batteryLevel: 15.0,
        fuelLevel: null,
        status: 'maintenance', // charging
        currentLocationId: n5.id,
        operatorId: droneOp.id,
        createdAt: DateTime.now(),
      },
    ])
  }
}
