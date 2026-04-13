import 'package:dio/dio.dart';

import '../datasource/local/source/connectivity_data_source.dart';
import '../datasource/remote/util/api_client.dart';

/// Reads optional metadata from [apps/api/app/modules/sync/sync.route.ts] when online.
/// Push/pull CRDT traffic is handled by [AppDataService.syncAll].
class SyncServerSnapshot {
  final bool offline;
  final List<Map<String, dynamic>> meshNodes;
  final List<Map<String, dynamic>> openConflicts;
  /// Human-readable notes (e.g. role restrictions).
  final List<String> notes;

  const SyncServerSnapshot({
    required this.offline,
    required this.meshNodes,
    required this.openConflicts,
    this.notes = const [],
  });

  static SyncServerSnapshot offlineMode() => const SyncServerSnapshot(
        offline: true,
        meshNodes: [],
        openConflicts: [],
        notes: [],
      );
}

class SyncRemoteApiService {
  final ApiClient _api;
  final ConnectivityDataSource _connectivity;

  SyncRemoteApiService({
    required ApiClient api,
    required ConnectivityDataSource connectivity,
  })  : _api = api,
        _connectivity = connectivity;

  Future<bool> _isOnline() async {
    final s = await _connectivity.currentStatus;
    return s.when(online: (_) => true, offline: () => false);
  }

  /// GET `/api/sync/nodes` and `/api/sync/conflicts` (role-gated on server).
  Future<SyncServerSnapshot> fetchServerSnapshot() async {
    if (!await _isOnline()) return SyncServerSnapshot.offlineMode();

    final notes = <String>[];
    var nodes = <Map<String, dynamic>>[];
    var conflicts = <Map<String, dynamic>>[];

    try {
      final res = await _api.get('/api/sync/nodes');
      final raw = res.data['data'];
      if (raw is List) {
        nodes = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        notes.add('Mesh nodes: requires camp_commander or sync_admin');
      } else if (e.response?.statusCode == 401) {
        notes.add('Mesh nodes: sign in required');
      }
    } catch (_) {}

    try {
      final res = await _api.get('/api/sync/conflicts');
      final raw = res.data['data'];
      if (raw is List) {
        conflicts = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        notes.add('Open conflicts: requires camp_commander or sync_admin');
      } else if (e.response?.statusCode == 401) {
        notes.add('Open conflicts: sign in required');
      }
    } catch (_) {}

    return SyncServerSnapshot(
      offline: false,
      meshNodes: nodes,
      openConflicts: conflicts,
      notes: notes,
    );
  }
}
