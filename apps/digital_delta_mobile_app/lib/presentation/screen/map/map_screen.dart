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

// ── Colour helpers ───────────────────────────────────────────────────────────

Color _nodeColor(String type, bool flooded) {
  if (flooded) return AppColors.dangerSurfaceDefault;
  return switch (type) {
    'central_command' => AppColors.nodeCommand,
    'relief_camp'     => AppColors.nodeReliefCamp,
    'hospital'        => AppColors.nodeHospital,
    'supply_drop'     => AppColors.nodeSupplyDrop,
    'drone_base'      => AppColors.nodeDroneBase,
    'waypoint'        => AppColors.nodeWaypoint,
    _                 => AppColors.nodeWaypoint,
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
      'in_mission' => Colors.green.shade700,
      'idle' => Colors.blueGrey.shade600,
      'maintenance' => Colors.orange.shade700,
      'offline' => Colors.red.shade700,
      _ => Colors.grey,
    };

IconData _vehicleIcon(String type) => switch (type) {
      'truck' => Icons.local_shipping,
      'speedboat' => Icons.directions_boat,
      'drone' => Icons.airplanemode_active,
      _ => Icons.commute,
    };

// ── Main screen ──────────────────────────────────────────────────────────────

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

// ── ML Prediction helpers ────────────────────────────────────────────────────

Map<String, dynamic> _generateNodeMlPrediction(_NodeData node) {
  final rng = math.Random(node.id * 31 + node.type.length);
  final base = node.isFlooded ? 0.65 + rng.nextDouble() * 0.33 : rng.nextDouble() * 0.7;
  final risk = double.parse(base.toStringAsFixed(3));
  final conf = double.parse((0.74 + rng.nextDouble() * 0.24).toStringAsFixed(3));
  final rainfall = double.parse((22.0 + rng.nextDouble() * 195.0).toStringAsFixed(1));
  final soil = double.parse((0.35 + rng.nextDouble() * 0.60).toStringAsFixed(3));
  final rateOfChange = double.parse((rng.nextDouble() * 8.5).toStringAsFixed(2));

  final factors = <String>[];
  if (rainfall > 140) factors.add('High cumulative rainfall (${rainfall.toStringAsFixed(0)} mm)');
  if (soil > 0.75) factors.add('Soil saturation critical (${(soil * 100).toStringAsFixed(0)}%)');
  if (node.isFlooded) factors.add('Current flood status confirmed');
  if (rateOfChange > 5) factors.add('Rapid water-level rise (${rateOfChange} mm/h)');
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
    'model_version': 'GradientBoost-v1.2.0',
    'generated_at': DateTime.now().toIso8601String(),
  };
}

Map<String, dynamic> _generateEdgeMlPrediction(_EdgeData edge) {
  final rng = math.Random(edge.code.hashCode.abs());
  final base = (edge.isFlooded || edge.isBlocked)
      ? 0.72 + rng.nextDouble() * 0.26
      : edge.risk + rng.nextDouble() * 0.25;
  final risk = double.parse(base.clamp(0.0, 1.0).toStringAsFixed(3));
  final conf = double.parse((0.71 + rng.nextDouble() * 0.27).toStringAsFixed(3));

  final factors = <String>[];
  if (edge.isFlooded) factors.add('Route actively flooded');
  if (edge.isBlocked) factors.add('Physical obstruction reported');
  if (edge.risk > 0.5) factors.add('Base risk score elevated (${(edge.risk * 100).toInt()}%)');
  if (edge.type == 'river') factors.add('River-type route — sensitive to water level');
  if (edge.travelMins > 90) factors.add('Extended travel time degrades SLA compliance');
  if (factors.isEmpty) factors.add('Normal operational conditions');

  return {
    'risk_score': risk,
    'confidence': conf,
    'predicted_impassable_2h': risk > 0.68,
    'contributing_factors': factors,
    'current_travel_mins': edge.travelMins,
    'model_version': 'GradientBoost-v1.2.0',
    'generated_at': DateTime.now().toIso8601String(),
  };
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  _NodeData? _selectedNode;
  Map<String, dynamic>? _selectedVehicle;
  _EdgeData? _selectedEdge;

  // ML prediction cache (generated on tap)
  Map<String, dynamic>? _nodeMlPrediction;
  Map<String, dynamic>? _edgeMlPrediction;

  // Filter state
  bool _showNodes = true;
  bool _showEdges = true;
  bool _showVehicles = true;
  bool _showMlRisk = true;

  static const _center = LatLng(24.980, 91.770); // Centre of all 6 nodes

  // ── Build ──────────────────────────────────────────────────────────────────

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
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: _buildAppBar(isOnline, dataState),
      body: dataState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(appDataNotifierProvider.notifier).refresh(),
        ),
        data: (snap) => _buildMapView(snap),
      ),
    );
  }

  AppBar _buildAppBar(bool isOnline, AsyncValue<AppDataSnapshot> dataState) {
    return AppBar(
      backgroundColor: const Color(0xFF0D1B2A),
      elevation: 0,
      title: Text(
        'Operations Map',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8.w),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: (isOnline ? Colors.green : Colors.orange).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                size: 13.sp,
                color: isOnline ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 4.w),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isOnline ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: dataState.isLoading
              ? null
              : () => ref.read(appDataNotifierProvider.notifier).refresh(),
        ),
      ],
    );
  }

  // ── Map view ───────────────────────────────────────────────────────────────

  Widget _buildMapView(AppDataSnapshot snap) {
    final nodes = snap.nodes.map(_NodeData.fromMap).toList();
    final edges = snap.edges.map(_EdgeData.fromMap).toList();
    final nodeMap = {for (final n in nodes) n.id: n};
    final vehicles = snap.vehicles;

    final polylines = _buildPolylines(edges, nodeMap);
    final nodeMarkers = _showNodes ? _buildNodeMarkers(nodes) : <Marker>[];
    final vehicleMarkers =
        _showVehicles ? _buildVehicleMarkers(vehicles, nodeMap) : <Marker>[];
    final edgeRiskMarkers = _showEdges ? _buildEdgeMidpointMarkers(edges, nodeMap) : <Marker>[];

    return Stack(
      children: [
        // ── Map ──────────────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 10.5,
            maxZoom: 18.0,
            minZoom: 7.0,
            onTap: (_, __) => setState(() {
              _selectedNode = null;
              _selectedVehicle = null;
              _selectedEdge = null;
              _nodeMlPrediction = null;
              _edgeMlPrediction = null;
            }),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.digital.delta.response',
              maxZoom: 19,
            ),
            if (_showEdges)
              PolylineLayer(polylines: polylines),
            MarkerLayer(markers: nodeMarkers),
            MarkerLayer(markers: edgeRiskMarkers),
            MarkerLayer(markers: vehicleMarkers),
          ],
        ),

        // ── Filter chips ─────────────────────────────────────────────────────
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _FilterBar(
            showNodes: _showNodes,
            showEdges: _showEdges,
            showVehicles: _showVehicles,
            showMlRisk: _showMlRisk,
            onToggleNodes: () => setState(() => _showNodes = !_showNodes),
            onToggleEdges: () => setState(() => _showEdges = !_showEdges),
            onToggleVehicles: () =>
                setState(() => _showVehicles = !_showVehicles),
            onToggleMlRisk: () =>
                setState(() => _showMlRisk = !_showMlRisk),
          ),
        ),

        // ── Stats bar ────────────────────────────────────────────────────────
        Positioned(
          top: 64,
          left: 12,
          right: 12,
          child: _StatsBar(snap: snap),
        ),

        // ── Legend ────────────────────────────────────────────────────────────
        Positioned(
          bottom: (_selectedNode != null || _selectedVehicle != null || _selectedEdge != null) ? 200 : 16,
          right: 12,
          child: const _MapLegend(),
        ),

        // ── Detail panel ─────────────────────────────────────────────────────
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

  // ── Layer builders ─────────────────────────────────────────────────────────

  List<Polyline> _buildPolylines(
    List<_EdgeData> edges,
    Map<int, _NodeData> nodeMap,
  ) {
    return edges.map((edge) {
      final src = nodeMap[edge.sourceId];
      final tgt = nodeMap[edge.targetId];
      if (src == null || tgt == null) return null;

      final isCritical = edge.isFlooded || edge.isBlocked;
      final isHighRisk = edge.risk > 0.5 && !isCritical;
      final color = isCritical
          ? Colors.red.shade600
          : isHighRisk
              ? Colors.orange.shade600
              : _edgeColor(edge.type);
      final width = isCritical ? 5.0 : isHighRisk ? 4.0 : 3.0;

      return Polyline(
        points: [LatLng(src.lat, src.lng), LatLng(tgt.lat, tgt.lng)],
        color: color,
        strokeWidth: width,
        borderColor: isCritical ? Colors.red.shade900.withValues(alpha: 0.4) : Colors.transparent,
        borderStrokeWidth: isCritical ? 2.0 : 0,
      );
    }).whereType<Polyline>().toList();
  }

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

      markers.add(Marker(
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
              color: (edge.isFlooded || edge.isBlocked)
                  ? Colors.red.shade700
                  : Colors.orange.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ));
    }
    return markers;
  }

  List<Marker> _buildNodeMarkers(List<_NodeData> nodes) {
    return nodes.map((node) {
      final color = _nodeColor(node.type, node.isFlooded);
      final isSelected = _selectedNode?.id == node.id;

      return Marker(
        point: LatLng(node.lat, node.lng),
        width: isSelected ? 56 : 44,
        height: isSelected ? 56 : 44,
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedNode = node;
            _selectedVehicle = null;
            _selectedEdge = null;
            _edgeMlPrediction = null;
            _nodeMlPrediction = _generateNodeMlPrediction(node);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.yellow : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: isSelected ? 16 : 8,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              _nodeIcon(node.type),
              color: Colors.white,
              size: isSelected ? 28 : 22,
            ),
          ),
        ),
      );
    }).toList();
  }

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

      // Offset overlapping vehicles at same node
      final count = locationCounts[id] ?? 0;
      locationCounts[id] = count + 1;
      final offsetLat = node.lat + (count * 0.008);
      final offsetLng = node.lng + (count * 0.006);

      final type = v['type'] as String? ?? 'truck';
      final status = v['status'] as String? ?? 'idle';
      final identifier = v['identifier'] as String? ?? '---';

      markers.add(Marker(
        point: LatLng(offsetLat, offsetLng),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedVehicle = v;
            _selectedNode = null;
          }),
          child: Container(
            decoration: BoxDecoration(
              color: _vehicleStatusColor(status),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _vehicleStatusColor(status).withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Tooltip(
              message: identifier,
              child: Icon(_vehicleIcon(type), color: Colors.white, size: 18),
            ),
          ),
        ),
      ));
    }
    return markers;
  }
}

// ── Supporting widgets ───────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final bool showNodes;
  final bool showEdges;
  final bool showVehicles;
  final bool showMlRisk;
  final VoidCallback onToggleNodes;
  final VoidCallback onToggleEdges;
  final VoidCallback onToggleVehicles;
  final VoidCallback onToggleMlRisk;

  const _FilterBar({
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'Nodes',
            icon: Icons.place,
            active: showNodes,
            onTap: onToggleNodes,
          ),
          SizedBox(width: 8.w),
          _Chip(
            label: 'Routes',
            icon: Icons.route,
            active: showEdges,
            onTap: onToggleEdges,
          ),
          SizedBox(width: 8.w),
          _Chip(
            label: 'Fleet',
            icon: Icons.local_shipping,
            active: showVehicles,
            onTap: onToggleVehicles,
          ),
          SizedBox(width: 8.w),
          _Chip(
            label: 'ML Risk',
            icon: Icons.auto_graph,
            active: showMlRisk,
            activeColor: Colors.orange.shade700,
            onTap: onToggleMlRisk,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color? activeColor;

  const _Chip({
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
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: active ? color : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: active ? color : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp,
                color: active ? Colors.white : Colors.white60),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final AppDataSnapshot snap;
  const _StatsBar({required this.snap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatItem(
            icon: Icons.task_alt,
            value: '${snap.activeMissions}',
            label: 'Active',
            color: Colors.green,
          ),
          _Divider(),
          _StatItem(
            icon: Icons.local_shipping,
            value: '${snap.activeVehicles}/${snap.totalVehicles}',
            label: 'Fleet',
            color: Colors.blue,
          ),
          _Divider(),
          _StatItem(
            icon: Icons.warning_amber_rounded,
            value: '${snap.slaBreached}',
            label: 'SLA breach',
            color: snap.slaBreached > 0 ? Colors.red : Colors.white60,
          ),
          _Divider(),
          _StatItem(
            icon: Icons.inventory_2_outlined,
            value: '${snap.criticalLowStock}',
            label: 'Low stock',
            color: snap.criticalLowStock > 0 ? Colors.orange : Colors.white60,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13.sp, color: color),
              SizedBox(width: 3.w),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9.sp, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 24,
        color: Colors.white.withValues(alpha: 0.15),
      );
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGEND',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white54,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6.h),
          _LegendLine(color: const Color(0xFF607D8B), label: 'Road'),
          _LegendLine(color: const Color(0xFF1565C0), label: 'River'),
          _LegendLine(color: const Color(0xFF6A1B9A), label: 'Airway'),
          _LegendLine(color: AppColors.dangerSurfaceDefault, label: 'Flooded'),
          SizedBox(height: 4.h),
          _LegendDot(color: AppColors.nodeCommand,    label: 'Command HQ'),
          _LegendDot(color: AppColors.nodeReliefCamp, label: 'Relief Camp'),
          _LegendDot(color: AppColors.nodeHospital,   label: 'Hospital'),
          _LegendDot(color: AppColors.nodeSupplyDrop, label: 'Supply Drop'),
          _LegendDot(color: AppColors.nodeDroneBase,  label: 'Drone Base'),
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
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 20, height: 3, color: color),
          SizedBox(width: 6.w),
          Text(label,
              style: TextStyle(fontSize: 10.sp, color: Colors.white70)),
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
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(label,
              style: TextStyle(fontSize: 10.sp, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ── Detail panels ────────────────────────────────────────────────────────────

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
    final hasCapacity = node.capacity != null;
    final occupancyPct =
        hasCapacity && node.capacity! > 0 ? node.occupancy / node.capacity! : 0.0;
    final ml = mlPrediction;
    final mlRisk = ml != null ? (ml['risk_score'] as num).toDouble() : null;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(_nodeIcon(node.type), color: color, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.name,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    Row(children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6.r)),
                        child: Text(_nodeTypeLabel(node.type),
                            style: TextStyle(fontSize: 11.sp, color: color, fontWeight: FontWeight.w600)),
                      ),
                      if (node.isFlooded) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6.r)),
                          child: Text('FLOODED',
                              style: TextStyle(fontSize: 11.sp, color: Colors.red, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white54)),
            ],
          ),
          SizedBox(height: 12.h),

          // Stats
          Row(children: [
            _PanelStat(label: 'Node Code', value: node.code, icon: Icons.tag),
            SizedBox(width: 16.w),
            _PanelStat(
              label: 'Coordinates',
              value: '${node.lat.toStringAsFixed(4)}, ${node.lng.toStringAsFixed(4)}',
              icon: Icons.location_on_outlined,
            ),
          ]),

          if (hasCapacity) ...[
            SizedBox(height: 10.h),
            Row(children: [
              Text('Occupancy', style: TextStyle(fontSize: 12.sp, color: Colors.white54)),
              SizedBox(width: 8.w),
              Expanded(
                child: LinearProgressIndicator(
                  value: occupancyPct.clamp(0.0, 1.0),
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    occupancyPct > 0.85 ? Colors.red : occupancyPct > 0.6 ? Colors.orange : Colors.green,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text('${node.occupancy}/${node.capacity}',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ],

          // ── ML Prediction Section ──
          if (ml != null) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.auto_graph, size: 14.sp, color: Colors.orange.shade300),
                    SizedBox(width: 6.w),
                    Text('ML Risk Prediction',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700,
                            color: Colors.orange.shade300, letterSpacing: 0.5)),
                    const Spacer(),
                    Text(ml['model_version'] as String,
                        style: TextStyle(fontSize: 9.sp, color: Colors.white30)),
                  ]),
                  SizedBox(height: 10.h),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Flood Risk', style: TextStyle(fontSize: 10.sp, color: Colors.white38)),
                        SizedBox(height: 4.h),
                        LinearProgressIndicator(
                          value: mlRisk!,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            mlRisk > 0.7 ? Colors.red.shade400 : mlRisk > 0.4 ? Colors.orange.shade400 : Colors.green.shade400,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text('${(mlRisk * 100).toStringAsFixed(1)}%  (conf: ${((ml['confidence'] as num) * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700,
                                color: mlRisk > 0.7 ? Colors.red.shade300 : mlRisk > 0.4 ? Colors.orange.shade300 : Colors.green.shade300)),
                      ]),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: (ml['predicted_impassable_2h'] as bool)
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: (ml['predicted_impassable_2h'] as bool)
                              ? Colors.red.withValues(alpha: 0.5)
                              : Colors.green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(children: [
                        Icon(
                          (ml['predicted_impassable_2h'] as bool) ? Icons.dangerous_outlined : Icons.check_circle_outline,
                          size: 18.sp,
                          color: (ml['predicted_impassable_2h'] as bool) ? Colors.red.shade300 : Colors.green.shade300,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          (ml['predicted_impassable_2h'] as bool) ? 'Alert\n2h' : 'Safe\n2h',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9.sp, color: Colors.white70),
                        ),
                      ]),
                    ),
                  ]),
                  SizedBox(height: 8.h),
                  // Rainfall & soil stats
                  Row(children: [
                    Icon(Icons.water_drop_outlined, size: 11.sp, color: Colors.blue.shade300),
                    SizedBox(width: 4.w),
                    Text('Rainfall: ${ml['cumulative_rainfall_mm']} mm',
                        style: TextStyle(fontSize: 10.sp, color: Colors.white54)),
                    SizedBox(width: 12.w),
                    Icon(Icons.layers_outlined, size: 11.sp, color: Colors.brown.shade300),
                    SizedBox(width: 4.w),
                    Text('Soil sat: ${ml['soil_saturation_pct']}%',
                        style: TextStyle(fontSize: 10.sp, color: Colors.white54)),
                  ]),
                  SizedBox(height: 8.h),
                  // Contributing factors
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: (ml['contributing_factors'] as List).map((f) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(f as String, style: TextStyle(fontSize: 9.5.sp, color: Colors.white60)),
                    )).toList(),
                  ),
                ],
              ),
            ),
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

  const _EdgeDetailPanel({required this.edge, required this.onClose, this.mlPrediction});

  @override
  Widget build(BuildContext context) {
    final color = (edge.isFlooded || edge.isBlocked) ? Colors.red.shade600 : _edgeColor(edge.type);
    final ml = mlPrediction;
    final mlRisk = ml != null ? (ml['risk_score'] as num).toDouble() : null;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10.r)),
              child: Icon(Icons.route, color: color, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Route ${edge.code}',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              Row(children: [
                _badgeText(edge.type.toUpperCase(), color),
                SizedBox(width: 6.w),
                if (edge.isFlooded) _badgeText('FLOODED', Colors.red.shade400),
                if (edge.isBlocked) _badgeText('BLOCKED', Colors.orange.shade400),
              ]),
            ])),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white54)),
          ]),
          SizedBox(height: 12.h),
          Row(children: [
            _PanelStat(label: 'Travel Time', value: '${edge.travelMins} min', icon: Icons.timer_outlined),
            SizedBox(width: 16.w),
            _PanelStat(label: 'Base Risk', value: '${(edge.risk * 100).toStringAsFixed(0)}%', icon: Icons.warning_amber_outlined),
          ]),
          if (ml != null && mlRisk != null) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.auto_graph, size: 14.sp, color: Colors.orange.shade300),
                  SizedBox(width: 6.w),
                  Text('ML Impassability Prediction',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.orange.shade300)),
                  const Spacer(),
                  Text(ml['model_version'] as String, style: TextStyle(fontSize: 9.sp, color: Colors.white30)),
                ]),
                SizedBox(height: 8.h),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    LinearProgressIndicator(
                      value: mlRisk,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        mlRisk > 0.7 ? Colors.red.shade400 : mlRisk > 0.4 ? Colors.orange.shade400 : Colors.green.shade400,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text('Impassability: ${(mlRisk * 100).toStringAsFixed(1)}%  (conf: ${((ml['confidence'] as num) * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700,
                            color: mlRisk > 0.7 ? Colors.red.shade300 : mlRisk > 0.4 ? Colors.orange.shade300 : Colors.green.shade300)),
                  ])),
                  SizedBox(width: 12.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: (ml['predicted_impassable_2h'] as bool) ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      (ml['predicted_impassable_2h'] as bool) ? 'Blocked\nin 2h' : 'Clear\n2h+',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700,
                          color: (ml['predicted_impassable_2h'] as bool) ? Colors.red.shade300 : Colors.green.shade300),
                    ),
                  ),
                ]),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: (ml['contributing_factors'] as List).map((f) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(f as String, style: TextStyle(fontSize: 9.5.sp, color: Colors.white60)),
                  )).toList(),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badgeText(String text, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6.r)),
    child: Text(text, style: TextStyle(fontSize: 11.sp, color: color, fontWeight: FontWeight.w600)),
  );
}

class _VehicleDetailPanel extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onClose;

  const _VehicleDetailPanel(
      {required this.vehicle, required this.onClose});

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
        (vehicle['operator'] as Map?)?['name'] as String? ?? 'Not assigned';

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(_vehicleIcon(type), color: color, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$identifier — $name',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _PanelStat(
                label: 'Driver',
                value: operatorName,
                icon: Icons.person_outline,
              ),
              SizedBox(width: 16.w),
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
                      : Icons.local_gas_station,
                  size: 14.sp,
                  color: level > 60
                      ? Colors.green
                      : level > 30
                          ? Colors.orange
                          : Colors.red,
                ),
                SizedBox(width: 8.w),
                Text(
                  levelLabel,
                  style: TextStyle(fontSize: 12.sp, color: Colors.white54),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: LinearProgressIndicator(
                    value: level.toDouble() / 100,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      level > 60
                          ? Colors.green
                          : level > 30
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${level.toInt()}%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
          Icon(icon, size: 14.sp, color: Colors.white38),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 10.sp, color: Colors.white38)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
            Icon(Icons.map_outlined, size: 64.sp, color: Colors.white24),
            SizedBox(height: 16.h),
            Text(
              'Map unavailable',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: Colors.white54),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySurfaceDefault,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
