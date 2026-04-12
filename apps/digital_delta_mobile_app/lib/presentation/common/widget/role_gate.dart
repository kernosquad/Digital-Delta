/// Conditionally renders [child] based on RBAC permissions.
///
/// Examples:
///   // Single permission
///   RoleGate(
///     permission: Permission.controlDrones,
///     child: DroneControlButton(),
///   )
///
///   // Any of several permissions
///   RoleGate.any(
///     permissions: [Permission.manageInventory, Permission.approveDeliveries],
///     child: InventoryPanel(),
///   )
///
///   // Role whitelist
///   RoleGate.roles(
///     roles: [UserRole.syncAdmin, UserRole.campCommander],
///     child: AdminPanel(),
///   )
///
///   // Provide a fallback instead of hiding
///   RoleGate(
///     permission: Permission.manageUsers,
///     child: AdminButton(),
///     fallback: Text('No access'),
///   )

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/rbac.dart';
import '../../../core/security/rbac_provider.dart';

class RoleGate extends ConsumerWidget {
  final Widget child;
  final Widget fallback;
  final Permission? _permission;
  final List<Permission>? _anyPermissions;
  final List<UserRole>? _roles;
  final _Mode _mode;

  /// Show [child] only when the current user has [permission].
  const RoleGate({
    super.key,
    required Permission permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  })  : _permission = permission,
        _anyPermissions = null,
        _roles = null,
        _mode = _Mode.single;

  /// Show [child] when the current user has **any** of [permissions].
  const RoleGate.any({
    super.key,
    required List<Permission> permissions,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  })  : _permission = null,
        _anyPermissions = permissions,
        _roles = null,
        _mode = _Mode.any;

  /// Show [child] when the current user's role is in [roles].
  const RoleGate.roles({
    super.key,
    required List<UserRole> roles,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  })  : _permission = null,
        _anyPermissions = null,
        _roles = roles,
        _mode = _Mode.roleList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guard = ref.watch(rbacGuardProvider);
    final allowed = switch (_mode) {
      _Mode.single => guard.can(_permission!),
      _Mode.any => guard.canAny(_anyPermissions!),
      _Mode.roleList => _roles!.contains(guard.role),
    };
    return allowed ? child : fallback;
  }
}

enum _Mode { single, any, roleList }
