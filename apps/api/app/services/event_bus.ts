import EventEmitter from 'node:events';

/**
 * EventBus — lightweight in-process pub/sub for Server-Sent Events.
 *
 * Controllers emit events here; DashboardController subscribes and
 * streams them to connected web clients via SSE.
 *
 * Event types and their payloads:
 *
 *   route_update   — a route's flood/block status or travel_mins changed
 *   mission_update — a mission changed status, was preempted, or rerouted
 *   sla_alert      — a mission is predicted to breach its SLA window
 *   triage_decision — an autonomous preemption/reroute decision was made
 *   vehicle_update — a vehicle's location, battery, or status changed
 *   conflict_detected — a CRDT sync conflict was detected
 *   sensor_update  — new sensor reading ingested (flood risk change)
 *
 * In production with multiple API servers, replace this with Redis pub/sub
 * (e.g., ioredis). For the hackathon (single process), this is sufficient.
 */

export type EventType =
  | 'route_update'
  | 'mission_update'
  | 'sla_alert'
  | 'triage_decision'
  | 'vehicle_update'
  | 'conflict_detected'
  | 'sensor_update';

export interface BusEvent {
  type: EventType;
  data: Record<string, unknown>;
  timestamp: string;
}

class EventBusService extends EventEmitter {
  private static instance: EventBusService;

  static getInstance(): EventBusService {
    if (!EventBusService.instance) {
      EventBusService.instance = new EventBusService();
      // Raise the limit — dashboards hold one listener per connected client
      EventBusService.instance.setMaxListeners(200);
    }
    return EventBusService.instance;
  }

  /**
   * Publish an event to all SSE subscribers.
   * Call this from any controller after a state-changing operation.
   *
   * Example:
   *   EventBus.publish('route_update', { routeId: 7, isFlooded: true })
   */
  publish(type: EventType, data: Record<string, unknown>): void {
    const event: BusEvent = {
      type,
      data,
      timestamp: new Date().toISOString(),
    };
    this.emit('event', event);
  }
}

export const EventBus = EventBusService.getInstance();
