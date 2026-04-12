/// M1.3 - Role-Based Access Control (RBAC)
/// 
/// Defines user roles and their permissions for the Digital Delta system.
/// Each role has specific read/write/execute permissions enforced at the data layer.

/// User roles in the Digital Delta disaster response system
enum UserRole {
  /// Field-level volunteers conducting ground operations
  /// Permissions: Read supply data, Submit PoD, Update location
  fieldVolunteer('field_volunteer', 'Field Volunteer'),

  /// Manages supply inventory and distribution
  /// Permissions: All field_volunteer + Manage inventory, Approve deliveries
  supplyManager('supply_manager', 'Supply Manager'),

  /// Operates autonomous drones for last-mile delivery
  /// Permissions: Control drones, View airspace, Execute drone deliveries
  droneOperator('drone_operator', 'Drone Operator'),

  /// Coordinates relief camp operations
  /// Permissions: All supply_manager + Manage camp resources, Triage priority
  campCommander('camp_commander', 'Camp Commander'),

  /// Administers sync infrastructure and resolves CRDT conflicts
  /// Permissions: Admin-level access, Manage sync nodes, Resolve conflicts
  syncAdmin('sync_admin', 'Sync Admin');

  final String value;
  final String displayName;

  const UserRole(this.value, this.displayName);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.fieldVolunteer,
    );
  }

  /// Check if role has permission for a specific action
  bool hasPermission(Permission permission) {
    return _rolePermissions[this]?.contains(permission) ?? false;
  }

  /// Get all permissions for this role
  Set<Permission> get permissions => _rolePermissions[this] ?? {};

  /// Check if this role can perform an action on specific resource
  bool canPerform(String action, {String? resource}) {
    // TODO: Implement fine-grained permission checking
    // For now, use basic permission model
    return true;
  }
}

/// Granular permissions for RBAC system
enum Permission {
  // Read permissions
  readSupplyData('read_supply_data'),
  readRouteData('read_route_data'),
  readUserData('read_user_data'),
  readAuditLogs('read_audit_logs'),
  readMeshNetwork('read_mesh_network'),

  // Write permissions
  submitProofOfDelivery('submit_pod'),
  updateLocation('update_location'),
  manageInventory('manage_inventory'),
  approveDeliveries('approve_deliveries'),
  createRoutes('create_routes'),

  // Execute permissions
  controlDrones('control_drones'),
  executeDelivery('execute_delivery'),
  triagePriority('triage_priority'),
  resolveCRDTConflicts('resolve_crdt_conflicts'),
  manageSyncNodes('manage_sync_nodes'),
  manageUsers('manage_users'),
  manageRoles('manage_roles');

  final String value;
  const Permission(this.value);
}

/// Role-Permission mapping
const Map<UserRole, Set<Permission>> _rolePermissions = {
  UserRole.fieldVolunteer: {
    Permission.readSupplyData,
    Permission.readRouteData,
    Permission.submitProofOfDelivery,
    Permission.updateLocation,
  },
  UserRole.supplyManager: {
    // Inherits field_volunteer permissions
    Permission.readSupplyData,
    Permission.readRouteData,
    Permission.submitProofOfDelivery,
    Permission.updateLocation,
    // Additional permissions
    Permission.manageInventory,
    Permission.approveDeliveries,
    Permission.createRoutes,
    Permission.readUserData,
  },
  UserRole.droneOperator: {
    Permission.readSupplyData,
    Permission.readRouteData,
    Permission.controlDrones,
    Permission.executeDelivery,
    Permission.updateLocation,
  },
  UserRole.campCommander: {
    // Inherits supply_manager permissions
    Permission.readSupplyData,
    Permission.readRouteData,
    Permission.submitProofOfDelivery,
    Permission.updateLocation,
    Permission.manageInventory,
    Permission.approveDeliveries,
    Permission.createRoutes,
    Permission.readUserData,
    // Additional permissions
    Permission.triagePriority,
    Permission.readAuditLogs,
    Permission.executeDelivery,
  },
  UserRole.syncAdmin: {
    // Admin-level permissions (all)
    Permission.readSupplyData,
    Permission.readRouteData,
    Permission.readUserData,
    Permission.readAuditLogs,
    Permission.readMeshNetwork,
    Permission.submitProofOfDelivery,
    Permission.updateLocation,
    Permission.manageInventory,
    Permission.approveDeliveries,
    Permission.createRoutes,
    Permission.controlDrones,
    Permission.executeDelivery,
    Permission.triagePriority,
    Permission.resolveCRDTConflicts,
    Permission.manageSyncNodes,
    Permission.manageUsers,
    Permission.manageRoles,
  },
};

/// RBAC Guard - Used to check permissions in UI and business logic
class RBACGuard {
  final UserRole role;

  RBACGuard(this.role);

  /// Check if user has a specific permission
  bool can(Permission permission) {
    return role.hasPermission(permission);
  }

  /// Check if user has any of the specified permissions
  bool canAny(List<Permission> permissions) {
    return permissions.any((p) => can(p));
  }

  /// Check if user has all of the specified permissions
  bool canAll(List<Permission> permissions) {
    return permissions.every((p) => can(p));
  }

  /// Check if user cannot perform an action (for assertions)
  bool cannot(Permission permission) {
    return !can(permission);
  }

  /// Get all permissions for current role
  Set<Permission> get allPermissions => role.permissions;

  /// Check if role is admin-level (Camp Commander or Sync Admin)
  bool get isAdmin =>
      role == UserRole.campCommander || role == UserRole.syncAdmin;

  /// Check if role can manage resources
  bool get canManageResources =>
      role == UserRole.supplyManager ||
      role == UserRole.campCommander ||
      role == UserRole.syncAdmin;
}

/// Exception thrown when user tries to perform unauthorized action
class PermissionDeniedException implements Exception {
  final String message;
  final Permission requiredPermission;
  final UserRole userRole;

  PermissionDeniedException({
    required this.message,
    required this.requiredPermission,
    required this.userRole,
  });

  @override
  String toString() {
    return 'PermissionDeniedException: $message. '
        'Required: ${requiredPermission.value}, '
        'User role: ${userRole.displayName}';
  }
}
