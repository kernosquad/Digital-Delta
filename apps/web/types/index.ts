// ── API response envelope ─────────────────────────────────────────────────────

export interface ApiResponse<T> {
  status: number;
  data: T;
  message?: string;
}

export interface ApiError {
  status: number;
  errors: { message: string; field?: string }[];
}

// ── Auth ──────────────────────────────────────────────────────────────────────

export type UserRole =
  | 'field_volunteer'
  | 'supply_manager'
  | 'drone_operator'
  | 'camp_commander'
  | 'sync_admin';

export type UserStatus = 'active' | 'inactive' | 'suspended';

export interface User {
  id: number;
  name: string;
  email: string;
  phone: string | null;
  role: UserRole;
  status: UserStatus;
  last_seen_at: string | null;
}

// ── Vehicles ──────────────────────────────────────────────────────────────────

export type VehicleType = 'truck' | 'boat' | 'drone' | 'motorcycle' | 'helicopter';
export type VehicleStatus = 'idle' | 'in_mission' | 'offline' | 'maintenance';

export interface Vehicle {
  id: number;
  name: string;
  type: VehicleType;
  status: VehicleStatus;
  capacity_kg: number;
  current_location_id: number | null;
  operator_id: number | null;
  last_gps_lat: string | null;
  last_gps_lng: string | null;
  last_gps_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

// ── Locations ─────────────────────────────────────────────────────────────────

export type LocationType = 'camp' | 'hospital' | 'warehouse' | 'checkpoint' | 'staging';

export interface Location {
  id: number;
  node_code: string;
  name: string;
  type: LocationType;
  lat: string;
  lng: string;
  is_flooded: boolean;
  is_active: boolean;
  max_capacity: number;
  current_occupancy: number;
  contact_name: string | null;
  contact_phone: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

// ── Supply ────────────────────────────────────────────────────────────────────

export type PriorityClass = 'p0_critical' | 'p1_high' | 'p2_standard' | 'p3_low';

export interface InventoryRow {
  location: string;
  node_code: string;
  item: string;
  category: string;
  unit: string;
  priority_class: PriorityClass;
  quantity: number;
  reserved_quantity: number;
}

// ── Missions ──────────────────────────────────────────────────────────────────

export type MissionStatus = 'planned' | 'active' | 'completed' | 'preempted' | 'cancelled';

export interface Mission {
  id: number;
  mission_code: string;
  status: MissionStatus;
  priority_class: PriorityClass;
  origin_location_id: number;
  destination_location_id: number;
  vehicle_id: number;
  driver_id: number | null;
  total_payload_kg: number;
  sla_deadline: string;
  sla_breached: boolean;
  preempted_by_mission_id: number | null;
  preemption_reason: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
  // joined fields
  origin_name: string;
  destination_name: string;
  vehicle_name: string;
  vehicle_type: VehicleType;
}

// ── Triage ────────────────────────────────────────────────────────────────────

export interface TriageDecision {
  id: number;
  mission_id: number;
  mission_code: string;
  triggered_by: string;
  rationale: string;
  preempted_mission_id: number | null;
  old_route: string | null;
  new_route: string | null;
  created_at: string;
}

// ── Network ───────────────────────────────────────────────────────────────────

export type RouteType = 'road' | 'river' | 'airway';

export interface NetworkEdge {
  id: number;
  edge_code: string;
  source_location_id: number;
  target_location_id: number;
  source_name?: string;
  target_name?: string;
  route_type: RouteType;
  base_travel_mins: number;
  current_travel_mins: number | null;
  max_payload_kg: number | null;
  allowed_vehicles: string[] | null;
  is_flooded: boolean;
  is_blocked: boolean;
  risk_score: number | null;
  created_at: string;
  updated_at: string;
}

// ── Handoff ───────────────────────────────────────────────────────────────────

export type HandoffStatus = 'scheduled' | 'in_progress' | 'completed' | 'failed';

export interface Handoff {
  id: number;
  mission_id: number;
  drone_vehicle_id: number;
  ground_vehicle_id: number;
  rendezvous_location_id: number | null;
  rendezvous_lat: number;
  rendezvous_lng: number;
  scheduled_at: string;
  completed_at: string | null;
  status: HandoffStatus;
  mission_code?: string;
  drone_name?: string;
  ground_name?: string;
  created_at: string;
}

// ── Supply Item ───────────────────────────────────────────────────────────────

export type SupplyCategory = 'medical' | 'food' | 'water' | 'shelter' | 'equipment' | 'other';

export interface SupplyItem {
  id: number;
  name: string;
  category: SupplyCategory;
  unit: string;
  weight_per_unit_kg: number;
  priority_class: PriorityClass;
  sla_hours: number;
  created_at: string;
}

// ── Sensor ────────────────────────────────────────────────────────────────────

export type SensorReadingType =
  | 'rainfall_mm'
  | 'water_level_cm'
  | 'wind_speed_kmh'
  | 'soil_saturation_pct'
  | 'temperature_c';

export interface SensorReading {
  id: number;
  location_id: number;
  reading_type: SensorReadingType;
  value: number;
  recorded_at: string;
  source: 'sensor' | 'mock_api' | 'manual';
  location_name?: string;
  created_at: string;
}

export interface RoutePrediction {
  edge_id: number;
  edge_code: string;
  impassability_probability: number;
  predicted_at: string;
  features: Record<string, number>;
}

// ── Sync ──────────────────────────────────────────────────────────────────────

export interface SyncConflict {
  id: number;
  table_name: string;
  record_id: string;
  node_a_id: string;
  node_b_id: string;
  node_a_value: Record<string, unknown>;
  node_b_value: Record<string, unknown>;
  vector_clock_a: Record<string, number>;
  vector_clock_b: Record<string, number>;
  status: 'pending' | 'resolved';
  resolution: string | null;
  resolved_at: string | null;
  created_at: string;
}

export interface SyncNode {
  id: string;
  device_id: string;
  last_seen_at: string;
  vector_clock: Record<string, number>;
  is_online: boolean;
}

// ── Dashboard stats ───────────────────────────────────────────────────────────

export interface DashboardStats {
  missions: {
    total: number;
    active: number;
    completed: number;
    planned: number;
    sla_breached: number;
  };
  vehicles: {
    total: number;
    idle: number;
    in_mission: number;
    offline: number;
  };
  locations: {
    total: number;
    flooded: number;
    active: number;
  };
  inventory: {
    critical_items_low: number;
  };
  mesh_messages: {
    pending: number;
    total_24h: number;
  };
  triage_decisions: {
    last_24h: number;
  };
  timestamp: string;
}
