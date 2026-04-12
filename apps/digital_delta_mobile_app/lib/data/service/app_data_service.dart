import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../datasource/local/source/connectivity_data_source.dart';
import '../datasource/remote/util/api_client.dart';
import 'sync_mesh_service.dart';

/// Offline-first data service for fleet, network graph, dashboard stats,
/// and mission data. Uses SharedPreferences for a 10-minute JSON cache with
/// stale-while-revalidate: API → fresh cache → stale cache → hardcoded seed.
///
/// When online, also performs CRDT push/pull with the server (M2.4).
class AppDataService {
  final ApiClient _api;
  final ConnectivityDataSource _connectivity;
  final SharedPreferences _prefs;
  final SyncMeshService _syncMesh;

  static const _ttlMs = 10 * 60 * 1000; // 10 minutes
  static const _keyPrefix = 'adc_';

  Future<bool> _isOnline() async {
    final status = await _connectivity.currentStatus;
    return status.when(online: (_) => true, offline: () => false);
  }

  AppDataService({
    required ApiClient api,
    required ConnectivityDataSource connectivity,
    required SharedPreferences prefs,
    required SyncMeshService syncMesh,
  })  : _api = api,
        _connectivity = connectivity,
        _prefs = prefs,
        _syncMesh = syncMesh;

  // ── Cache helpers ──────────────────────────────────────────────────────────

  void _put(String key, dynamic data) {
    _prefs.setString(
      '$_keyPrefix$key',
      jsonEncode({'v': data, 't': DateTime.now().millisecondsSinceEpoch}),
    );
  }

  dynamic _read(String key, {bool stale = false}) {
    final raw = _prefs.getString('$_keyPrefix$key');
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map;
    if (!stale) {
      final age = DateTime.now().millisecondsSinceEpoch - (m['t'] as int);
      if (age > _ttlMs) return null;
    }
    return m['v'];
  }

  void _invalidate(String key) => _prefs.remove('$_keyPrefix$key');

  Future<T> _fetch<T>({
    required String cacheKey,
    required String path,
    required T Function(dynamic raw) parse,
    required T Function() fallback,
  }) async {
    // 1. Fresh cache hit
    final fresh = _read(cacheKey);
    if (fresh != null) return parse(fresh);

    // 2. Online → fetch from API and cache
    if (await _isOnline()) {
      try {
        final res = await _api.get(path);
        final data = res.data['data'];
        if (data != null) {
          _put(cacheKey, data);
          return parse(data);
        }
      } on DioException catch (_) {
        // Connection issue — fall through to stale / seed
      } catch (_) {
        // Unexpected error — fall through
      }
    }

    // 3. Stale cache (ignores TTL)
    final stale = _read(cacheKey, stale: true);
    if (stale != null) return parse(stale);

    // 4. Hardcoded seed data as last resort
    return fallback();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() => _fetch(
        cacheKey: 'dashboard',
        path: '/api/dashboard',
        parse: (d) => Map<String, dynamic>.from(d as Map),
        fallback: _seedDashboard,
      );

  Future<List<Map<String, dynamic>>> getVehicles() => _fetch(
        cacheKey: 'vehicles',
        path: '/api/vehicles',
        parse: (d) => List<Map<String, dynamic>>.from(d as List),
        fallback: _seedVehicles,
      );

  Future<Map<String, dynamic>> getNetworkGraph() => _fetch(
        cacheKey: 'network_graph',
        path: '/api/network/graph',
        parse: (d) => Map<String, dynamic>.from(d as Map),
        fallback: _seedNetworkGraph,
      );

  Future<List<Map<String, dynamic>>> getMissions() => _fetch(
        cacheKey: 'missions',
        path: '/api/missions',
        parse: (d) => List<Map<String, dynamic>>.from(d as List),
        fallback: _seedMissions,
      );

  Future<List<Map<String, dynamic>>> getInventory() => _fetch(
        cacheKey: 'inventory',
        path: '/api/supply/inventory',
        parse: (d) => List<Map<String, dynamic>>.from(d as List),
        fallback: () => [],
      );

  /// Force-invalidate all caches and re-fetch from API.
  /// Also performs CRDT push/pull (M2.4) when device is online.
  Future<void> syncAll() async {
    if (!await _isOnline()) return;

    // ── CRDT server sync (M2.4) ───────────────────────────────────────────────
    await _syncCrdtWithServer();

    // ── Invalidate + re-fetch all REST caches ─────────────────────────────────
    for (final k in ['dashboard', 'vehicles', 'network_graph', 'missions', 'inventory']) {
      _invalidate(k);
    }
    await Future.wait([
      getDashboardStats(),
      getVehicles(),
      getNetworkGraph(),
      getMissions(),
    ]);
  }

  /// Push unsynced local CRDT ops to server; pull new ops from server.
  Future<void> _syncCrdtWithServer() async {
    final nodeUuid = _syncMesh.localNodeUuid;

    // 1. Ensure node is registered (idempotent)
    try {
      await _api.post('/api/sync/nodes/register', data: {
        'node_uuid': nodeUuid,
        'node_type': 'mobile',
        'public_key': jsonDecode(_syncMesh.getLocalNodeIdentity())['public_key'] ?? '',
      });
    } on DioException catch (_) {
      // Node may already exist (409/200 both fine); continue
    } catch (_) {}

    // 2. Push unsynced ops
    final unsyncedOps = _syncMesh.getUnsyncedOps();
    if (unsyncedOps.isNotEmpty) {
      try {
        final ops = unsyncedOps.map((op) => {
          'operation_uuid': op['operation_uuid'],
          'op_type': op['op_type'],
          'entity_type': op['entity_type'],
          'entity_id': op['entity_id'],
          'field_name': op['field_name'],
          'old_value': op['old_value'] != null ? jsonDecode(op['old_value'] as String) : null,
          'new_value': jsonDecode(op['new_value'] as String),
          'vector_clock': jsonDecode(op['vector_clock'] as String),
          'created_at': op['created_at'],
        }).toList();

        await _api.post('/api/sync/push', data: {
          'node_uuid': nodeUuid,
          'operations': ops,
        });

        _syncMesh.markOpsAsSynced(
          unsyncedOps.map((o) => o['operation_uuid'] as String).toList(),
        );
      } on DioException catch (_) {
        // Push failed — keep ops pending for next sync attempt
      } catch (_) {}
    }

    // 3. Pull new ops from server using current vector clock
    try {
      final vc = jsonEncode(_syncMesh.currentVectorClock);
      final res = await _api.get(
        '/api/sync/pull',
        queryParameters: {'node_uuid': nodeUuid, 'vc': vc},
      );
      final data = res.data['data'];
      if (data != null) {
        final serverOps = data['operations'];
        if (serverOps is List && serverOps.isNotEmpty) {
          await _syncMesh.applyServerOps(
            serverOps.map((o) => Map<String, dynamic>.from(o as Map)).toList(),
          );
        }
      }
    } on DioException catch (_) {
      // Pull failed — local data remains; will retry next time
    } catch (_) {}
  }

  // ── Seed / fallback data (real Bangladesh coordinates) ────────────────────

  Map<String, dynamic> _seedDashboard() => {
        'missions': {
          'total': 8,
          'active': 3,
          'completed': 4,
          'planned': 1,
          'sla_breached': 1,
        },
        'vehicles': {
          'total': 5,
          'idle': 2,
          'in_mission': 3,
          'offline': 0,
        },
        'locations': {
          'total': 6,
          'flooded': 1,
          'active': 6,
        },
        'critical_low_stock': 2,
        'mesh_pending': 3,
        'triage_24h': 5,
      };

  List<Map<String, dynamic>> _seedVehicles() => [
        {
          'id': 1,
          'identifier': 'TRK-001',
          'name': 'Supply Truck Alpha',
          'type': 'truck',
          'status': 'in_mission',
          'fuel_level': 85.0,
          'battery_level': null,
          'current_location_id': 1,
          'operator': {'name': 'Karim Ahmed'},
        },
        {
          'id': 2,
          'identifier': 'BOAT-012',
          'name': 'River Runner',
          'type': 'speedboat',
          'status': 'in_mission',
          'fuel_level': 62.0,
          'battery_level': null,
          'current_location_id': 2,
          'operator': {'name': 'Rahim Mia'},
        },
        {
          'id': 3,
          'identifier': 'DRN-005',
          'name': 'Aerial Scout',
          'type': 'drone',
          'status': 'idle',
          'fuel_level': null,
          'battery_level': 34.0,
          'current_location_id': 5,
          'operator': {'name': 'Auto-Pilot'},
        },
        {
          'id': 4,
          'identifier': 'TRK-008',
          'name': 'Logistics Carrier',
          'type': 'truck',
          'status': 'idle',
          'fuel_level': 100.0,
          'battery_level': null,
          'current_location_id': 1,
          'operator': {'name': 'Nasir Uddin'},
        },
        {
          'id': 5,
          'identifier': 'BOAT-007',
          'name': 'Flood Patrol',
          'type': 'speedboat',
          'status': 'in_mission',
          'fuel_level': 71.0,
          'battery_level': null,
          'current_location_id': 3,
          'operator': {'name': 'Jamal Hossain'},
        },
      ];

  Map<String, dynamic> _seedNetworkGraph() => {
        'nodes': [
          {
            'id': 1,
            'code': 'N1',
            'name': 'Sylhet City Command',
            'type': 'central_command',
            'lat': 24.8949,
            'lng': 91.8687,
            'is_flooded': false,
            'capacity': null,
            'current_occupancy': 0,
          },
          {
            'id': 2,
            'code': 'N2',
            'name': 'Companiganj Relief Camp',
            'type': 'relief_camp',
            'lat': 24.994,
            'lng': 91.644,
            'is_flooded': false,
            'capacity': 500,
            'current_occupancy': 312,
          },
          {
            'id': 3,
            'code': 'N3',
            'name': 'Shahjalal Hospital',
            'type': 'hospital',
            'lat': 24.9045,
            'lng': 91.866,
            'is_flooded': false,
            'capacity': 200,
            'current_occupancy': 143,
          },
          {
            'id': 4,
            'code': 'N4',
            'name': 'Sunamganj Supply Drop',
            'type': 'supply_drop',
            'lat': 25.0666,
            'lng': 91.3993,
            'is_flooded': true,
            'capacity': null,
            'current_occupancy': 0,
          },
          {
            'id': 5,
            'code': 'N5',
            'name': 'Ratargul Drone Base',
            'type': 'drone_base',
            'lat': 25.0219,
            'lng': 91.9572,
            'is_flooded': false,
            'capacity': null,
            'current_occupancy': 0,
          },
          {
            'id': 6,
            'code': 'N6',
            'name': 'Jaintiapur Waypoint',
            'type': 'waypoint',
            'lat': 25.1379,
            'lng': 92.1138,
            'is_flooded': false,
            'capacity': null,
            'current_occupancy': 0,
          },
        ],
        'edges': [
          {
            'id': 1,
            'code': 'E1',
            'source': 1,
            'target': 2,
            'type': 'road',
            'current_travel_mins': 90,
            'is_flooded': false,
            'is_blocked': false,
            'risk_score': 0.35,
          },
          {
            'id': 2,
            'code': 'E2',
            'source': 1,
            'target': 3,
            'type': 'road',
            'current_travel_mins': 25,
            'is_flooded': false,
            'is_blocked': false,
            'risk_score': 0.05,
          },
          {
            'id': 3,
            'code': 'E3',
            'source': 2,
            'target': 4,
            'type': 'river',
            'current_travel_mins': 150,
            'is_flooded': true,
            'is_blocked': false,
            'risk_score': 0.65,
          },
          {
            'id': 4,
            'code': 'E4',
            'source': 3,
            'target': 5,
            'type': 'road',
            'current_travel_mins': 75,
            'is_flooded': false,
            'is_blocked': false,
            'risk_score': 0.2,
          },
          {
            'id': 5,
            'code': 'E5',
            'source': 4,
            'target': 5,
            'type': 'airway',
            'current_travel_mins': 30,
            'is_flooded': false,
            'is_blocked': false,
            'risk_score': 0.1,
          },
          {
            'id': 6,
            'code': 'E6',
            'source': 2,
            'target': 5,
            'type': 'airway',
            'current_travel_mins': 35,
            'is_flooded': false,
            'is_blocked': false,
            'risk_score': 0.1,
          },
          {
            'id': 7,
            'code': 'E7',
            'source': 1,
            'target': 6,
            'type': 'road',
            'current_travel_mins': 90,
            'is_flooded': false,
            'is_blocked': false,
            'risk_score': 0.25,
          },
        ],
      };

  List<Map<String, dynamic>> _seedMissions() => [
        {
          'id': 1,
          'mission_code': 'MSN-2026-0001',
          'status': 'active',
          'priority_class': 'p0_critical',
          'sla_breached': false,
          'origin_location_id': 1,
          'destination_location_id': 3,
          'vehicle_id': 1,
        },
        {
          'id': 2,
          'mission_code': 'MSN-2026-0002',
          'status': 'active',
          'priority_class': 'p1_high',
          'sla_breached': false,
          'origin_location_id': 1,
          'destination_location_id': 2,
          'vehicle_id': 2,
        },
        {
          'id': 3,
          'mission_code': 'MSN-2026-0003',
          'status': 'planned',
          'priority_class': 'p2_standard',
          'sla_breached': false,
          'origin_location_id': 3,
          'destination_location_id': 5,
          'vehicle_id': 4,
        },
      ];
}
