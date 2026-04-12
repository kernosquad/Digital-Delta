import { createHash, randomUUID } from 'node:crypto'

import db from '@adonisjs/lucid/services/db'

import type {
  StoreHandoffType,
  CompleteHandoffType,
  RendezvousType,
  SimulateProtocolType,
} from './handoff.validator.js'
import type { HttpContext } from '@adonisjs/core/http'

import { EventBus } from '#services/event_bus'

// ── Geo helpers ──────────────────────────────────────────────────────────────

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371
  const dLat = ((lat2 - lat1) * Math.PI) / 180
  const dLng = ((lng2 - lng1) * Math.PI) / 180
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

// Interpolate a point at fraction t [0,1] along the line from A to B
function interpolate(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
  t: number
): [number, number] {
  return [lat1 + (lat2 - lat1) * t, lng1 + (lng2 - lng1) * t]
}

// ── BFS reachability ─────────────────────────────────────────────────────────

function bfsReachable(
  fromIds: number[],
  edges: Array<{ source: number; target: number }>
): Set<number> {
  const adj = new Map<number, number[]>()
  for (const e of edges) {
    if (!adj.has(e.source)) adj.set(e.source, [])
    adj.get(e.source)!.push(e.target)
    if (!adj.has(e.target)) adj.set(e.target, [])
    adj.get(e.target)!.push(e.source)
  }
  const visited = new Set<number>(fromIds)
  const queue = [...fromIds]
  while (queue.length > 0) {
    const cur = queue.shift()!
    for (const next of adj.get(cur) ?? []) {
      if (!visited.has(next)) {
        visited.add(next)
        queue.push(next)
      }
    }
  }
  return visited
}

export class HandoffService {
  async index(ctx: HttpContext) {
    const { request, response } = ctx

    const status = request.input('status')
    const missionId = request.input('mission_id')

    const query = db
      .from('handoff_events as h')
      .join('missions as m', 'm.id', 'h.mission_id')
      .join('vehicles as dv', 'dv.id', 'h.drone_vehicle_id')
      .join('vehicles as gv', 'gv.id', 'h.ground_vehicle_id')
      .select(
        'h.*',
        'm.mission_code',
        'dv.name as drone_name',
        'dv.identifier as drone_identifier',
        'gv.name as ground_name',
        'gv.identifier as ground_identifier'
      )
      .orderBy('h.scheduled_at', 'desc')

    if (status) query.where('h.status', status)
    if (missionId) query.where('h.mission_id', missionId)

    const data = await query

    return response.sendFormatted(data)
  }

  async show(ctx: HttpContext) {
    const { params, response } = ctx

    const handoff = await db
      .from('handoff_events as h')
      .join('missions as m', 'm.id', 'h.mission_id')
      .join('vehicles as dv', 'dv.id', 'h.drone_vehicle_id')
      .join('vehicles as gv', 'gv.id', 'h.ground_vehicle_id')
      .leftJoin('locations as loc', 'loc.id', 'h.rendezvous_location_id')
      .where('h.id', params.id)
      .select(
        'h.*',
        'm.mission_code',
        'm.status as mission_status',
        'm.priority_class',
        'dv.name as drone_name',
        'dv.identifier as drone_identifier',
        'dv.type as drone_type',
        'gv.name as ground_name',
        'gv.identifier as ground_identifier',
        'gv.type as ground_type',
        'loc.name as rendezvous_location_name'
      )
      .first()

    if (!handoff) {
      return response.status(404).sendError('Handoff event not found')
    }

    return response.sendFormatted(handoff)
  }

  async store(ctx: HttpContext, payload: StoreHandoffType) {
    const { response } = ctx

    // Validate both vehicles are registered
    const droneVehicle = await db.from('vehicles').where('id', payload.drone_vehicle_id).first()
    if (!droneVehicle) {
      return response.status(422).sendError('Drone vehicle not found')
    }

    const groundVehicle = await db.from('vehicles').where('id', payload.ground_vehicle_id).first()
    if (!groundVehicle) {
      return response.status(422).sendError('Ground vehicle not found')
    }

    const [handoffId] = await db.table('handoff_events').insert({
      mission_id: payload.mission_id,
      drone_vehicle_id: payload.drone_vehicle_id,
      ground_vehicle_id: payload.ground_vehicle_id,
      rendezvous_location_id: payload.rendezvous_location_id ?? null,
      rendezvous_lat: payload.rendezvous_lat,
      rendezvous_lng: payload.rendezvous_lng,
      scheduled_at: new Date(payload.scheduled_at),
      status: 'scheduled',
      created_at: new Date(),
    })

    EventBus.publish('mission_update', {
      type: 'handoff_scheduled',
      handoffId,
      missionId: payload.mission_id,
    })

    return response.status(201).sendFormatted({ handoff_id: handoffId })
  }

  async complete(ctx: HttpContext, payload: CompleteHandoffType) {
    const { params, response } = ctx

    const handoffId = Number(params.id)

    const handoff = await db.from('handoff_events').where('id', handoffId).first()
    if (!handoff) {
      return response.status(404).sendError('Handoff event not found')
    }

    await db
      .from('handoff_events')
      .where('id', handoffId)
      .update({
        status: 'completed',
        completed_at: payload.completed_at ? new Date(payload.completed_at) : new Date(),
        ...(payload.delivery_receipt_id !== undefined && {
          delivery_receipt_id: payload.delivery_receipt_id,
        }),
      })

    EventBus.publish('mission_update', {
      type: 'handoff_completed',
      handoffId,
    })

    return response.sendFormatted({ handoff_id: handoffId }, 'Handoff marked as completed')
  }

  // M8.1 — Reachability Analysis: classify every location as truck/boat/drone-required
  async reachability(ctx: HttpContext) {
    const { response } = ctx

    const [nodes, roadEdges, riverEdges] = await Promise.all([
      db
        .from('locations')
        .where('is_active', true)
        .select(
          'id',
          'node_code as code',
          'name',
          'type',
          'latitude as lat',
          'longitude as lng',
          'is_flooded'
        ),
      db
        .from('routes')
        .where('route_type', 'road')
        .where('is_flooded', false)
        .where('is_blocked', false)
        .select('source_location_id as source', 'target_location_id as target'),
      db
        .from('routes')
        .where('route_type', 'river')
        .where('is_flooded', false)
        .where('is_blocked', false)
        .select('source_location_id as source', 'target_location_id as target'),
    ])

    // Hub nodes (command centres + supply drops) are the supply origin points
    const hubIds = nodes
      .filter((n: any) => ['central_command', 'supply_drop'].includes(n.type))
      .map((n: any) => n.id)

    const truckReachable = bfsReachable(hubIds, roadEdges)
    const boatReachable = bfsReachable(hubIds, riverEdges)

    const zones = nodes.map((n: any) => {
      const byTruck = truckReachable.has(n.id)
      const byBoat = boatReachable.has(n.id)
      const isDroneRequired =
        !byTruck && !byBoat && !['central_command', 'supply_drop'].includes(n.type)
      return {
        ...n,
        reachable_by_truck: byTruck,
        reachable_by_boat: byBoat,
        reachable_by_drone_only: isDroneRequired,
        classification: isDroneRequired
          ? 'drone_required'
          : byTruck
            ? 'truck_accessible'
            : 'boat_accessible',
      }
    })

    const droneRequired = zones.filter((z: any) => z.reachable_by_drone_only)

    return response.sendFormatted({
      total_nodes: nodes.length,
      drone_required_count: droneRequired.length,
      zones,
      computed_at: new Date().toISOString(),
    })
  }

  // M8.2 — Optimal Rendezvous Point Computation (minimises total mission time)
  async computeRendezvous(ctx: HttpContext, payload: RendezvousType) {
    const { response } = ctx

    const boatSpd = payload.boat_speed_kmh ?? 20
    const droneSpd = payload.drone_speed_kmh ?? 60
    const maxRange = payload.drone_max_range_km ?? 50
    const pKg = payload.payload_kg ?? 0
    const droneMax = payload.drone_max_payload_kg ?? 10

    if (pKg > droneMax) {
      return response
        .status(422)
        .sendError(
          `Payload ${pKg}kg exceeds drone max capacity ${droneMax}kg — drone handoff not feasible`
        )
    }

    // Generate 60 candidate rendezvous points:
    //  - 30 along the boat's straight line toward the destination
    //  - 30 in a grid around the midpoint of boat ↔ drone_base
    const candidates: Array<[number, number]> = []
    for (let i = 0; i <= 29; i++) {
      candidates.push(
        interpolate(payload.boat_lat, payload.boat_lng, payload.dest_lat, payload.dest_lng, i / 29)
      )
    }
    const midLat = (payload.boat_lat + payload.drone_base_lat) / 2
    const midLng = (payload.boat_lng + payload.drone_base_lng) / 2
    for (let di = -2; di <= 2; di++) {
      for (let dj = -2; dj <= 2; dj++) {
        candidates.push([midLat + di * 0.03, midLng + dj * 0.03])
      }
    }

    let best: {
      lat: number
      lng: number
      boat_travel_h: number
      drone_to_rv_h: number
      drone_to_dest_h: number
      total_drone_km: number
      total_mission_h: number
      feasible: boolean
    } | null = null

    for (const [rvLat, rvLng] of candidates) {
      const boatToRv = haversineKm(payload.boat_lat, payload.boat_lng, rvLat, rvLng)
      const droneToRv = haversineKm(payload.drone_base_lat, payload.drone_base_lng, rvLat, rvLng)
      const rvToDest = haversineKm(rvLat, rvLng, payload.dest_lat, payload.dest_lng)
      const totalDroneKm = droneToRv + rvToDest

      if (totalDroneKm > maxRange) continue // outside drone range

      const boatTimeH = boatToRv / boatSpd
      const droneTimeH = droneToRv / droneSpd
      const droneDestH = rvToDest / droneSpd

      // Total mission time: both arrive at RV, then drone completes last mile
      const missionH = Math.max(boatTimeH, droneTimeH) + droneDestH

      if (!best || missionH < best.total_mission_h) {
        best = {
          lat: rvLat,
          lng: rvLng,
          boat_travel_h: boatTimeH,
          drone_to_rv_h: droneTimeH,
          drone_to_dest_h: droneDestH,
          total_drone_km: totalDroneKm,
          total_mission_h: missionH,
          feasible: true,
        }
      }
    }

    if (!best) {
      // No candidate within range — drone can't reach destination from any meetup point
      const directDist = haversineKm(
        payload.drone_base_lat,
        payload.drone_base_lng,
        payload.dest_lat,
        payload.dest_lng
      )
      return response
        .status(422)
        .sendError(
          `No feasible rendezvous within drone range (${maxRange}km). Direct drone distance to dest: ${directDist.toFixed(1)}km`
        )
    }

    const toMin = (h: number) => Math.round(h * 60)

    return response.sendFormatted({
      rendezvous_lat: Number.parseFloat(best.lat.toFixed(6)),
      rendezvous_lng: Number.parseFloat(best.lng.toFixed(6)),
      boat_travel_mins: toMin(best.boat_travel_h),
      drone_to_rv_mins: toMin(best.drone_to_rv_h),
      drone_to_dest_mins: toMin(best.drone_to_dest_h),
      total_drone_km: Number.parseFloat(best.total_drone_km.toFixed(2)),
      total_mission_mins: toMin(best.total_mission_h),
      within_drone_range: best.total_drone_km <= maxRange,
      payload_feasible: pKg <= droneMax,
      constraints: {
        boat_speed_kmh: boatSpd,
        drone_speed_kmh: droneSpd,
        drone_max_range_km: maxRange,
        payload_kg: pKg,
        drone_max_payload_kg: droneMax,
      },
    })
  }

  // M8.3 — Simulate full handoff coordination protocol
  async simulateProtocol(ctx: HttpContext, payload: SimulateProtocolType) {
    const { auth, response } = ctx

    const handoff = await db.from('handoff_events').where('id', payload.handoff_id).first()
    if (!handoff) {
      return response.status(404).sendError('Handoff event not found')
    }
    if (handoff.status === 'completed') {
      return response.status(422).sendError('Handoff already completed')
    }

    // Step 1: transition to in_progress
    await db
      .from('handoff_events')
      .where('id', payload.handoff_id)
      .update({ status: 'in_progress' })

    EventBus.publish('mission_update', {
      type: 'handoff_in_progress',
      handoffId: payload.handoff_id,
    })

    // Step 2 (M5.1): generate PoD receipt for the handoff
    const nonce = randomUUID()
    const ts = new Date().toISOString()
    const payloadRaw = `${handoff.mission_id}:${nonce}:${ts}:handoff`
    const payloadHash = createHash('sha256').update(payloadRaw).digest('hex')

    // boat/ground-vehicle driver signature
    const driverSigRaw = `${payloadHash}:${auth.user!.id}:${nonce}`
    const driverSig = createHash('sha256').update(driverSigRaw).digest('hex')

    // drone counter-signature (M8.3)
    const droneSigRaw = `${driverSig}:drone_ack:${handoff.drone_vehicle_id}`
    const droneSig = createHash('sha256').update(droneSigRaw).digest('hex')

    const lastReceipt = await db
      .from('delivery_receipts')
      .orderBy('id', 'desc')
      .select('receipt_hash')
      .first()
    const prevHash = lastReceipt?.receipt_hash ?? null
    const receiptRaw = `${handoff.mission_id}:${nonce}:${payloadHash}:${driverSig}`
    const receiptHash = createHash('sha256').update(receiptRaw).digest('hex')

    const recipientLocId = payload.recipient_location_id ?? handoff.rendezvous_location_id ?? 1

    const [receiptId] = await db.table('delivery_receipts').insert({
      mission_id: handoff.mission_id,
      recipient_location_id: recipientLocId,
      received_by_user_id: auth.user!.id,
      driver_user_id: auth.user!.id,
      qr_nonce: nonce,
      driver_signature: driverSig,
      recipient_signature: droneSig, // drone counter-signs
      payload_hash: payloadHash,
      is_verified: true,
      verified_at: new Date(),
      previous_receipt_hash: prevHash,
      receipt_hash: receiptHash,
      created_at: new Date(),
    })

    await db
      .table('used_nonces')
      .insert({ nonce, delivery_receipt_id: receiptId, created_at: new Date() })

    // Step 3: complete handoff and link receipt (CRDT ownership transfer)
    const now = new Date()
    await db.from('handoff_events').where('id', payload.handoff_id).update({
      status: 'completed',
      delivery_receipt_id: receiptId,
      completed_at: now,
    })

    // Step 4: update mission to delivered
    await db.from('missions').where('id', handoff.mission_id).update({
      status: 'completed',
      actual_arrival: now,
      updated_at: now,
    })

    EventBus.publish('mission_update', {
      type: 'handoff_completed_with_pod',
      handoffId: payload.handoff_id,
      receiptId,
      receiptHash,
      droneCounterSigned: true,
    })

    return response.status(201).sendFormatted({
      handoff_id: payload.handoff_id,
      receipt_id: receiptId,
      receipt_hash: receiptHash,
      driver_signature: driverSig,
      drone_counter_signature: droneSig,
      chain_verified: !!prevHash,
      protocol_steps: [
        { step: 1, event: 'handoff_in_progress', ts: ts },
        { step: 2, event: 'pod_receipt_generated', nonce: nonce.slice(0, 8) + '…' },
        { step: 3, event: 'drone_counter_signed' },
        {
          step: 4,
          event: 'crdt_ownership_transferred',
          receipt_hash: receiptHash.slice(0, 16) + '…',
        },
      ],
    })
  }
}
