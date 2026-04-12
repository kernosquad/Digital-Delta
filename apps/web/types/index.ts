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
