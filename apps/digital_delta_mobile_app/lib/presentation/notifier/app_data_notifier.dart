import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/service/app_data_service.dart';
import '../../di/cache_module.dart';

/// Immutable snapshot of all app-level data fetched from the API (or cache/seed).
class AppDataSnapshot {
  final Map<String, dynamic> dashboardStats;
  final List<Map<String, dynamic>> vehicles;
  final Map<String, dynamic> networkGraph;
  final List<Map<String, dynamic>> missions;

  const AppDataSnapshot({
    required this.dashboardStats,
    required this.vehicles,
    required this.networkGraph,
    required this.missions,
  });

  // ── Convenience getters ────────────────────────────────────────────────────

  List<Map<String, dynamic>> get nodes =>
      List<Map<String, dynamic>>.from(networkGraph['nodes'] as List? ?? []);

  List<Map<String, dynamic>> get edges =>
      List<Map<String, dynamic>>.from(networkGraph['edges'] as List? ?? []);

  Map<String, dynamic> get missionStats =>
      Map<String, dynamic>.from(dashboardStats['missions'] as Map? ?? {});

  Map<String, dynamic> get vehicleStats =>
      Map<String, dynamic>.from(dashboardStats['vehicles'] as Map? ?? {});

  int get activeMissions => (missionStats['active'] as num?)?.toInt() ?? 0;
  int get activeVehicles => (vehicleStats['in_mission'] as num?)?.toInt() ?? 0;
  int get totalVehicles => (vehicleStats['total'] as num?)?.toInt() ?? vehicles.length;
  int get criticalLowStock => (dashboardStats['critical_low_stock'] as num?)?.toInt() ?? 0;
  int get slaBreached => (missionStats['sla_breached'] as num?)?.toInt() ?? 0;
  int get meshPending => (dashboardStats['mesh_pending'] as num?)?.toInt() ?? 0;
}

class AppDataNotifier extends StateNotifier<AsyncValue<AppDataSnapshot>> {
  AppDataNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  AppDataService get _service => getIt<AppDataService>();

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getDashboardStats(),
        _service.getVehicles(),
        _service.getNetworkGraph(),
        _service.getMissions(),
      ]);
      state = AsyncValue.data(AppDataSnapshot(
        dashboardStats: results[0] as Map<String, dynamic>,
        vehicles: results[1] as List<Map<String, dynamic>>,
        networkGraph: results[2] as Map<String, dynamic>,
        missions: results[3] as List<Map<String, dynamic>>,
      ));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }

  /// Invalidates all caches, re-fetches from API, then refreshes state.
  /// Called when device comes back online.
  Future<void> syncAndRefresh() async {
    try {
      await _service.syncAll();
    } catch (_) {
      // Ignore sync errors — still refresh from whatever is available
    }
    await refresh();
  }
}

final appDataNotifierProvider =
    StateNotifierProvider<AppDataNotifier, AsyncValue<AppDataSnapshot>>(
  (ref) => AppDataNotifier(),
);
