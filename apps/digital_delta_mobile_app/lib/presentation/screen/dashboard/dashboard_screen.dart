import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../domain/model/operations/operations_snapshot_model.dart';
import '../../connectivity/notifier/provider.dart';
import '../../theme/color.dart';
import 'notifier/operations_notifier.dart';
import 'notifier/provider.dart';
import 'notifier/sync_hub_notifier.dart';

Future<void> _syncDashboardPull(WidgetRef ref) async {
  final online = ref.read(connectivityNotifierProvider).maybeWhen(
        online: (_) => true,
        orElse: () => false,
      );
  if (online) {
    await ref.read(syncHubProvider.notifier).syncAllWithBackend(
          ref.read(operationsNotifierProvider.notifier),
        );
  } else {
    await ref.read(operationsNotifierProvider.notifier).refresh();
    await ref.read(syncHubProvider.notifier).refreshMetadataOnly();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Module 2 — Offline-First Distributed Database & CRDT Sync
// M2.1  CRDT Inventory Ledger (LWW-Register / G-Counter)
// M2.2  Vector Clock Causal Ordering
// M2.3  Conflict Detection & Resolution
// M2.4  Delta Sync over BLE (simulated)
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opsState = ref.watch(operationsNotifierProvider);
    final connectivity = ref.watch(connectivityNotifierProvider);

    final syncInfo = connectivity.when(
      initial: () => ('Initializing', Colors.grey, Icons.hourglass_empty),
      online: (_) => ('Online', Colors.green, Icons.cloud_done),
      offline: () => ('Offline', Colors.orange, Icons.cloud_off),
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.colorBackground,
        appBar: AppBar(
          title: Text('Supply & Delivery Status',
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              tooltip: 'Sync with server',
              onPressed: () => _syncDashboardPull(ref),
              icon: Icon(Icons.sync, size: 22.sp),
            ),
            _SyncBadge(label: syncInfo.$1, color: syncInfo.$2, icon: syncInfo.$3),
            SizedBox(width: 12.w),
          ],
          bottom: TabBar(
            labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Inventory'),
              Tab(text: 'Clocks'),
              Tab(text: 'Conflicts'),
            ],
          ),
        ),
        body: opsState.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SyncHubStrip(),
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (msg) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SyncHubStrip(),
              Expanded(child: _ErrorView(msg: msg)),
            ],
          ),
          loaded: (snap) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SyncHubStrip(),
              Expanded(child: _DashboardTabs(snapshot: snap)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncHubStrip extends ConsumerWidget {
  const _SyncHubStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(syncHubProvider);
    final online = ref.watch(connectivityNotifierProvider).maybeWhen(
          online: (_) => true,
          orElse: () => false,
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 4.h),
      child: hub.when(
        loading: () => ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: const LinearProgressIndicator(minHeight: 3),
        ),
        error: (e, _) => Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.dangerSurfaceTint,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.dangerSurfaceDefault.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            'Server sync info unavailable: $e',
            style: TextStyle(fontSize: 11.sp, color: AppColors.primaryTextDefault),
          ),
        ),
        data: (snap) => Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(12.r),
          color: online
              ? AppColors.primarySurfaceTint
              : AppColors.warningSurfaceDefault.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                      size: 18.sp,
                      color: online
                          ? AppColors.statusOnline
                          : AppColors.statusPending,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        snap.offline
                            ? 'Offline — local CRDT ledger; reconnect for /api/sync push & pull'
                            : 'Online — REST sync (/api/sync) + CRDT when you pull to refresh',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTextDefault,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!snap.offline) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Server mesh nodes: ${snap.meshNodes.length} · Server open conflicts: ${snap.openConflicts.length}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.secondaryTextDefault,
                    ),
                  ),
                ],
                if (snap.notes.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  ...snap.notes.map(
                    (n) => Padding(
                      padding: EdgeInsets.only(top: 3.h),
                      child: Text(
                        n,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.statusPending,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab body ─────────────────────────────────────────────────────────────────

class _DashboardTabs extends ConsumerWidget {
  final OperationsSnapshot snapshot;
  const _DashboardTabs({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(operationsNotifierProvider.notifier);
    return TabBarView(
      children: [
        _InventoryTab(snapshot: snapshot, notifier: notifier),
        _ClocksTab(snapshot: snapshot),
        _ConflictsTab(snapshot: snapshot, notifier: notifier),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1 — Inventory Ledger (M2.1)
// ═════════════════════════════════════════════════════════════════════════════

class _InventoryTab extends ConsumerWidget {
  final OperationsSnapshot snapshot;
  final OperationsNotifier notifier;
  const _InventoryTab({required this.snapshot, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = snapshot.summary;
    return RefreshIndicator(
      onRefresh: () => _syncDashboardPull(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 120.h),
        children: [
          // ── Quick stats ────────────────────────────────────────────────
          Row(children: [
            _StatChip(icon: Icons.pending_actions, value: '${summary.pendingOperations}',  label: 'Pending',  color: AppColors.statusPending),
            SizedBox(width: 8.w),
            _StatChip(icon: Icons.check_circle_outline, value: '${summary.syncedOperations}', label: 'Synced',  color: AppColors.statusOnline),
            SizedBox(width: 8.w),
            _StatChip(icon: Icons.warning_amber_rounded, value: '${summary.openConflicts}', label: 'Conflicts',
                color: summary.openConflicts > 0 ? AppColors.dangerSurfaceDefault : AppColors.statusIdle),
          ]),
          SizedBox(height: 14.h),

          // ── Action bar ─────────────────────────────────────────────────
          _ActionRow(children: [
            _ActionBtn(icon: Icons.add_box_outlined,   label: 'Add Item',    color: AppColors.primarySurfaceDefault,
                onTap: () => _showAddDialog(context, notifier)),
            _ActionBtn(icon: Icons.edit_outlined,      label: 'Update',      color: AppColors.priorityP2,
                onTap: snapshot.inventory.isEmpty ? null : notifier.createLocalDelta),
            _ActionBtn(icon: Icons.sync,               label: 'Peer Sync',   color: AppColors.nodeDroneBase,
                onTap: notifier.simulatePeerSync),
            _ActionBtn(icon: Icons.flash_on_outlined,  label: 'Conflict!',   color: AppColors.dangerSurfaceDefault,
                onTap: snapshot.inventory.isEmpty ? null : notifier.injectConflict),
          ]),
          SizedBox(height: 16.h),

          // ── Section header ─────────────────────────────────────────────
          _SectionHeader(title: 'Supply Inventory',
              subtitle: 'Auto-synced · ${snapshot.inventory.length} items'),
          SizedBox(height: 8.h),

          if (snapshot.inventory.isEmpty)
            _EmptyCard(
              icon: Icons.inventory_2_outlined,
              title: 'No inventory yet',
              subtitle: 'Tap "Add Item" or pull-to-refresh to seed demo data',
            )
          else
            ...snapshot.inventory.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _InventoryCard(item: item),
            )),

          SizedBox(height: 16.h),

          // ── Operations log ─────────────────────────────────────────────
          _SectionHeader(title: 'Activity Log',
              subtitle: 'Recent updates · last ${snapshot.operations.length}'),
          SizedBox(height: 8.h),

          if (snapshot.operations.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text('No operations yet. Create a delta to start.',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500)),
            )
          else
            ...snapshot.operations.map((op) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: _OperationTile(op: op, localNode: snapshot.summary.localNodeUuid),
            )),
        ],
      ),
    );
  }

  static void _showAddDialog(BuildContext ctx, OperationsNotifier notifier) {
    final nameCtrl    = TextEditingController();
    final locationCtrl = TextEditingController();
    final baseQtyCtrl = TextEditingController();
    final curQtyCtrl  = TextEditingController();
    final slaCtrl     = TextEditingController(text: '24');
    String prio = 'P1';

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Inventory Item'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name *', hintText: 'e.g. Antivenom Kits')),
              const SizedBox(height: 8),
              TextField(controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location *', hintText: 'e.g. Sylhet City Hub')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: baseQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Base Qty *'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: curQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Current Qty *'))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: prio,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: ['P0', 'P1', 'P2', 'P3']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setSt(() => prio = v ?? 'P1'),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: slaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Deadline (hrs)'))),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name  = nameCtrl.text.trim();
                final loc   = locationCtrl.text.trim();
                final base  = int.tryParse(baseQtyCtrl.text.trim());
                final cur   = int.tryParse(curQtyCtrl.text.trim());
                final sla   = int.tryParse(slaCtrl.text.trim()) ?? 24;
                if (name.isEmpty || loc.isEmpty || base == null || cur == null) return;
                final rank = switch (prio) { 'P0' => 0, 'P1' => 1, 'P2' => 2, _ => 3 };
                notifier.addInventoryItem(
                  itemId: DateTime.now().millisecondsSinceEpoch.toString(),
                  itemName: name, locationName: loc,
                  baseQuantity: base, currentQuantity: cur,
                  priorityClass: prio, priorityRank: rank, slaHours: sla,
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

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2 — Vector Clocks (M2.2)
// ═════════════════════════════════════════════════════════════════════════════

class _ClocksTab extends ConsumerWidget {
  final OperationsSnapshot snapshot;
  const _ClocksTab({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = snapshot.summary.vectorClock;
    final localId = snapshot.summary.localNodeUuid;
    final ops = snapshot.operations;

    return RefreshIndicator(
      onRefresh: () => _syncDashboardPull(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        children: [
        // ── What are vector clocks? ────────────────────────────────────
        _InfoCard(
          icon: Icons.account_tree_outlined,
          color: Colors.indigo,
          title: 'Update History',
          body: 'Every change is tracked across all devices. '
              'When two devices edit the same item at the same time, a conflict is flagged. '
              'The full change history is preserved even when devices are offline.',
        ),
        SizedBox(height: 14.h),

        // ── Merged vector clock ────────────────────────────────────────
        _SectionHeader(title: 'Device Sync Timeline', subtitle: '${vc.length} device(s)'),
        SizedBox(height: 8.h),
        if (vc.isEmpty)
          _EmptyCard(icon: Icons.schedule, title: 'No activity yet',
              subtitle: 'Make updates to see the sync timeline')
        else
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: vc.entries.map((e) {
                final isLocal = e.key == localId;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(children: [
                    Container(
                      width: 10.w, height: 10.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLocal ? AppColors.primarySurfaceDefault : Colors.deepPurple,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(child: Text(
                      isLocal ? 'This device' : e.key.length > 16 ? '${e.key.substring(0, 16)}…' : e.key,
                      style: TextStyle(fontSize: 12.sp, color: Colors.indigo.shade800,
                          fontWeight: isLocal ? FontWeight.w700 : FontWeight.normal),
                    )),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: (isLocal ? AppColors.primarySurfaceDefault : Colors.deepPurple).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text('t=${e.value}',
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700,
                              color: isLocal ? AppColors.primarySurfaceDefault : Colors.deepPurple)),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        SizedBox(height: 16.h),

        // ── Per-operation breakdown ────────────────────────────────────
        _SectionHeader(title: 'Change History', subtitle: '${ops.length} updates'),
        SizedBox(height: 8.h),
        if (ops.isEmpty)
          Text('No operations logged yet.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500))
        else
          ...ops.map((op) {
            final nodeVc = op.vectorClock;
            final isLocal = op.syncNodeUuid == localId;
            return Container(
              margin: EdgeInsets.only(bottom: 6.h),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: isLocal
                    ? AppColors.primarySurfaceDefault.withValues(alpha: 0.3)
                    : Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(isLocal ? Icons.phone_android : Icons.devices_other,
                      size: 14.sp, color: isLocal ? AppColors.primarySurfaceDefault : Colors.purple),
                  SizedBox(width: 6.w),
                  Expanded(child: Text(
                    '${op.opType.toUpperCase()} · ${op.fieldName}',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  )),
                  if (op.isConflicted)
                    _Chip(label: 'CONFLICT', color: Colors.red),
                ]),
                SizedBox(height: 4.h),
                Text(
                  'VC: { ${nodeVc.entries.map((e) => '${e.key.length > 8 ? e.key.substring(0, 8) : e.key}: ${e.value}').join(', ')} }',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600, fontFamily: 'monospace'),
                ),
              ]),
            );
          }),
      ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 3 — Conflict Resolution (M2.3)
// ═════════════════════════════════════════════════════════════════════════════

class _ConflictsTab extends ConsumerWidget {
  final OperationsSnapshot snapshot;
  final OperationsNotifier notifier;
  const _ConflictsTab({required this.snapshot, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open    = snapshot.conflicts.where((c) => c.resolution == null).toList();
    final resolved = snapshot.conflicts.where((c) => c.resolution != null).toList();

    return RefreshIndicator(
      onRefresh: () => _syncDashboardPull(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        children: [
        _InfoCard(
          icon: Icons.merge_type,
          color: Colors.red,
          title: 'Conflict Resolution',
          body: 'When two devices edit the same item at the same time, '
              'a conflict appears here. Choose which version to keep, or merge both.',
        ),
        SizedBox(height: 14.h),

        // ── Inject demo button ─────────────────────────────────────────
        _ActionRow(children: [
          _ActionBtn(icon: Icons.flash_on_outlined, label: 'Inject Conflict',
              color: Colors.red, onTap: notifier.injectConflict),
          _ActionBtn(icon: Icons.sync, label: 'Peer Sync',
              color: Colors.deepPurple, onTap: notifier.simulatePeerSync),
        ]),
        SizedBox(height: 16.h),

        // ── Open conflicts ─────────────────────────────────────────────
        _SectionHeader(title: 'Open Conflicts', subtitle: '${open.length} unresolved'),
        SizedBox(height: 8.h),
        if (open.isEmpty)
          _EmptyCard(icon: Icons.check_circle_outline, title: 'No open conflicts',
              subtitle: 'Tap "Inject Conflict" to demo the resolution flow')
        else
          ...open.map((c) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _ConflictCard(conflict: c, snapshot: snapshot,
                onResolve: (r) => notifier.resolveConflict(conflictId: c.id, resolution: r)),
          )),

        if (resolved.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _SectionHeader(title: 'Resolved Conflicts', subtitle: '${resolved.length} resolved'),
          SizedBox(height: 8.h),
          ...resolved.map((c) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: _ResolvedConflictTile(conflict: c),
          )),
        ],
      ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widget Library
// ─────────────────────────────────────────────────────────────────────────────

class _SyncBadge extends StatelessWidget {
  final String label;
  final Color  color;
  final IconData icon;
  const _SyncBadge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: color, width: 1.2),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13.sp, color: color),
      SizedBox(width: 4.w),
      Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700,
          color: AppColors.primaryTextDefault)),
      if (subtitle != null) ...[
        SizedBox(width: 8.w),
        Text(subtitle!, style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
      ],
    ],
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color  color;
  const _StatChip({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(width: 6.w),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: color)),
          Text(label,  style: TextStyle(fontSize: 9.sp,  color: AppColors.secondaryTextDefault)),
        ]),
      ]),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  final List<Widget> children;
  const _ActionRow({required this.children});

  @override
  Widget build(BuildContext context) => Row(
    children: children.map((c) => Expanded(child: c)).toList(),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color  color;
  final VoidCallback? onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: Material(
        color: enabled ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 18.sp, color: enabled ? color : Colors.grey.shade400),
              SizedBox(height: 3.h),
              Text(label, style: TextStyle(fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : Colors.grey.shade400),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _InfoCard({required this.icon, required this.color, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(14.w),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20.sp, color: color),
      SizedBox(width: 10.w),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: color)),
        SizedBox(height: 4.h),
        Text(body, style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault, height: 1.4)),
      ])),
    ]),
  );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(24.w),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(children: [
      Icon(icon, size: 40.sp, color: Colors.grey.shade400),
      SizedBox(height: 8.h),
      Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      SizedBox(height: 4.h),
      Text(subtitle, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500), textAlign: TextAlign.center),
    ]),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20.r),
    ),
    child: Text(label, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: color)),
  );
}

// ── Inventory card (M2.1) ──────────────────────────────────────────────────

class _InventoryCard extends StatelessWidget {
  final InventoryLedgerEntry item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final prio  = item.priorityClass;
    final color = switch (prio) {
      'P0' => Colors.red,
      'P1' => Colors.orange,
      'P2' => Colors.blue,
      _    => Colors.grey,
    };
    final fill = item.baseQuantity > 0
        ? (item.currentQuantity / item.baseQuantity).clamp(0.0, 1.0)
        : 0.0;
    final isLow = fill < 0.3;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isLow ? Colors.red.withValues(alpha: 0.4) : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Chip(label: prio, color: color),
          SizedBox(width: 8.w),
          Expanded(child: Text(item.itemName,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
          Text('${item.currentQuantity}/${item.baseQuantity}',
              style: TextStyle(fontSize: 12.sp, color: isLow ? Colors.red : AppColors.secondaryTextDefault,
                  fontWeight: FontWeight.w600)),
        ]),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 6.h,
            backgroundColor: Colors.grey.shade200,
            color: isLow ? Colors.red : color,
          ),
        ),
        SizedBox(height: 6.h),
        Row(children: [
          Icon(Icons.location_on_outlined, size: 12.sp, color: AppColors.secondaryTextDefault),
          SizedBox(width: 3.w),
          Expanded(child: Text(item.locationName,
              style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault),
              overflow: TextOverflow.ellipsis)),
          Icon(Icons.schedule, size: 12.sp, color: AppColors.secondaryTextDefault),
          SizedBox(width: 3.w),
          Text('Deadline ${item.slaHours}h',
              style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
        ]),
        SizedBox(height: 4.h),
        // Vector clock snippet
        if (item.vectorClock.isNotEmpty)
          Text(
            'VC: ${item.vectorClock.entries.map((e) => 't${e.value}').join('·')}',
            style: TextStyle(fontSize: 9.sp, color: Colors.indigo.shade400, fontFamily: 'monospace'),
          ),
      ]),
    );
  }
}

// ── Operation tile (M2.2) ─────────────────────────────────────────────────

class _OperationTile extends StatelessWidget {
  final CrdtOperationEntry op;
  final String localNode;
  const _OperationTile({required this.op, required this.localNode});

  @override
  Widget build(BuildContext context) {
    final isLocal  = op.syncNodeUuid == localNode;
    final color    = switch (op.opType) {
      'increment' || 'set' => Colors.green,
      'decrement'          => Colors.orange,
      'merge'              => Colors.blue,
      _                    => Colors.grey,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: op.isConflicted
            ? Colors.red.withValues(alpha: 0.4)
            : Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          width: 34.w, height: 34.w,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(_opIcon(op.opType), size: 16.sp, color: color),
        ),
        SizedBox(width: 10.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(op.opType.toUpperCase(),
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: color)),
            SizedBox(width: 6.w),
            Text(isLocal ? 'local' : op.syncNodeUuid.length > 12
                ? op.syncNodeUuid.substring(0, 12) : op.syncNodeUuid,
                style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryTextDefault)),
          ]),
          Text('${op.oldValue ?? '?'} → ${op.newValue ?? '?'}',
              style: TextStyle(fontSize: 11.sp, color: AppColors.primaryTextDefault)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (op.isConflicted) _Chip(label: 'CONFLICT', color: Colors.red),
          if (op.syncedAt != null) _Chip(label: 'SYNCED', color: Colors.green),
          if (op.syncedAt == null && !op.isConflicted) _Chip(label: 'PENDING', color: Colors.orange),
        ]),
      ]),
    );
  }

  static IconData _opIcon(String type) => switch (type) {
    'increment' => Icons.add,
    'decrement' => Icons.remove,
    'set'       => Icons.edit,
    'merge'     => Icons.merge_type,
    _           => Icons.circle_outlined,
  };
}

// ── Conflict card (M2.3) ──────────────────────────────────────────────────

class _ConflictCard extends StatelessWidget {
  final SyncConflictEntry conflict;
  final OperationsSnapshot snapshot;
  final void Function(String) onResolve;
  const _ConflictCard({required this.conflict, required this.snapshot, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded, size: 18.sp, color: Colors.red),
          SizedBox(width: 8.w),
          Expanded(child: Text(
            'Conflict: ${conflict.fieldName} on entity #${conflict.entityId}',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.red.shade800),
          )),
        ]),
        SizedBox(height: 10.h),
        // Side-by-side value comparison
        Row(children: [
          Expanded(child: _ValueBox(
            label: 'Value A  (local)',
            value: '${conflict.valueA}',
            color: AppColors.primarySurfaceDefault,
          )),
          SizedBox(width: 8.w),
          Expanded(child: _ValueBox(
            label: 'Value B  (peer)',
            value: '${conflict.valueB}',
            color: Colors.purple,
          )),
        ]),
        SizedBox(height: 12.h),
        // Resolution buttons
        Row(children: [
          _ResolveBtn(label: 'A Wins', color: AppColors.primarySurfaceDefault,
              onTap: () => onResolve('a_wins')),
          SizedBox(width: 8.w),
          _ResolveBtn(label: 'B Wins', color: Colors.purple,
              onTap: () => onResolve('b_wins')),
          SizedBox(width: 8.w),
          _ResolveBtn(label: 'Merge (max)', color: Colors.teal,
              onTap: () => onResolve('merged')),
        ]),
      ]),
    );
  }
}

class _ValueBox extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _ValueBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10.sp, color: color, fontWeight: FontWeight.w600)),
      SizedBox(height: 4.h),
      Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: color)),
    ]),
  );
}

class _ResolveBtn extends StatelessWidget {
  final String label;
  final Color  color;
  final VoidCallback onTap;
  const _ResolveBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        elevation: 0,
      ),
      child: Text(label, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700)),
    ),
  );
}

class _ResolvedConflictTile extends StatelessWidget {
  final SyncConflictEntry conflict;
  const _ResolvedConflictTile({required this.conflict});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: Colors.green.shade200),
    ),
    child: Row(children: [
      Icon(Icons.check_circle, size: 16.sp, color: Colors.green),
      SizedBox(width: 8.w),
      Expanded(child: Text(
        'entity #${conflict.entityId} · ${conflict.fieldName} → ${conflict.resolvedValue}',
        style: TextStyle(fontSize: 11.sp, color: Colors.green.shade800),
      )),
      _Chip(label: conflict.resolution?.toUpperCase() ?? 'RESOLVED', color: Colors.green),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  final String msg;
  const _ErrorView({required this.msg});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
        SizedBox(height: 12.h),
        Text('CRDT engine error', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.red)),
        SizedBox(height: 8.h),
        Text(msg, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600), textAlign: TextAlign.center),
      ]),
    ),
  );
}
