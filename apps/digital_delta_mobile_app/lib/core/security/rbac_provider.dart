/// Riverpod providers for RBAC – reactive to profile changes.
///
/// Usage:
///   final guard = ref.watch(rbacGuardProvider);
///   if (guard.can(Permission.controlDrones)) { ... }

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/cache_module.dart';
import '../../data/datasource/local/source/auth_local_data_source.dart';
import '../../presentation/screen/auth/notifier/user_profile_provider.dart';
import 'rbac.dart';

/// Derives the authenticated user's role.
/// Watches [refreshableUserProfileProvider]; falls back to the local
/// SharedPreferences cache while the async load is in-flight or on error.
final currentRoleProvider = Provider<UserRole>((ref) {
  final asyncUser = ref.watch(refreshableUserProfileProvider);
  return asyncUser.when(
    data: (user) => UserRole.fromString(user?.role ?? 'field_volunteer'),
    loading: () {
      final cached = getIt<AuthLocalDataSource>().getCurrentUser();
      return UserRole.fromString(cached?.role ?? 'field_volunteer');
    },
    error: (_, __) => UserRole.fieldVolunteer,
  );
});

/// An [RBACGuard] scoped to the current user. Reactive – rebuilds whenever
/// the user's role changes (e.g. after profile refresh or re-login).
final rbacGuardProvider = Provider<RBACGuard>((ref) {
  return RBACGuard(ref.watch(currentRoleProvider));
});
