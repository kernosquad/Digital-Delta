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
  if (flooded) return Colors.red.shade700;
  return switch (type) {
    'central_command' => const Color(0xFF1A237E),
    'relief_camp' => const Color(0xFF2E7D32),
    'hospital' => const Color(0xFFB71C1C),
    'supply_drop' => const Color(0xFFE65100),
    'drone_base' => const Color(0xFF4A148C),
    'waypoint' => const Color(0xFF546E7A),
    _ => const Color(0xFF455A64),
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

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  _NodeData? _selectedNode;
  Map<String, dynamic>? _selectedVehicle;

  // Filter state
  bool _showNodes = true;
  bool _showEdges = true;
  bool _showVehicles = true;

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

    return Stack(
      children: [
        // ── Map ──────────────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 9.0,
            maxZoom: 15.0,
            minZoom: 7.0,
            onTap: (_, __) => setState(() {
              _selectedNode = null;
              _selectedVehicle = null;
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
              PolylineLayer(
                polylines: polylines,
              ),
            MarkerLayer(markers: nodeMarkers),
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
            onToggleNodes: () => setState(() => _showNodes = !_showNodes),
            onToggleEdges: () => setState(() => _showEdges = !_showEdges),
            onToggleVehicles: () =>
                setState(() => _showVehicles = !_showVehicles),
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
          bottom: _selectedNode != null || _selectedVehicle != null ? 200 : 16,
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
              onClose: () => setState(() => _selectedNode = null),
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

      final color =
          (edge.isFlooded || edge.isBlocked) ? Colors.red.shade600 : _edgeColor(edge.type);
      final width = (edge.isFlooded || edge.isBlocked) ? 4.0 : 2.5;

      return Polyline(
        points: [LatLng(src.lat, src.lng), LatLng(tgt.lat, tgt.lng)],
        color: color,
        strokeWidth: width,
      );
    }).whereType<Polyline>().toList();
  }

  List<Marker> _buildNodeMarkers(List<_NodeData> nodes) {
    return nodes.map((node) {
      final color = _nodeColor(node.type, node.isFlooded);
      final isSelected = _selectedNode?.id == node.id;

      return Marker(
        point: LatLng(node.lat, node.lng),
        width: isSelected ? 52 : 40,
        height: isSelected ? 52 : 40,
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedNode = node;
            _selectedVehicle = null;
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
  final VoidCallback onToggleNodes;
  final VoidCallback onToggleEdges;
  final VoidCallback onToggleVehicles;

  const _FilterBar({
    required this.showNodes,
    required this.showEdges,
    required this.showVehicles,
    required this.onToggleNodes,
    required this.onToggleEdges,
    required this.onToggleVehicles,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primarySurfaceDefault
              : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: active
                ? AppColors.primarySurfaceDefault
                : Colors.white.withValues(alpha: 0.3),
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
          _LegendLine(color: Colors.red, label: 'Flooded'),
          SizedBox(height: 4.h),
          _LegendDot(color: const Color(0xFF1A237E), label: 'Command HQ'),
          _LegendDot(color: const Color(0xFF2E7D32), label: 'Relief Camp'),
          _LegendDot(color: const Color(0xFFB71C1C), label: 'Hospital'),
          _LegendDot(color: const Color(0xFFE65100), label: 'Supply Drop'),
          _LegendDot(color: const Color(0xFF4A148C), label: 'Drone Base'),
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
  final VoidCallback onClose;

  const _NodeDetailPanel({required this.node, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final color = _nodeColor(node.type, node.isFlooded);
    final hasCapacity = node.capacity != null;
    final occupancyPct =
        hasCapacity && node.capacity! > 0 ? node.occupancy / node.capacity! : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(
          top: BorderSide(color: color, width: 3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
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
                child: Icon(_nodeIcon(node.type), color: color, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            _nodeTypeLabel(node.type),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        if (node.isFlooded)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'FLOODED',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
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
                label: 'Node Code',
                value: node.code,
                icon: Icons.tag,
              ),
              SizedBox(width: 16.w),
              _PanelStat(
                label: 'Coordinates',
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
                Text(
                  'Occupancy',
                  style:
                      TextStyle(fontSize: 12.sp, color: Colors.white54),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: LinearProgressIndicator(
                    value: occupancyPct.clamp(0.0, 1.0),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      occupancyPct > 0.85
                          ? Colors.red
                          : occupancyPct > 0.6
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${node.occupancy}/${node.capacity}',
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
