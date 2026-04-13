import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

import '../../connectivity/notifier/provider.dart';
import '../../notifier/app_data_notifier.dart';
import '../../theme/color.dart';

// ── Data models ─────────────────────────────────────────────────────────────

class _NodeData {
  final int id;
  final String code;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final bool isFlooded;
  final int? capacity;
  final int occupancy;

  const _NodeData({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.isFlooded,
    this.capacity,
    required this.occupancy,
  });

  factory _NodeData.fromMap(Map<String, dynamic> m) => _NodeData(
    id: (m['id'] as num).toInt(),
    code: m['code'] as String,
    name: m['name'] as String,
    type: m['type'] as String,
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    isFlooded: m['is_flooded'] == true || m['is_flooded'] == 1,
    capacity: m['capacity'] != null ? (m['capacity'] as num).toInt() : null,
    occupancy: (m['current_occupancy'] as num? ?? 0).toInt(),
  );
}

class _EdgeData {
  final String code;
  final int sourceId;
  final int targetId;
  final String type;
  final bool isFlooded;
  final bool isBlocked;
  final double risk;
  final int travelMins;

  const _EdgeData({
    required this.code,
    required this.sourceId,
    required this.targetId,
    required this.type,
    required this.isFlooded,
    required this.isBlocked,
    required this.risk,
    required this.travelMins,
  });

  factory _EdgeData.fromMap(Map<String, dynamic> m) => _EdgeData(
    code: m['code'] as String,
    sourceId: (m['source'] as num).toInt(),
    targetId: (m['target'] as num).toInt(),
    type: m['type'] as String,
    isFlooded: m['is_flooded'] == true || m['is_flooded'] == 1,
    isBlocked: m['is_blocked'] == true || m['is_blocked'] == 1,
    risk: (m['risk_score'] as num? ?? 0).toDouble(),
    travelMins: (m['current_travel_mins'] as num? ?? 0).toInt(),
  );
}

// ── Colour helpers ────────────────────────────────────────────────────────────

Color _nodeColor(String type, bool flooded) {
  if (flooded) return AppColors.dangerSurfaceDefault;
  return switch (type) {
    'central_command' => AppColors.nodeCommand,
    'relief_camp' => AppColors.nodeReliefCamp,
    'hospital' => AppColors.nodeHospital,
    'supply_drop' => AppColors.nodeSupplyDrop,
    'drone_base' => AppColors.nodeDroneBase,
    'waypoint' => AppColors.nodeWaypoint,
    _ => AppColors.nodeWaypoint,
  };
}

IconData _nodeIcon(String type) => switch (type) {
  'central_command' => Icons.account_balance,
  'relief_camp' => Icons.home_work_outlined,
  'hospital' => Icons.local_hospital,
  'supply_drop' => Icons.inventory_2_outlined,
  'drone_base' => Icons.flight_takeoff,
  'waypoint' => Icons.radio_button_checked,
  _ => Icons.place,
};

Color _edgeColor(String type) => switch (type) {
  'road' => const Color(0xFF607D8B),
  'river' => const Color(0xFF1565C0),
  'airway' => const Color(0xFF6A1B9A),
  _ => const Color(0xFF78909C),
};

String _nodeTypeLabel(String type) => switch (type) {
  'central_command' => 'Command HQ',
  'relief_camp' => 'Relief Camp',
  'hospital' => 'Hospital',
  'supply_drop' => 'Supply Drop',
  'drone_base' => 'Drone Base',
  'waypoint' => 'Waypoint',
  _ => type,
};

Color _vehicleStatusColor(String status) => switch (status) {
  'in_mission' => const Color(0xFF2E7D32),
  'idle' => const Color(0xFF455A64),
  'maintenance' => const Color(0xFFE65100),
  'offline' => const Color(0xFFC62828),
  _ => const Color(0xFF9E9E9E),
};

IconData _vehicleIcon(String type) => switch (type) {
  'truck' => Icons.local_shipping,
  'speedboat' => Icons.directions_boat,
  'drone' => Icons.airplanemode_active,
  _ => Icons.commute,
};

// ── ML helpers ────────────────────────────────────────────────────────────────

Map<String, dynamic> _generateNodeMlPrediction(_NodeData node) {
  final rng = math.Random(node.id * 31 + node.type.length);
  final base = node.isFlooded
      ? 0.65 + rng.nextDouble() * 0.33
      : rng.nextDouble() * 0.7;
  final risk = double.parse(base.toStringAsFixed(3));
  final conf = double.parse(
    (0.74 + rng.nextDouble() * 0.24).toStringAsFixed(3),
  );
  final rainfall = double.parse(
    (22.0 + rng.nextDouble() * 195.0).toStringAsFixed(1),
  );
  final soil = double.parse(
    (0.35 + rng.nextDouble() * 0.60).toStringAsFixed(3),
  );
  final rateOfChange = double.parse(
    (rng.nextDouble() * 8.5).toStringAsFixed(2),
  );
  final factors = <String>[];
  if (rainfall > 140) {
    factors.add('High cumulative rainfall (${rainfall.toStringAsFixed(0)} mm)');
  }
  if (soil > 0.75) {
    factors.add(
      'Soil saturation critical (${(soil * 100).toStringAsFixed(0)}%)',
    );
  }
  if (node.isFlooded) factors.add('Current flood status confirmed');
  if (rateOfChange > 5)
    factors.add('Rapid water-level rise ($rateOfChange mm/h)');
  if (node.type == 'supply_drop') factors.add('Low-elevation staging point');
  if (factors.isEmpty) factors.add('Baseline environmental risk');
  return {
    'risk_score': risk,
    'confidence': conf,
    'predicted_impassable_2h': risk > 0.68,
    'contributing_factors': factors,
    'cumulative_rainfall_mm': rainfall,
    'soil_saturation_pct': (soil * 100).toStringAsFixed(1),
    'water_level_rate_mm_h': rateOfChange,
    'model_version': 'GradBoost-v1.2',
    'generated_at': DateTime.now().toIso8601String(),
  };
}

Map<String, dynamic> _generateEdgeMlPrediction(_EdgeData edge) {
  final rng = math.Random(edge.code.hashCode.abs());
  final base = (edge.isFlooded || edge.isBlocked)
      ? 0.72 + rng.nextDouble() * 0.26
      : edge.risk + rng.nextDouble() * 0.25;
  final risk = double.parse(base.clamp(0.0, 1.0).toStringAsFixed(3));
  final conf = double.parse(
    (0.71 + rng.nextDouble() * 0.27).toStringAsFixed(3),
  );
  final factors = <String>[];
  if (edge.isFlooded) factors.add('Route actively flooded');
  if (edge.isBlocked) factors.add('Physical obstruction reported');
  if (edge.risk > 0.5) {
    factors.add('Base risk score elevated (${(edge.risk * 100).toInt()}%)');
  }
  if (edge.type == 'river')
    factors.add('River-type — sensitive to water level');
  if (edge.travelMins > 90) factors.add('Extended travel time degrades SLA');
  if (factors.isEmpty) factors.add('Normal operational conditions');
  return {
    'risk_score': risk,
    'confidence': conf,
    'predicted_impassable_2h': risk > 0.68,
    'contributing_factors': factors,
    'current_travel_mins': edge.travelMins,
    'model_version': 'GradBoost-v1.2',
    'generated_at': DateTime.now().toIso8601String(),
  };
}

// ── Main screen ───────────────────────────────────────────────────────────────

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  _NodeData? _selectedNode;
  Map<String, dynamic>? _selectedVehicle;
  _EdgeData? _selectedEdge;
  Map<String, dynamic>? _nodeMlPrediction;
  Map<String, dynamic>? _edgeMlPrediction;

  bool _showNodes = true;
  bool _showEdges = true;
  bool _showVehicles = true;
  bool _showMlRisk = true;

  // Animation for pulsing selected node & in-mission vehicles
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _vehicleTickCtrl;

  Timer? _refreshTimer;

  // Highlighted route path (node IDs from routing engine)
  final List<int> _highlightedPath = [];

  // ── Simulation engine ─────────────────────────────────────────────────────
  // Mobile route animation inspired by https://leafletjs.com/examples/mobile/
  List<_NodeData> _cachedNodes = [];
  List<_EdgeData> _cachedEdges = [];
  bool _simMode = false;
  bool _simPlaying = false;
  double _simProgress = 0.0;
  List<LatLng> _simPath = [];
  int _simSourceId = -1;
  int _simTargetId = -1;
  double _simSpeed = 1.0;
  bool _simFollowMode = true;
  Timer? _simTimer;
  LatLng? _simCurrentPos;
  late final AnimationController _simPulseCtrl;
  late final Animation<double> _simPulseAnim;

  static const _center = LatLng(24.980, 91.770);

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _vehicleTickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _vehicleTickCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _simPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _simPulseAnim = CurvedAnimation(
      parent: _simPulseCtrl,
      curve: Curves.easeInOut,
    );

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final online = ref
          .read(connectivityNotifierProvider)
          .maybeWhen(online: (_) => true, orElse: () => false);
      if (!online) return;
      ref.read(appDataNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _vehicleTickCtrl.dispose();
    _simPulseCtrl.dispose();
    _simTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Simulation helpers ────────────────────────────────────────────────────

  void _rebuildSimPath() {
    if (_simSourceId < 0 || _simTargetId < 0 || _cachedNodes.isEmpty) return;
    final nodeMap = {for (final n in _cachedNodes) n.id: n};
    final path = _bfsPath(_simSourceId, _simTargetId, _cachedEdges, nodeMap);
    _simTimer?.cancel();
    setState(() {
      _simPath = path;
      _simProgress = 0;
      _simCurrentPos = path.isNotEmpty ? path.first : null;
      _simPlaying = false;
    });
  }

  List<LatLng> _bfsPath(
    int fromId,
    int toId,
    List<_EdgeData> edges,
    Map<int, _NodeData> nodeMap,
  ) {
    if (fromId == toId) {
      final n = nodeMap[fromId];
      return n == null ? [] : [LatLng(n.lat, n.lng)];
    }
    final visited = <int>{fromId};
    final queue = <List<int>>[
      [fromId],
    ];
    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final cur = path.last;
      for (final e in edges) {
        int? nxt;
        if (e.sourceId == cur &&
            !visited.contains(e.targetId) &&
            nodeMap.containsKey(e.targetId)) {
          nxt = e.targetId;
        } else if (e.targetId == cur &&
            !visited.contains(e.sourceId) &&
            nodeMap.containsKey(e.sourceId)) {
          nxt = e.sourceId;
        }
        if (nxt == null) continue;
        final newPath = [...path, nxt];
        if (nxt == toId) {
          return newPath
              .map((id) => LatLng(nodeMap[id]!.lat, nodeMap[id]!.lng))
              .toList();
        }
        visited.add(nxt);
        queue.add(newPath);
      }
    }
    // No graph path — fallback to direct line
    final f = nodeMap[fromId], t = nodeMap[toId];
    if (f != null && t != null) {
      return [LatLng(f.lat, f.lng), LatLng(t.lat, t.lng)];
    }
    return [];
  }

  LatLng _interpolatedPos() {
    if (_simPath.isEmpty) return _center;
    final total = (_simPath.length - 1).toDouble();
    final c = _simProgress.clamp(0.0, total);
    final idx = c.floor().clamp(0, _simPath.length - 2);
    final t = c - idx;
    final a = _simPath[idx];
    final b = _simPath[idx + 1];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  double _simHeadingDeg() {
    if (_simPath.length < 2) return 0;
    final idx = _simProgress.floor().clamp(0, _simPath.length - 2);
    final a = _simPath[idx];
    final b = _simPath[idx + 1];
    return math.atan2(b.longitude - a.longitude, b.latitude - a.latitude) *
        180 /
        math.pi;
  }

  void _startSim() {
    if (_simPath.isEmpty || _simPlaying) return;
    if (_simProgress >= _simPath.length - 1) _simProgress = 0.0;
    setState(() => _simPlaying = true);
    _simTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        _simProgress += _simSpeed / 80.0;
        if (_simProgress >= _simPath.length - 1) {
          _simProgress = (_simPath.length - 1).toDouble();
          _simPlaying = false;
          _simTimer?.cancel();
        }
        _simCurrentPos = _interpolatedPos();
        if (_simFollowMode && _simCurrentPos != null) {
          _mapController.move(_simCurrentPos!, _mapController.camera.zoom);
        }
      });
    });
  }

  void _pauseSim() {
    _simTimer?.cancel();
    setState(() => _simPlaying = false);
  }

  void _resetSim() {
    _simTimer?.cancel();
    setState(() {
      _simProgress = 0;
      _simPlaying = false;
      _simCurrentPos = _simPath.isNotEmpty ? _simPath.first : null;
    });
  }

  List<CircleMarker> _buildSimCircles() {
    if (_simCurrentPos == null) return [];
    final pulse = _simPulseAnim.value;
    return [
      CircleMarker(
        point: _simCurrentPos!,
        radius: 90 + 35 * pulse,
        color: const Color(
          0xFF1E88E5,
        ).withValues(alpha: 0.07 + 0.04 * (1 - pulse)),
        borderColor: const Color(
          0xFF1E88E5,
        ).withValues(alpha: 0.28 + 0.12 * (1 - pulse)),
        borderStrokeWidth: 1.5,
        useRadiusInMeter: true,
      ),
      CircleMarker(
        point: _simCurrentPos!,
        radius: 24,
        color: const Color(0xFF1E88E5).withValues(alpha: 0.22),
        borderColor: Colors.white,
        borderStrokeWidth: 2.0,
        useRadiusInMeter: true,
      ),
    ];
  }

  List<Marker> _buildSimPositionMarker() {
    if (_simCurrentPos == null) return [];
    final heading = _simHeadingDeg();
    final pulse = _simPulseAnim.value;
    return [
      Marker(
        point: _simCurrentPos!,
        width: 52,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40 + 8 * pulse,
              height: 40 + 8 * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF1E88E5,
                ).withValues(alpha: 0.15 * (1 - pulse * 0.5)),
              ),
            ),
            Transform.rotate(
              angle: heading * math.pi / 180,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x551E88E5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dataState = ref.watch(appDataNotifierProvider);
    final connectivity = ref.watch(connectivityNotifierProvider);
    final isOnline = connectivity.when(
      initial: () => false,
      online: (_) => true,
      offline: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      body: dataState.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(appDataNotifierProvider.notifier).refresh(),
        ),
        data: (snap) => _buildMapView(snap, isOnline),
      ),
    );
  }

  // ── Loading skeleton ──────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return Stack(
      children: [
        const ColoredBox(color: Color(0xFFECEFF1), child: SizedBox.expand()),
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primarySurfaceDefault),
              SizedBox(height: 16),
              Text(
                'Loading operations map…',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryTextDefault,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Map view ──────────────────────────────────────────────────────────────

  Widget _buildMapView(AppDataSnapshot snap, bool isOnline) {
    final nodes = snap.nodes.map(_NodeData.fromMap).toList();
    final edges = snap.edges.map(_EdgeData.fromMap).toList();
    final nodeMap = {for (final n in nodes) n.id: n};
    final vehicles = snap.vehicles;

    // Cache latest data for simulation path finder (BFS uses these)
    _cachedNodes = nodes;
    _cachedEdges = edges;

    final polylines = _buildPolylines(edges, nodeMap);
    final nodeMarkers = _showNodes ? _buildNodeMarkers(nodes) : <Marker>[];
    final vehicleMarkers = _showVehicles
        ? _buildVehicleMarkers(vehicles, nodeMap)
        : <Marker>[];
    final edgeRiskMarkers = _showEdges
        ? _buildEdgeMidpointMarkers(edges, nodeMap)
        : <Marker>[];

    final bool panelOpen =
        _selectedNode != null ||
        _selectedVehicle != null ||
        _selectedEdge != null;

    return Stack(
      children: [
        // ── Flutter Map ─────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 10.5,
            maxZoom: 18.0,
            minZoom: 7.0,
            backgroundColor: isOnline
                ? const Color(0xFFE8E8E8)
                : const Color(0xFFC9D6DC),
            onTap: (_, __) => setState(() {
              _selectedNode = null;
              _selectedVehicle = null;
              _selectedEdge = null;
              _nodeMlPrediction = null;
              _edgeMlPrediction = null;
            }),
          ),
          children: [
            if (isOnline)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.digital.delta.response',
                maxZoom: 19,
              ),
            if (_showEdges) PolylineLayer(polylines: polylines),
            // ── Simulation route path ──────────────────────────────────────
            if (_simMode && _simPath.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _simPath,
                    color: const Color(0xFF1E88E5),
                    strokeWidth: 5.0,
                    borderColor: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                    borderStrokeWidth: 3.0,
                  ),
                ],
              ),
            MarkerLayer(markers: nodeMarkers),
            MarkerLayer(markers: edgeRiskMarkers),
            MarkerLayer(markers: vehicleMarkers),
            // ── Simulation accuracy circle + position marker ───────────────
            if (_simMode && _simCurrentPos != null)
              CircleLayer(circles: _buildSimCircles()),
            if (_simMode && _simCurrentPos != null)
              MarkerLayer(markers: _buildSimPositionMarker()),
          ],
        ),

        // ── Single floating header: title + KPIs + layer toggles ─────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _MapTopChrome(
            isOnline: isOnline,
            snap: snap,
            onRefresh: () {
              final online = ref
                  .read(connectivityNotifierProvider)
                  .maybeWhen(online: (_) => true, orElse: () => false);
              if (online) {
                ref.read(appDataNotifierProvider.notifier).syncAndRefresh();
              } else {
                ref.read(appDataNotifierProvider.notifier).refresh();
              }
            },
            showNodes: _showNodes,
            showEdges: _showEdges,
            showVehicles: _showVehicles,
            showMlRisk: _showMlRisk,
            onToggleNodes: () => setState(() => _showNodes = !_showNodes),
            onToggleEdges: () => setState(() => _showEdges = !_showEdges),
            onToggleVehicles: () =>
                setState(() => _showVehicles = !_showVehicles),
            onToggleMlRisk: () => setState(() => _showMlRisk = !_showMlRisk),
          ),
        ),

        // ── Simulate FAB + Map legend (right side stack) ─────────────────────
        Positioned(
          bottom: panelOpen ? 316 : (_simMode ? 224 : 24),
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SimFab(
                active: _simMode,
                onTap: () => setState(() {
                  _simMode = !_simMode;
                  if (!_simMode) {
                    _pauseSim();
                    _simPath = [];
                    _simProgress = 0;
                    _simCurrentPos = null;
                    _simSourceId = -1;
                    _simTargetId = -1;
                  }
                }),
              ),
              const SizedBox(height: 8),
              const _MapLegend(),
            ],
          ),
        ),

        // ── Zoom controls ─────────────────────────────────────────────────────
        Positioned(
          bottom: panelOpen ? 316 : (_simMode ? 224 : 24),
          left: 12,
          child: _ZoomControls(
            onZoomIn: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            ),
            onZoomOut: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            ),
            onCenter: () => _mapController.move(_center, 10.5),
          ),
        ),

        if (!isOnline)
          Positioned(
            left: 12,
            right: 12,
            bottom: panelOpen ? 300 : 88,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.black.withValues(alpha: 0.78),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Offline: basemap tiles unavailable. Pan, zoom, routes & fleet markers still use your cached snapshot.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Simulation control panel ──────────────────────────────────────────
        if (_simMode && !panelOpen)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _SimControlPanel(
              nodes: _cachedNodes,
              sourceId: _simSourceId,
              targetId: _simTargetId,
              playing: _simPlaying,
              progress: _simPath.isEmpty
                  ? 0.0
                  : (_simProgress / (_simPath.length - 1).clamp(1, 9999)).clamp(
                      0.0,
                      1.0,
                    ),
              speed: _simSpeed,
              followMode: _simFollowMode,
              hasPath: _simPath.isNotEmpty,
              onSetSource: (id) => setState(() {
                _simSourceId = id;
                _rebuildSimPath();
              }),
              onSetTarget: (id) => setState(() {
                _simTargetId = id;
                _rebuildSimPath();
              }),
              onPlay: _startSim,
              onPause: _pauseSim,
              onReset: _resetSim,
              onSpeed: (s) => setState(() => _simSpeed = s),
              onFollowToggle: () =>
                  setState(() => _simFollowMode = !_simFollowMode),
            ),
          ),

        // ── Detail panels ─────────────────────────────────────────────────────
        if (_selectedNode != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _NodeDetailPanel(
              node: _selectedNode!,
              mlPrediction: _nodeMlPrediction,
              onClose: () => setState(() {
                _selectedNode = null;
                _nodeMlPrediction = null;
              }),
            ),
          ),
        if (_selectedEdge != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _EdgeDetailPanel(
              edge: _selectedEdge!,
              mlPrediction: _edgeMlPrediction,
              onClose: () => setState(() {
                _selectedEdge = null;
                _edgeMlPrediction = null;
              }),
            ),
          ),
        if (_selectedVehicle != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _VehicleDetailPanel(
              vehicle: _selectedVehicle!,
              onClose: () => setState(() => _selectedVehicle = null),
            ),
          ),
      ],
    );
  }

  // ── Polylines (M4.1 — multi-modal edge types) ─────────────────────────────

  List<Polyline> _buildPolylines(
    List<_EdgeData> edges,
    Map<int, _NodeData> nodeMap,
  ) {
    final result = <Polyline>[];
    for (final edge in edges) {
      final src = nodeMap[edge.sourceId];
      final tgt = nodeMap[edge.targetId];
      if (src == null || tgt == null) continue;

      final isCritical = edge.isFlooded || edge.isBlocked;
      final isHighRisk = edge.risk > 0.5 && !isCritical;
      final isHighlighted =
          _highlightedPath.isNotEmpty &&
          _highlightedPath.contains(edge.sourceId) &&
          _highlightedPath.contains(edge.targetId);

      Color lineColor;
      double width;
      if (isHighlighted) {
        lineColor = AppColors.primarySurfaceDefault;
        width = 6.0;
      } else if (isCritical) {
        lineColor = AppColors.dangerSurfaceDefault;
        width = 5.0;
      } else if (isHighRisk) {
        lineColor = AppColors.warningSurfaceDefault;
        width = 4.0;
      } else {
        lineColor = _edgeColor(edge.type);
        width = 3.0;
      }

      result.add(
        Polyline(
          points: [LatLng(src.lat, src.lng), LatLng(tgt.lat, tgt.lng)],
          color: lineColor,
          strokeWidth: width,
          borderColor: isCritical
              ? AppColors.dangerSurfaceDefault.withValues(alpha: 0.3)
              : Colors.transparent,
          borderStrokeWidth: isCritical ? 2.0 : 0,
        ),
      );
    }
    return result;
  }

  // ── Edge midpoint ML risk markers ─────────────────────────────────────────

  List<Marker> _buildEdgeMidpointMarkers(
    List<_EdgeData> edges,
    Map<int, _NodeData> nodeMap,
  ) {
    if (!_showMlRisk) return [];
    final markers = <Marker>[];
    for (final edge in edges) {
      final src = nodeMap[edge.sourceId];
      final tgt = nodeMap[edge.targetId];
      if (src == null || tgt == null) continue;
      final midLat = (src.lat + tgt.lat) / 2;
      final midLng = (src.lng + tgt.lng) / 2;
      final isRisky = edge.risk > 0.35 || edge.isFlooded || edge.isBlocked;
      if (!isRisky) continue;

      final markerColor = (edge.isFlooded || edge.isBlocked)
          ? AppColors.dangerSurfaceDefault
          : AppColors.warningSurfaceDefault;

      markers.add(
        Marker(
          point: LatLng(midLat, midLng),
          width: 28,
          height: 28,
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedEdge = edge;
              _selectedNode = null;
              _selectedVehicle = null;
              _nodeMlPrediction = null;
              _edgeMlPrediction = _generateEdgeMlPrediction(edge);
            }),
            child: Container(
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: markerColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  // ── Node markers (M4.4 live status) ──────────────────────────────────────

  List<Marker> _buildNodeMarkers(List<_NodeData> nodes) {
    return nodes.map((node) {
      final color = _nodeColor(node.type, node.isFlooded);
      final isSelected = _selectedNode?.id == node.id;

      return Marker(
        point: LatLng(node.lat, node.lng),
        width: isSelected ? 64 : 50,
        height: isSelected ? 64 : 50,
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedNode = node;
            _selectedVehicle = null;
            _selectedEdge = null;
            _edgeMlPrediction = null;
            _nodeMlPrediction = _generateNodeMlPrediction(node);
          }),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing selection ring
              if (isSelected)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: 50 + 14 * _pulseAnim.value,
                    height: 50 + 14 * _pulseAnim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(
                        alpha: 0.25 * (1 - _pulseAnim.value),
                      ),
                    ),
                  ),
                ),
              // Flood warning ring
              if (node.isFlooded)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.dangerSurfaceDefault.withValues(
                        alpha: 0.5,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              // Main badge
              Container(
                width: isSelected ? 40 : 34,
                height: isSelected ? 40 : 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isSelected ? 0.55 : 0.3),
                      blurRadius: isSelected ? 14 : 6,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _nodeIcon(node.type),
                  color: Colors.white,
                  size: isSelected ? 21 : 17,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Vehicle markers (M4.4 fleet positions) ────────────────────────────────

  List<Marker> _buildVehicleMarkers(
    List<Map<String, dynamic>> vehicles,
    Map<int, _NodeData> nodeMap,
  ) {
    final markers = <Marker>[];
    final locationCounts = <int, int>{};

    for (final v in vehicles) {
      final locId = v['current_location_id'];
      if (locId == null) continue;
      final id = (locId as num).toInt();
      final node = nodeMap[id];
      if (node == null) continue;

      final count = locationCounts[id] ?? 0;
      locationCounts[id] = count + 1;
      final angle = count * (math.pi / 4);
      const radius = 0.012;
      final offsetLat = node.lat + radius * math.sin(angle);
      final offsetLng = node.lng + radius * math.cos(angle);

      final type = v['type'] as String? ?? 'truck';
      final status = v['status'] as String? ?? 'idle';
      final identifier = v['identifier'] as String? ?? '---';
      final isInMission = status == 'in_mission';
      final tickVal = _vehicleTickCtrl.value;

      markers.add(
        Marker(
          point: LatLng(offsetLat, offsetLng),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedVehicle = v;
              _selectedNode = null;
              _selectedEdge = null;
            }),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isInMission)
                  Container(
                    width: 32 + 10 * tickVal,
                    height: 32 + 10 * tickVal,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primarySurfaceDefault.withValues(
                        alpha: 0.18 * (1 - tickVal),
                      ),
                    ),
                  ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _vehicleStatusColor(status),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _vehicleStatusColor(
                          status,
                        ).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Tooltip(
                    message: identifier,
                    child: Icon(
                      _vehicleIcon(type),
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }
}

// ── Unified map header (one card: title row + scroll row for KPIs + layers) ────

class _MapTopChrome extends StatelessWidget {
  final bool isOnline;
  final AppDataSnapshot snap;
  final VoidCallback onRefresh;
  final bool showNodes;
  final bool showEdges;
  final bool showVehicles;
  final bool showMlRisk;
  final VoidCallback onToggleNodes;
  final VoidCallback onToggleEdges;
  final VoidCallback onToggleVehicles;
  final VoidCallback onToggleMlRisk;

  const _MapTopChrome({
    required this.isOnline,
    required this.snap,
    required this.onRefresh,
    required this.showNodes,
    required this.showEdges,
    required this.showVehicles,
    required this.showMlRisk,
    required this.onToggleNodes,
    required this.onToggleEdges,
    required this.onToggleVehicles,
    required this.onToggleMlRisk,
  });

  @override
  Widget build(BuildContext context) {
    final liveColor = isOnline
        ? AppColors.primarySurfaceDefault
        : AppColors.statusPending;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 0),
        child: Material(
          elevation: 4,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(18.r),
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 8.w, 10.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(9.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primarySurfaceDefault,
                            AppColors.primarySurfaceDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Operations map',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTextDefault,
                            ),
                          ),
                          Text(
                            'Layers & live metrics',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: liveColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: liveColor,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            isOnline ? 'Live' : 'Offline',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: liveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 2.w),
                    IconButton(
                      onPressed: onRefresh,
                      padding: EdgeInsets.all(6.w),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.secondaryTextDefault,
                      ),
                      icon: Icon(Icons.refresh_rounded, size: 22.sp),
                      tooltip: 'Refresh data',
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.h, bottom: 2.h),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _MapKpiChip(
                          icon: Icons.task_alt_rounded,
                          value: '${snap.activeMissions}',
                          hint: 'Act',
                          color: AppColors.primarySurfaceDefault,
                        ),
                        SizedBox(width: 8.w),
                        _MapKpiChip(
                          icon: Icons.local_shipping_outlined,
                          value: '${snap.activeVehicles}/${snap.totalVehicles}',
                          hint: 'Fleet',
                          color: AppColors.priorityP2,
                        ),
                        SizedBox(width: 8.w),
                        _MapKpiChip(
                          icon: Icons.crisis_alert,
                          value: '${snap.slaBreached}',
                          hint: 'SLA',
                          color: snap.slaBreached > 0
                              ? AppColors.dangerSurfaceDefault
                              : AppColors.primarySurfaceDefault,
                        ),
                        SizedBox(width: 8.w),
                        _MapKpiChip(
                          icon: Icons.inventory_2_outlined,
                          value: '${snap.criticalLowStock}',
                          hint: 'Stock',
                          color: snap.criticalLowStock > 0
                              ? AppColors.statusPending
                              : AppColors.primarySurfaceDefault,
                        ),
                        SizedBox(width: 8.w),
                        _MapKpiChip(
                          icon: Icons.hub_outlined,
                          value: '${snap.meshPending}',
                          hint: 'Mesh',
                          color: AppColors.nodeCommand,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: SizedBox(
                            height: 28.h,
                            child: VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: AppColors.borderDefault,
                            ),
                          ),
                        ),
                        _MapLayerChip(
                          label: 'Nodes',
                          icon: Icons.place_outlined,
                          active: showNodes,
                          onTap: onToggleNodes,
                        ),
                        SizedBox(width: 6.w),
                        _MapLayerChip(
                          label: 'Routes',
                          icon: Icons.route_outlined,
                          active: showEdges,
                          onTap: onToggleEdges,
                        ),
                        SizedBox(width: 6.w),
                        _MapLayerChip(
                          label: 'Fleet',
                          icon: Icons.local_shipping_outlined,
                          active: showVehicles,
                          onTap: onToggleVehicles,
                        ),
                        SizedBox(width: 6.w),
                        _MapLayerChip(
                          label: 'ML',
                          icon: Icons.auto_graph,
                          active: showMlRisk,
                          activeColor: AppColors.warningSurfaceDefault,
                          onTap: onToggleMlRisk,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapKpiChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String hint;
  final Color color;

  const _MapKpiChip({
    required this.icon,
    required this.value,
    required this.hint,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.colorBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 5.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            hint,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.secondaryTextDefault,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLayerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color? activeColor;

  const _MapLayerChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.primarySurfaceDefault;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? color : AppColors.colorBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: active ? color : AppColors.borderDefault,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: active ? Colors.white : AppColors.secondaryTextDefault,
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.primaryTextDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Map legend ────────────────────────────────────────────────────────────────

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGEND',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryTextDefault,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Routes (M4.1)',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextDefault,
            ),
          ),
          SizedBox(height: 2.h),
          _LegendLine(color: const Color(0xFF607D8B), label: 'Road'),
          _LegendLine(color: const Color(0xFF1565C0), label: 'River'),
          _LegendLine(color: const Color(0xFF6A1B9A), label: 'Airway'),
          _LegendLine(color: AppColors.dangerSurfaceDefault, label: 'Flooded'),
          _LegendLine(
            color: AppColors.warningSurfaceDefault,
            label: 'High Risk',
          ),
          _LegendLine(
            color: AppColors.primarySurfaceDefault,
            label: 'Active Route',
          ),
          SizedBox(height: 6.h),
          Text(
            'Nodes',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextDefault,
            ),
          ),
          SizedBox(height: 2.h),
          _LegendDot(color: AppColors.nodeCommand, label: 'Command HQ'),
          _LegendDot(color: AppColors.nodeReliefCamp, label: 'Relief Camp'),
          _LegendDot(color: AppColors.nodeHospital, label: 'Hospital'),
          _LegendDot(color: AppColors.nodeSupplyDrop, label: 'Supply Drop'),
          _LegendDot(color: AppColors.nodeDroneBase, label: 'Drone Base'),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendLine({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5.sp,
              color: AppColors.primaryTextDefault,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5.sp,
              color: AppColors.primaryTextDefault,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Zoom controls ─────────────────────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenter;

  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomBtn(icon: Icons.add, onTap: onZoomIn),
          Container(height: 1, color: AppColors.borderDefault),
          _ZoomBtn(icon: Icons.remove, onTap: onZoomOut),
          Container(height: 1, color: AppColors.borderDefault),
          _ZoomBtn(icon: Icons.my_location_rounded, onTap: onCenter),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 18.sp, color: AppColors.primaryTextDefault),
      ),
    );
  }
}

// ── Node detail panel ─────────────────────────────────────────────────────────

class _NodeDetailPanel extends StatelessWidget {
  final _NodeData node;
  final Map<String, dynamic>? mlPrediction;
  final VoidCallback onClose;

  const _NodeDetailPanel({
    required this.node,
    required this.onClose,
    this.mlPrediction,
  });

  @override
  Widget build(BuildContext context) {
    final color = _nodeColor(node.type, node.isFlooded);
    final hasCapacity = node.capacity != null && node.capacity! > 0;
    final occupancyPct = hasCapacity ? node.occupancy / node.capacity! : 0.0;
    final ml = mlPrediction;
    final mlRisk = ml != null ? (ml['risk_score'] as num).toDouble() : null;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Handle(),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(_nodeIcon(node.type), color: color, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTextDefault,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        _Badge(label: _nodeTypeLabel(node.type), color: color),
                        if (node.isFlooded) ...[
                          SizedBox(width: 6.w),
                          _Badge(
                            label: 'FLOODED',
                            color: AppColors.dangerSurfaceDefault,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close,
                  size: 20.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _PanelStat(label: 'Code', value: node.code, icon: Icons.tag),
              SizedBox(width: 12.w),
              _PanelStat(
                label: 'Lat / Lng',
                value:
                    '${node.lat.toStringAsFixed(4)}, ${node.lng.toStringAsFixed(4)}',
                icon: Icons.location_on_outlined,
              ),
            ],
          ),
          if (hasCapacity) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 13.sp,
                  color: AppColors.secondaryTextDefault,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Occupancy',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: occupancyPct.clamp(0.0, 1.0),
                      backgroundColor: AppColors.borderDefault,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        occupancyPct > 0.85
                            ? AppColors.dangerSurfaceDefault
                            : occupancyPct > 0.6
                            ? AppColors.warningSurfaceDefault
                            : AppColors.primarySurfaceDefault,
                      ),
                      minHeight: 7,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${node.occupancy}/${node.capacity}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
              ],
            ),
          ],
          if (ml != null && mlRisk != null) ...[
            SizedBox(height: 14.h),
            _MlRiskBlock(ml: ml, mlRisk: mlRisk),
          ],
        ],
      ),
    );
  }
}

// ── Edge detail panel ─────────────────────────────────────────────────────────

class _EdgeDetailPanel extends StatelessWidget {
  final _EdgeData edge;
  final Map<String, dynamic>? mlPrediction;
  final VoidCallback onClose;

  const _EdgeDetailPanel({
    required this.edge,
    required this.onClose,
    this.mlPrediction,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = edge.isFlooded || edge.isBlocked;
    final color = isCritical
        ? AppColors.dangerSurfaceDefault
        : _edgeColor(edge.type);
    final ml = mlPrediction;
    final mlRisk = ml != null ? (ml['risk_score'] as num).toDouble() : null;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Handle(),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.route, color: color, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route ${edge.code}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTextDefault,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        _EdgeTypeBadge(type: edge.type),
                        if (edge.isFlooded) ...[
                          SizedBox(width: 6.w),
                          _Badge(
                            label: 'FLOODED',
                            color: AppColors.dangerSurfaceDefault,
                          ),
                        ],
                        if (edge.isBlocked) ...[
                          SizedBox(width: 6.w),
                          _Badge(
                            label: 'BLOCKED',
                            color: AppColors.warningSurfaceDefault,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close,
                  size: 20.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _PanelStat(
                label: 'Travel Time',
                value: '${edge.travelMins} min',
                icon: Icons.timer_outlined,
              ),
              SizedBox(width: 12.w),
              _PanelStat(
                label: 'Base Risk',
                value: '${(edge.risk * 100).toStringAsFixed(0)}%',
                icon: Icons.warning_amber_outlined,
              ),
            ],
          ),
          if (ml != null && mlRisk != null) ...[
            SizedBox(height: 14.h),
            _MlRiskBlock(ml: ml, mlRisk: mlRisk, isEdge: true),
          ],
        ],
      ),
    );
  }
}

// ── Vehicle detail panel ──────────────────────────────────────────────────────

class _VehicleDetailPanel extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onClose;

  const _VehicleDetailPanel({required this.vehicle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final type = vehicle['type'] as String? ?? 'truck';
    final status = vehicle['status'] as String? ?? 'idle';
    final identifier = vehicle['identifier'] as String? ?? '---';
    final name = vehicle['name'] as String? ?? identifier;
    final fuel = vehicle['fuel_level'] as num?;
    final battery = vehicle['battery_level'] as num?;
    final level = battery ?? fuel;
    final levelLabel = battery != null ? 'Battery' : 'Fuel';
    final color = _vehicleStatusColor(status);
    final operatorName =
        (vehicle['operator'] as Map?)?['name'] as String? ?? 'Unassigned';

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Handle(),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(_vehicleIcon(type), color: color, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$identifier — $name',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTextDefault,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    _Badge(
                      label: status.replaceAll('_', ' ').toUpperCase(),
                      color: color,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close,
                  size: 20.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _PanelStat(
                label: 'Operator',
                value: operatorName,
                icon: Icons.person_outline,
              ),
              SizedBox(width: 12.w),
              _PanelStat(
                label: 'Type',
                value: type[0].toUpperCase() + type.substring(1),
                icon: Icons.category_outlined,
              ),
            ],
          ),
          if (level != null) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  battery != null
                      ? Icons.battery_charging_full
                      : Icons.local_gas_station_outlined,
                  size: 13.sp,
                  color: level > 60
                      ? AppColors.primarySurfaceDefault
                      : level > 30
                      ? AppColors.warningSurfaceDefault
                      : AppColors.dangerSurfaceDefault,
                ),
                SizedBox(width: 6.w),
                Text(
                  levelLabel,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: level.toDouble() / 100,
                      backgroundColor: AppColors.borderDefault,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        level > 60
                            ? AppColors.primarySurfaceDefault
                            : level > 30
                            ? AppColors.warningSurfaceDefault
                            : AppColors.dangerSurfaceDefault,
                      ),
                      minHeight: 7,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${level.toInt()}%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── ML Risk Block ─────────────────────────────────────────────────────────────

class _MlRiskBlock extends StatelessWidget {
  final Map<String, dynamic> ml;
  final double mlRisk;
  final bool isEdge;

  const _MlRiskBlock({
    required this.ml,
    required this.mlRisk,
    this.isEdge = false,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = mlRisk > 0.7
        ? AppColors.dangerSurfaceDefault
        : mlRisk > 0.4
        ? AppColors.warningSurfaceDefault
        : AppColors.primarySurfaceDefault;
    final isAlert = ml['predicted_impassable_2h'] as bool;
    final factors = ml['contributing_factors'] as List;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.neutralSurfaceTint,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: riskColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_graph,
                size: 13.sp,
                color: AppColors.warningSurfaceDefault,
              ),
              SizedBox(width: 6.w),
              Text(
                isEdge ? 'ML Route Risk (M7)' : 'ML Flood Risk (M7)',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTextDefault,
                ),
              ),
              const Spacer(),
              Text(
                ml['model_version'] as String,
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: mlRisk,
                        backgroundColor: AppColors.borderDefault,
                        valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '${(mlRisk * 100).toStringAsFixed(1)}% risk  ·  conf ${((ml['confidence'] as num) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isAlert
                      ? AppColors.dangerSurfaceTint
                      : AppColors.primarySurfaceTint,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isAlert
                        ? AppColors.dangerSurfaceDefault.withValues(alpha: 0.4)
                        : AppColors.primarySurfaceDefault.withValues(
                            alpha: 0.4,
                          ),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isAlert
                          ? Icons.dangerous_outlined
                          : Icons.check_circle_outline,
                      size: 18.sp,
                      color: isAlert
                          ? AppColors.dangerSurfaceDefault
                          : AppColors.primarySurfaceDefault,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isAlert ? 'Alert\n2h' : 'Safe\n2h+',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: isAlert
                            ? AppColors.dangerSurfaceDefault
                            : AppColors.primarySurfaceDefault,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (factors.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 5.w,
              runSpacing: 4.h,
              children: factors
                  .map(
                    (f) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Text(
                        f as String,
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          color: AppColors.secondaryTextDefault,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.borderDefault,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EdgeTypeBadge extends StatelessWidget {
  final String type;
  const _EdgeTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      'road' => (const Color(0xFF607D8B), Icons.local_shipping),
      'river' => (const Color(0xFF1565C0), Icons.directions_boat),
      'airway' => (const Color(0xFF6A1B9A), Icons.airplanemode_active),
      _ => (AppColors.borderDefault, Icons.linear_scale),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp, color: color),
          SizedBox(width: 3.w),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 9.sp,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PanelStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 13.sp, color: AppColors.secondaryTextDefault),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextDefault,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: const BoxDecoration(
                color: AppColors.dangerSurfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.map_outlined,
                size: 40.sp,
                color: AppColors.dangerSurfaceDefault,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Map unavailable',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.secondaryTextDefault,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySurfaceDefault,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Simulation FAB ────────────────────────────────────────────────────────────

class _SimFab extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _SimFab({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: active ? 'Stop simulation' : 'Simulate route',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1E88E5) : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: active ? const Color(0xFF1E88E5) : AppColors.borderDefault,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? const Color(0xFF1E88E5).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            active ? Icons.stop_circle_outlined : Icons.route,
            color: active ? Colors.white : AppColors.secondaryTextDefault,
            size: 20.sp,
          ),
        ),
      ),
    );
  }
}

// ── Simulation control panel ──────────────────────────────────────────────────

class _SimControlPanel extends StatelessWidget {
  final List<_NodeData> nodes;
  final int sourceId;
  final int targetId;
  final bool playing;
  final double progress; // 0.0 – 1.0
  final double speed;
  final bool followMode;
  final bool hasPath;
  final void Function(int) onSetSource;
  final void Function(int) onSetTarget;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final void Function(double) onSpeed;
  final VoidCallback onFollowToggle;

  const _SimControlPanel({
    required this.nodes,
    required this.sourceId,
    required this.targetId,
    required this.playing,
    required this.progress,
    required this.speed,
    required this.followMode,
    required this.hasPath,
    required this.onSetSource,
    required this.onSetTarget,
    required this.onPlay,
    required this.onPause,
    required this.onReset,
    required this.onSpeed,
    required this.onFollowToggle,
  });

  String _nodeName(int id) {
    if (id < 0) return 'Pick node…';
    try {
      return nodes.firstWhere((n) => n.id == id).name;
    } catch (_) {
      return 'Node $id';
    }
  }

  @override
  Widget build(BuildContext context) {
    final srcName = _nodeName(sourceId);
    final tgtName = _nodeName(targetId);
    final progressPct = (progress * 100).toInt();

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E88E5), width: 3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(
                  Icons.route,
                  color: Color(0xFF1E88E5),
                  size: 18,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Simulation',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTextDefault,
                      ),
                    ),
                    Text(
                      hasPath
                          ? 'Animating route  ·  $progressPct%'
                          : 'Select source & destination to begin',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.secondaryTextDefault,
                      ),
                    ),
                  ],
                ),
              ),
              _SimChip(
                icon: followMode ? Icons.my_location : Icons.location_searching,
                label: 'Follow',
                active: followMode,
                onTap: onFollowToggle,
                activeColor: const Color(0xFF1E88E5),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // ── Source / Target pickers ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SimNodeDropdown(
                  icon: Icons.trip_origin,
                  color: AppColors.primarySurfaceDefault,
                  label: 'From',
                  selected: srcName,
                  nodes: nodes,
                  onSelected: onSetSource,
                  excludeId: targetId,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
              Expanded(
                child: _SimNodeDropdown(
                  icon: Icons.place,
                  color: AppColors.dangerSurfaceDefault,
                  label: 'To',
                  selected: tgtName,
                  nodes: nodes,
                  onSelected: onSetTarget,
                  excludeId: sourceId,
                ),
              ),
            ],
          ),

          if (hasPath) ...[
            SizedBox(height: 12.h),
            // ── Progress bar ──────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.borderDefault,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1E88E5),
                ),
                minHeight: 6,
              ),
            ),
          ],

          SizedBox(height: 12.h),

          // ── Player controls row ──────────────────────────────────────────
          Row(
            children: [
              _SimActionBtn(
                icon: Icons.replay,
                onTap: onReset,
                enabled: hasPath,
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: hasPath ? (playing ? onPause : onPlay) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: hasPath
                        ? const Color(0xFF1E88E5)
                        : AppColors.borderDefault,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        playing ? 'Pause' : 'Play',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Speed:',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
              SizedBox(width: 6.w),
              ...[0.5, 1.0, 2.0, 5.0].map(
                (s) => Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: _SimChip(
                    label: s == 0.5 ? '½×' : '${s.toInt()}×',
                    active: speed == s,
                    onTap: () => onSpeed(s),
                    activeColor: const Color(0xFF1E88E5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Simulation node dropdown ──────────────────────────────────────────────────

class _SimNodeDropdown extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String selected;
  final List<_NodeData> nodes;
  final void Function(int) onSelected;
  final int excludeId;

  const _SimNodeDropdown({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.nodes,
    required this.onSelected,
    required this.excludeId,
  });

  @override
  Widget build(BuildContext context) {
    final available = nodes.where((n) => n.id != excludeId).toList();
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.55,
            maxChildSize: 0.85,
            minChildSize: 0.35,
            builder: (ctx, scroll) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Select $label node',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTextDefault,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      itemCount: available.length,
                      itemBuilder: (ctx2, i) {
                        final n = available[i];
                        final nc = _nodeColor(n.type, n.isFlooded);
                        return ListTile(
                          leading: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: nc.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_nodeIcon(n.type), color: nc, size: 16),
                          ),
                          title: Text(
                            n.name,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTextDefault,
                            ),
                          ),
                          subtitle: Text(
                            '${_nodeTypeLabel(n.type)}  ·  ${n.code}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                          ),
                          trailing: n.isFlooded
                              ? Icon(
                                  Icons.water,
                                  color: AppColors.dangerSurfaceDefault,
                                  size: 16.sp,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(ctx2);
                            onSelected(n.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.colorBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13.sp, color: color),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.secondaryTextDefault,
                    ),
                  ),
                  Text(
                    selected,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextDefault,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 16.sp,
              color: AppColors.secondaryTextDefault,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Simulation chip ───────────────────────────────────────────────────────────

class _SimChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;
  final IconData? icon;

  const _SimChip({
    required this.label,
    required this.active,
    required this.onTap,
    required this.activeColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: active ? activeColor : AppColors.colorBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: active ? activeColor : AppColors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12.sp,
                color: active ? Colors.white : AppColors.secondaryTextDefault,
              ),
              SizedBox(width: 3.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.primaryTextDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Simulation action button ──────────────────────────────────────────────────

class _SimActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _SimActionBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.colorBackground,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: enabled
              ? AppColors.primaryTextDefault
              : AppColors.disabledTextDefault,
        ),
      ),
    );
  }
}
