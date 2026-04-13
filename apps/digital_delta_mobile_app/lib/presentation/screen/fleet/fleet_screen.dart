import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../connectivity/notifier/provider.dart';
import '../../notifier/app_data_notifier.dart';
import '../../theme/color.dart';

// ---------------------------------------------------------------------------
// Fleet Screen — live vehicle data from AppDataService (offline-first)
// ---------------------------------------------------------------------------

class FleetScreen extends ConsumerWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataState = ref.watch(appDataNotifierProvider);
    final isOnline = ref.watch(connectivityNotifierProvider).maybeWhen(
          online: (_) => true,
          orElse: () => false,
        );

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'Fleet Management',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: dataState.isLoading
                ? null
                : () async {
                    if (isOnline) {
                      await ref
                          .read(appDataNotifierProvider.notifier)
                          .syncAndRefresh();
                    } else {
                      await ref
                          .read(appDataNotifierProvider.notifier)
                          .refresh();
                    }
                  },
          ),
        ],
      ),
      body: dataState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(appDataNotifierProvider.notifier).refresh(),
        ),
        data: (snap) => Column(
          children: [
            if (!isOnline) const _FleetOfflineBanner(),
            Expanded(
              child: _FleetBody(
                vehicles: snap.vehicles,
                networkNodes: snap.nodes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FleetOfflineBanner extends StatelessWidget {
  const _FleetOfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningSurfaceDefault.withValues(alpha: 0.12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 18.sp, color: AppColors.statusPending),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Offline — fleet list reflects your last synced snapshot from the API cache.',
                style: TextStyle(
                  fontSize: 11.sp,
                  height: 1.3,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body with filter + list
// ---------------------------------------------------------------------------

class _FleetBody extends StatefulWidget {
  final List<Map<String, dynamic>> vehicles;
  final List<Map<String, dynamic>> networkNodes;

  const _FleetBody({
    required this.vehicles,
    required this.networkNodes,
  });

  @override
  State<_FleetBody> createState() => _FleetBodyState();
}

class _FleetBodyState extends State<_FleetBody> {
  String _filter = 'All';

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return widget.vehicles;
    final typeMap = {
      'Trucks': 'truck',
      'Boats': 'speedboat',
      'Drones': 'drone',
    };
    final typeKey = typeMap[_filter];
    return widget.vehicles.where((v) => v['type'] == typeKey).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      children: [
        // Summary chips
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          color: Colors.white,
          child: Row(
            children: [
              _SummaryChip(
                label: 'Total',
                count: widget.vehicles.length,
                color: AppColors.statusIdle,
              ),
              SizedBox(width: 8.w),
              _SummaryChip(
                label: 'Active',
                count: widget.vehicles
                    .where((v) => v['status'] == 'in_mission')
                    .length,
                color: AppColors.statusOnline,
              ),
              SizedBox(width: 8.w),
              _SummaryChip(
                label: 'Idle',
                count: widget.vehicles
                    .where((v) => v['status'] == 'idle')
                    .length,
                color: AppColors.statusIdle,
              ),
              SizedBox(width: 8.w),
              _SummaryChip(
                label: 'Offline',
                count: widget.vehicles
                    .where((v) => v['status'] == 'offline')
                    .length,
                color: AppColors.statusOffline,
              ),
            ],
          ),
        ),

        // Filter row
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Trucks', 'Boats', 'Drones']
                  .map(
                    (f) => Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _FilterChip(
                        label: f,
                        isSelected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),

        // Vehicles list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 48.sp, color: Colors.grey.shade300),
                      SizedBox(height: 12.h),
                      Text(
                        'No $_filter vehicles',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.secondaryTextDefault,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, i) => _VehicleCard(
                    vehicle: filtered[i],
                    locationName: _locationNameForVehicle(
                      filtered[i],
                      widget.networkNodes,
                    ),
                    operatorName: _operatorLabel(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

String _locationNameForVehicle(
  Map<String, dynamic> vehicle,
  List<Map<String, dynamic>> nodes,
) {
  final nested = vehicle['location'];
  if (nested is Map && nested['name'] != null) {
    return nested['name'] as String;
  }
  final raw = vehicle['current_location_id'];
  if (raw == null) return '—';
  final id = (raw as num).toInt();
  for (final n in nodes) {
    if ((n['id'] as num).toInt() == id) {
      return n['name'] as String? ?? '—';
    }
  }
  return 'Location #$id';
}

String _operatorLabel(Map<String, dynamic> vehicle) {
  final op = vehicle['operator'];
  if (op is Map && op['name'] != null) return op['name'] as String;
  final oid = vehicle['operator_id'];
  if (oid != null) return 'Operator #$oid';
  return 'Not assigned';
}

// ---------------------------------------------------------------------------
// Vehicle card
// ---------------------------------------------------------------------------

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final String locationName;
  final String operatorName;

  const _VehicleCard({
    required this.vehicle,
    required this.locationName,
    required this.operatorName,
  });

  @override
  Widget build(BuildContext context) {
    final type = vehicle['type'] as String? ?? 'truck';
    final status = vehicle['status'] as String? ?? 'idle';
    final identifier = vehicle['identifier'] as String? ?? '—';
    final name = vehicle['name'] as String? ?? identifier;
    final fuel = vehicle['fuel_level'] as num?;
    final battery = vehicle['battery_level'] as num?;
    final level = battery ?? fuel;
    final levelLabel = battery != null ? 'Battery' : 'Fuel';
    final statusColor = _statusColor(status);
    final typeIcon = _typeIcon(type);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(typeIcon, size: 28.sp, color: statusColor),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          identifier,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTextDefault,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _StatusBadge(status: status, color: statusColor),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.secondaryTextDefault,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, color: AppColors.borderDefault),
          SizedBox(height: 12.h),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Driver',
            value: operatorName,
          ),
          SizedBox(height: 8.h),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: locationName,
          ),
          if (level != null) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  battery != null
                      ? Icons.battery_charging_full
                      : Icons.local_gas_station,
                  size: 16.sp,
                  color: level > 60
                      ? AppColors.statusOnline
                      : level > 30
                          ? AppColors.statusPending
                          : AppColors.statusOffline,
                ),
                SizedBox(width: 6.w),
                Text(
                  levelLabel,
                  style: TextStyle(
                      fontSize: 12.sp, color: AppColors.secondaryTextDefault),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: LinearProgressIndicator(
                    value: level.toDouble() / 100,
                    backgroundColor: Colors.grey.shade200,
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
                    fontWeight: FontWeight.w600,
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

  Color _statusColor(String status) => switch (status) {
        'in_mission' => Colors.green,
        'idle' => Colors.blueGrey,
        'maintenance' => Colors.orange,
        'offline' => Colors.red,
        _ => Colors.grey,
      };

  IconData _typeIcon(String type) => switch (type) {
        'truck' => Icons.local_shipping,
        'speedboat' => Icons.directions_boat,
        'drone' => Icons.airplanemode_active,
        _ => Icons.commute,
      };
}

// ---------------------------------------------------------------------------
// Reusable small widgets
// ---------------------------------------------------------------------------

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: color),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = status.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySurfaceDefault
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.secondaryTextDefault,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.secondaryTextDefault),
        SizedBox(width: 8.w),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.secondaryTextDefault,
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextDefault,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
            Icon(Icons.local_shipping_outlined,
                size: 48.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text(
              'Failed to load vehicles',
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
                  fontSize: 13.sp, color: AppColors.secondaryTextDefault),
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
