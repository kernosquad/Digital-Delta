import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../domain/model/operations/operations_snapshot_model.dart';
import '../../connectivity/notifier/provider.dart';
import '../../theme/color.dart';
import 'notifier/operations_notifier.dart';
import 'notifier/provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opsState = ref.watch(operationsNotifierProvider);
    final connectivity = ref.watch(connectivityNotifierProvider);

    final isOnline = connectivity.maybeWhen(
      online: (_) => true,
      orElse: () => false,
    );

    final syncLabel = connectivity.when(
      initial: () => ('Initializing', Colors.grey, Icons.hourglass_empty),
      online: (_) => ('Online', Colors.green, Icons.cloud_done),
      offline: () => ('Offline', Colors.orange, Icons.cloud_off),
    );

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'Sync & CRDT Dashboard',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: syncLabel.$2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: syncLabel.$2, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(syncLabel.$3, size: 14.sp, color: syncLabel.$2),
                SizedBox(width: 4.w),
                Text(
                  syncLabel.$1,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: syncLabel.$2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: opsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (msg) => Center(child: Text(msg)),
        loaded: (snapshot) =>
            _DashboardBody(snapshot: snapshot, isOnline: isOnline),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final OperationsSnapshot snapshot;
  final bool isOnline;

  const _DashboardBody({required this.snapshot, required this.isOnline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = snapshot.summary;
    final notifier = ref.read(operationsNotifierProvider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // ── Sync Status Summary ──
          _SectionTitle(title: 'Sync Overview'),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.pending_actions,
                  value: '${summary.pendingOperations}',
                  label: 'Pending Ops',
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_outline,
                  value: '${summary.syncedOperations}',
                  label: 'Synced Ops',
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _StatCard(
                  icon: Icons.warning_amber_rounded,
                  value: '${summary.openConflicts}',
                  label: 'Conflicts',
                  color: summary.openConflicts > 0
                      ? AppColors.dangerSurfaceDefault
                      : Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // ── Vector Clock ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16.sp, color: Colors.indigo),
                    SizedBox(width: 6.w),
                    Text(
                      'Vector Clock (Causal Order)',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  snapshot.vectorClockHumanReadable,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.indigo.shade800,
                  ),
                ),
                if (summary.lastSyncAt != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Last sync: ${_timeAgo(summary.lastSyncAt!)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.indigo.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // ── Action Buttons ──
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_box_outlined,
                  label: 'Add Item',
                  color: Colors.teal,
                  onPressed: () => _showAddInventoryDialog(context, notifier),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Create Delta',
                  color: Colors.blue,
                  onPressed: snapshot.inventory.isEmpty
                      ? () {}
                      : notifier.createLocalDelta,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ActionButton(
                  icon: Icons.sync,
                  label: 'Sync',
                  color: AppColors.primarySurfaceDefault,
                  onPressed: notifier.triggerSync,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // ── CRDT Inventory Ledger (M2.1) ──
          _SectionTitle(title: 'CRDT Inventory Ledger'),
          SizedBox(height: 8.h),
          if (snapshot.inventory.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 40.sp,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'No inventory items yet',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Tap "Add Item" to create your first CRDT inventory entry',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...snapshot.inventory.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _InventoryLedgerCard(entry: item),
              ),
            ),
          SizedBox(height: 16.h),

          // ── CRDT Operations Log (M2.2) ──
          _SectionTitle(title: 'CRDT Operations Log'),
          SizedBox(height: 8.h),
          if (snapshot.operations.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(
                'No CRDT operations recorded yet. Add inventory items and create deltas to start.',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
              ),
            )
          else
            ...snapshot.operations.map(
              (op) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: _CrdtOperationTile(
                  snapshot: snapshot,
                  op: op,
                  localNode: summary.localNodeUuid,
                ),
              ),
            ),
          SizedBox(height: 16.h),

          // ── Conflict Resolution (M2.3) ──
          if (snapshot.conflicts.isNotEmpty) ...[
            _SectionTitle(title: 'Conflict Resolution'),
            SizedBox(height: 8.h),
            ...snapshot.conflicts.map(
              (conflict) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _ConflictCard(
                  snapshot: snapshot,
                  conflict: conflict,
                  onResolve: (resolution) => notifier.resolveConflict(
                    conflictId: conflict.id,
                    resolution: resolution,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // ── Mesh Quick Status ──
          _SectionTitle(title: 'Mesh Network'),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.hub_outlined,
                  value: '${summary.nearbyNodes}',
                  label: 'Nearby Nodes',
                  color: Colors.teal,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _StatCard(
                  icon: Icons.cell_tower,
                  value: '${summary.relayCapableNodes}',
                  label: 'Relay Nodes',
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _StatCard(
                  icon: Icons.mail_outline,
                  value: '${summary.queuedMessages}',
                  label: 'Queued Msgs',
                  color: Colors.pink,
                ),
              ),
            ],
          ),
          SizedBox(height: 60.h),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static void _showAddInventoryDialog(
    BuildContext context,
    OperationsNotifier notifier,
  ) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final baseQtyController = TextEditingController();
    final currentQtyController = TextEditingController();
    final slaController = TextEditingController(text: '24');
    String selectedPriority = 'P1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Inventory Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g. Antivenom Kits',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    hintText: 'e.g. Sylhet District Hospital',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: baseQtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Base Qty *',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: currentQtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Current Qty *',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                        ),
                        items: ['P0', 'P1', 'P2', 'P3']
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedPriority = v ?? 'P1'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: slaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'SLA (hours)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final location = locationController.text.trim();
                final baseQty = int.tryParse(baseQtyController.text.trim());
                final currentQty = int.tryParse(
                  currentQtyController.text.trim(),
                );
                final sla = int.tryParse(slaController.text.trim()) ?? 24;

                if (name.isEmpty ||
                    location.isEmpty ||
                    baseQty == null ||
                    currentQty == null) {
                  return;
                }

                final priorityRank = switch (selectedPriority) {
                  'P0' => 0,
                  'P1' => 1,
                  'P2' => 2,
                  _ => 3,
                };

                final itemId = DateTime.now().millisecondsSinceEpoch.toString();

                notifier.addInventoryItem(
                  itemId: itemId,
                  itemName: name,
                  locationName: location,
                  baseQuantity: baseQty,
                  currentQuantity: currentQty,
                  priorityClass: selectedPriority,
                  priorityRank: priorityRank,
                  slaHours: sla,
                );

                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ───────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryTextDefault,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTextDefault,
            ),
          ),
          Text(
            label,
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18.sp),
      label: Text(label, style: TextStyle(fontSize: 13.sp)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}

class _InventoryLedgerCard extends StatelessWidget {
  final InventoryLedgerEntry entry;
  const _InventoryLedgerCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final fillColor = entry.isCritical
        ? AppColors.dangerSurfaceDefault
        : entry.fillRatio > 0.6
        ? AppColors.primarySurfaceDefault
        : AppColors.warningSurfaceDefault;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: entry.isCritical
            ? Border.all(color: AppColors.dangerSurfaceDefault, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: fillColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  entry.priorityClass,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: fillColor,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  entry.itemName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
              ),
              Text(
                '${entry.currentQuantity} / ${entry.baseQuantity}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: fillColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: entry.fillRatio,
              minHeight: 6.h,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.locationName,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
              ),
              Text(
                inventoryPriorityDescription(
                  entry.priorityClass,
                  entry.slaHours,
                ),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrdtOperationTile extends StatelessWidget {
  final OperationsSnapshot snapshot;
  final CrdtOperationEntry op;
  final String localNode;
  const _CrdtOperationTile({
    required this.snapshot,
    required this.op,
    required this.localNode,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = op.syncNodeUuid == localNode;
    final statusColor = op.isConflicted
        ? AppColors.dangerSurfaceDefault
        : op.syncedAt != null
        ? AppColors.primarySurfaceDefault
        : AppColors.warningSurfaceDefault;
    final statusLabel = op.isConflicted
        ? 'Conflicted'
        : op.syncedAt != null
        ? 'Synced'
        : 'Pending';
    final originLabel = snapshot.labelForNode(op.syncNodeUuid);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              op.opType == 'increment'
                  ? Icons.arrow_upward
                  : op.opType == 'decrement'
                  ? Icons.arrow_downward
                  : op.opType == 'merge'
                  ? Icons.merge_type
                  : Icons.edit,
              size: 18.sp,
              color: statusColor,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${op.opType.toUpperCase()}  ${op.entityType}.${op.fieldName}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${isLocal ? "This device" : originLabel}  ·  ${op.oldValue} → ${op.newValue}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final OperationsSnapshot snapshot;
  final SyncConflictEntry conflict;
  final ValueChanged<String> onResolve;

  const _ConflictCard({
    required this.snapshot,
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final isResolved = conflict.isResolved;
    final entityTitle = conflict.entityType == 'inventory'
        ? (snapshot.inventoryItemNameForEntity(conflict.entityId) ??
            'Inventory item')
        : conflict.entityType;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: !isResolved
            ? Border.all(color: AppColors.dangerSurfaceDefault, width: 1.5)
            : Border.all(color: AppColors.primarySurfaceDefault, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isResolved ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 20.sp,
                color: isResolved
                    ? AppColors.primarySurfaceDefault
                    : AppColors.dangerSurfaceDefault,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '$entityTitle · ${conflict.fieldName}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _ConflictValueBox(
                  label: 'Value A',
                  value: '${conflict.valueA}',
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'vs',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ConflictValueBox(
                  label: 'Value B',
                  value: '${conflict.valueB}',
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          if (isResolved) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primarySurfaceDefault.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.merge_type,
                    size: 14.sp,
                    color: AppColors.primarySurfaceDefault,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Resolved: ${conflict.resolution}  →  ${conflict.resolvedValue}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primarySurfaceDefault,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                _ResolutionButton(
                  label: 'Accept A',
                  color: Colors.blue,
                  onPressed: () => onResolve('a_wins'),
                ),
                SizedBox(width: 8.w),
                _ResolutionButton(
                  label: 'Accept B',
                  color: Colors.deepOrange,
                  onPressed: () => onResolve('b_wins'),
                ),
                SizedBox(width: 8.w),
                _ResolutionButton(
                  label: 'Merge',
                  color: AppColors.primarySurfaceDefault,
                  onPressed: () => onResolve('merged'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ConflictValueBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ConflictValueBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolutionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ResolutionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          foregroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
