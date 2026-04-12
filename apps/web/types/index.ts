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
