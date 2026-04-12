import db from '@adonisjs/lucid/services/db'

import type { StoreEdgeType, EdgeStatusType } from './network.validator.js'
import type { HttpContext } from '@adonisjs/core/http'

import { EventBus } from '#services/event_bus'

export class NetworkService {
  async graph(ctx: HttpContext) {
    const { response } = ctx

    const nodes = await db
      .from('locations')
      .where('is_active', true)
      .select(
        'id',
        'node_code as code',
        'name',
        'type',
        'latitude as lat',
        'longitude as lng',
        'is_flooded',
        'capacity',
        'current_occupancy'
      )

    const edges = await db
      .from('routes')
      .select(
        'id',
        'edge_code as code',
        'source_location_id as source',
        'target_location_id as target',
        'route_type as type',
        'base_travel_mins',
        'current_travel_mins',
        'is_flooded',
        'is_blocked',
        'risk_score',
        'max_payload_kg',
        'allowed_vehicles'
      )

    return response.sendFormatted({ nodes, edges, fetched_at: new Date().toISOString() })
  }

  async edges(ctx: HttpContext) {
    const { request, response } = ctx

    const routeType = request.input('type')
    const isFlooded = request.input('is_flooded')

    const query = db.from('routes')
    if (routeType) query.where('route_type', routeType)
    if (isFlooded !== undefined) query.where('is_flooded', isFlooded === 'true')

    return response.sendFormatted(await query)
  }

  async showEdge(ctx: HttpContext) {
    const { params, response } = ctx

    const edge = await db.from('routes').where('id', params.id).firstOrFail()
    const prediction = await db
      .from('route_ml_predictions')
      .where('route_id', params.id)
      .where('is_active', true)
      .first()

    return response.sendFormatted({ ...edge, prediction })
  }

  async compute(ctx: HttpContext) {
    const { request, response } = ctx

    const fromCode = request.input('from')
    const toCode = request.input('to')
    const vehicle = request.input('vehicle', 'truck')

    if (!fromCode || !toCode) {
      return response.status(400).sendError('from and to query params are required')
    }

    // M4.3 — vehicle-type constraint: each vehicle only uses its allowed edge type
    const allowedType = vehicle === 'truck' ? 'road' : vehicle === 'speedboat' ? 'river' : 'airway'

    const [edges, fromNode, toNode] = await Promise.all([
      db
        .from('routes')
        .where('route_type', allowedType)
        .where('is_flooded', false)
        .where('is_blocked', false)
        .select(
          'id',
          'edge_code',
          'source_location_id',
          'target_location_id',
          'route_type',
          'current_travel_mins as weight',
          'risk_score',
          'max_payload_kg'
        ),
      db.from('locations').where('node_code', fromCode).first(),
      db.from('locations').where('node_code', toCode).first(),
    ])

    if (!fromNode || !toNode) {
      return response.status(404).sendError('One or both locations not found')
    }

    // M4.2 — Dijkstra shortest path (by current_travel_mins)
    const result = this._dijkstra(edges, fromNode.id, toNode.id)

    if (!result) {
      return response.sendFormatted(
        { from: fromNode, to: toNode, vehicle, is_viable: false, path: [], total_mins: null },
        'No viable route found for this vehicle type (all paths flooded or blocked)'
      )
    }

    // Enrich path with node metadata
    const nodeIds = result.path
    const allNodes = await db
      .from('locations')
      .whereIn('id', nodeIds)
      .select(
        'id',
        'node_code as code',
        'name',
        'type',
        'latitude as lat',
        'longitude as lng',
        'is_flooded'
      )
    const nodeMap = new Map(allNodes.map((n: any) => [n.id, n]))
    const edgeMap = new Map(result.usedEdges.map((e: any) => [e.id, e]))

    const pathSteps = nodeIds.map((nodeId, idx) => ({
      step: idx + 1,
      node: nodeMap.get(nodeId),
      via_edge: idx > 0 ? edgeMap.get(result.edgeIds[idx - 1]) : null,
    }))

    return response.sendFormatted({
      from: fromNode,
      to: toNode,
      vehicle,
      is_viable: true,
      total_mins: Math.round(result.totalWeight),
      path: pathSteps,
      edge_count: result.edgeIds.length,
      computed_at: new Date().toISOString(),
    })
  }

  // M4.2 — Dijkstra implementation (O(n²) — sufficient for small disaster-zone graphs)
  private _dijkstra(
    edges: Array<{
      id: number
      source_location_id: number
      target_location_id: number
      weight: number
      [k: string]: any
    }>,
    fromId: number,
    toId: number
  ): { path: number[]; edgeIds: number[]; usedEdges: any[]; totalWeight: number } | null {
    const adj = new Map<number, Array<{ to: number; edgeId: number; weight: number; edge: any }>>()
    for (const e of edges) {
      if (!adj.has(e.source_location_id)) adj.set(e.source_location_id, [])
      adj
        .get(e.source_location_id)!
        .push({ to: e.target_location_id, edgeId: e.id, weight: Number(e.weight) || 1, edge: e })
      // treat routes as bidirectional for MVP
      if (!adj.has(e.target_location_id)) adj.set(e.target_location_id, [])
      adj
        .get(e.target_location_id)!
        .push({ to: e.source_location_id, edgeId: e.id, weight: Number(e.weight) || 1, edge: e })
    }

    const dist = new Map<number, number>()
    const prev = new Map<number, { nodeId: number; edgeId: number; edge: any } | null>()
    const visited = new Set<number>()

    const allNodeIds = new Set(edges.flatMap((e) => [e.source_location_id, e.target_location_id]))
    allNodeIds.add(fromId)
    allNodeIds.add(toId)
    for (const n of allNodeIds) dist.set(n, Infinity)
    dist.set(fromId, 0)
    prev.set(fromId, null)

    while (true) {
      let u = -1
      let minDist = Infinity
      for (const [node, d] of dist) {
        if (!visited.has(node) && d < minDist) {
          minDist = d
          u = node
        }
      }
      if (u === -1 || u === toId) break
      visited.add(u)

      for (const { to, edgeId, weight, edge } of adj.get(u) ?? []) {
        const nd = minDist + weight
        if (nd < (dist.get(to) ?? Infinity)) {
          dist.set(to, nd)
          prev.set(to, { nodeId: u, edgeId, edge })
        }
      }
    }

    if ((dist.get(toId) ?? Infinity) === Infinity) return null

    const path: number[] = []
    const edgeIds: number[] = []
    const usedEdges: any[] = []
    let cur: number | undefined = toId

    while (cur !== undefined) {
      path.unshift(cur)
      const p = prev.get(cur)
      if (!p) break
      edgeIds.unshift(p.edgeId)
      usedEdges.unshift(p.edge)
      cur = p.nodeId
    }

    return { path, edgeIds, usedEdges, totalWeight: dist.get(toId)! }
  }

  async storeEdge(ctx: HttpContext, payload: StoreEdgeType) {
    const { response } = ctx

    const [id] = await db.table('routes').insert({
      ...payload,
      allowed_vehicles: JSON.stringify(payload.allowed_vehicles ?? []),
      current_travel_mins: payload.base_travel_mins,
      is_flooded: false,
      is_blocked: false,
      risk_score: 0,
      created_at: new Date(),
      updated_at: new Date(),
    })

    return response.status(201).sendFormatted(await db.from('routes').where('id', id).first())
  }

  async updateEdgeStatus(ctx: HttpContext, payload: EdgeStatusType) {
    const { params, auth, response } = ctx

    const route = await db.from('routes').where('id', params.id).firstOrFail()

    await db.table('route_condition_logs').insert({
      route_id: params.id,
      changed_by_user_id: auth.user?.id ?? null,
      old_travel_mins: route.current_travel_mins,
      new_travel_mins: payload.current_travel_mins ?? route.current_travel_mins,
      old_risk_score: route.risk_score,
      new_risk_score: payload.risk_score ?? route.risk_score,
      is_flooded: payload.is_flooded ?? route.is_flooded,
      reason: payload.reason ?? 'manual_override',
      created_at: new Date(),
    })

    await db
      .from('routes')
      .where('id', params.id)
      .update({
        ...(payload.is_flooded !== undefined && { is_flooded: payload.is_flooded }),
        ...(payload.is_blocked !== undefined && { is_blocked: payload.is_blocked }),
        ...(payload.current_travel_mins && { current_travel_mins: payload.current_travel_mins }),
        ...(payload.risk_score !== undefined && { risk_score: payload.risk_score }),
        updated_at: new Date(),
      })

    EventBus.publish('route_update', {
      routeId: Number(params.id),
      edgeCode: route.edge_code,
      ...payload,
    })

    return response.sendFormatted('Edge status updated')
  }
}
