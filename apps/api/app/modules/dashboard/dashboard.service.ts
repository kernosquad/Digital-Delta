import db from '@adonisjs/lucid/services/db';

import type { BusEvent } from '#services/event_bus';
import type { HttpContext } from '@adonisjs/core/http';

import { EventBus } from '#services/event_bus';

export class DashboardService {
  async stats(ctx: HttpContext) {
    const { response } = ctx;

    const now = new Date();
    const since24h = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    const [
      missionsRow,
      vehiclesRow,
      locationsRow,
      inventoryRow,
      meshPendingRow,
      mesh24hRow,
      triage24hRow,
    ] = await Promise.all([
      // Missions aggregates
      db
        .from('missions')
        .select(
          db.raw('COUNT(*) as total'),
          db.raw("SUM(CASE WHEN status IN ('active','paused') THEN 1 ELSE 0 END) as active"),
          db.raw("SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed"),
          db.raw("SUM(CASE WHEN status = 'planned' THEN 1 ELSE 0 END) as planned"),
          db.raw('SUM(CASE WHEN sla_breached = 1 THEN 1 ELSE 0 END) as sla_breached')
        )
        .first(),

      // Vehicles aggregates
      db
        .from('vehicles')
        .select(
          db.raw('COUNT(*) as total'),
          db.raw("SUM(CASE WHEN status = 'idle' THEN 1 ELSE 0 END) as idle"),
          db.raw("SUM(CASE WHEN status = 'in_mission' THEN 1 ELSE 0 END) as in_mission"),
          db.raw("SUM(CASE WHEN status = 'offline' THEN 1 ELSE 0 END) as offline")
        )
        .first(),

      // Locations aggregates
      db
        .from('locations')
        .select(
          db.raw('COUNT(*) as total'),
          db.raw('SUM(CASE WHEN is_flooded = 1 THEN 1 ELSE 0 END) as flooded'),
          db.raw('SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as active')
        )
        .first(),

      // Critical inventory items low stock (p0_critical supply items with quantity < 10)
      db
        .from('inventory as inv')
        .join('supply_items as si', 'si.id', 'inv.supply_item_id')
        .where('si.priority_class', 'p0_critical')
        .where('inv.quantity', '<', 10)
        .count('* as count')
        .first(),

      // Mesh messages pending (not yet delivered and not expired)
      db
        .from('mesh_messages')
        .where('is_delivered', false)
        .where('expires_at', '>', new Date())
        .count('* as count')
        .first(),

      // Mesh messages total last 24h
      db.from('mesh_messages').where('created_at', '>', since24h).count('* as count').first(),

      // Triage decisions last 24h
      db.from('triage_decisions').where('created_at', '>', since24h).count('* as count').first(),
    ]);

    return response.sendFormatted({
      missions: {
        total: Number(missionsRow?.total ?? 0),
        active: Number(missionsRow?.active ?? 0),
        completed: Number(missionsRow?.completed ?? 0),
        planned: Number(missionsRow?.planned ?? 0),
        sla_breached: Number(missionsRow?.sla_breached ?? 0),
      },
      vehicles: {
        total: Number(vehiclesRow?.total ?? 0),
        idle: Number(vehiclesRow?.idle ?? 0),
        in_mission: Number(vehiclesRow?.in_mission ?? 0),
        offline: Number(vehiclesRow?.offline ?? 0),
      },
      locations: {
        total: Number(locationsRow?.total ?? 0),
        flooded: Number(locationsRow?.flooded ?? 0),
        active: Number(locationsRow?.active ?? 0),
      },
      inventory: {
        critical_items_low: Number(inventoryRow?.count ?? 0),
      },
      mesh_messages: {
        pending: Number(meshPendingRow?.count ?? 0),
        total_24h: Number(mesh24hRow?.count ?? 0),
      },
      triage_decisions: {
        last_24h: Number(triage24hRow?.count ?? 0),
      },
      timestamp: now.toISOString(),
    });
  }

  async stream(ctx: HttpContext) {
    const { response } = ctx;

    // Set SSE headers
    response.response.setHeader('Content-Type', 'text/event-stream');
    response.response.setHeader('Cache-Control', 'no-cache');
    response.response.setHeader('Connection', 'keep-alive');
    response.response.flushHeaders();

    const send = (eventType: string, data: unknown) => {
      response.response.write(`event: ${eventType}\ndata: ${JSON.stringify(data)}\n\n`);
    };

    // EventBus emits all events on the 'event' channel as BusEvent objects
    const handler = (busEvent: BusEvent) => {
      send(busEvent.type, busEvent.data);
    };

    EventBus.on('event', handler);

    // Keep-alive every 30s
    const keepAlive = setInterval(() => {
      response.response.write(': keep-alive\n\n');
    }, 30_000);

    // Cleanup on connection close
    response.response.on('close', () => {
      clearInterval(keepAlive);
      EventBus.off('event', handler);
    });

    // Send initial connected event
    send('connected', { timestamp: new Date().toISOString() });
  }
}
