import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/mesh/battery_mesh_throttler.dart';
import '../../../data/service/nearby_mesh_service.dart';
import '../../../di/cache_module.dart';
import '../../../domain/model/operations/operations_snapshot_model.dart';
import '../../theme/color.dart';
import '../../util/routes.dart';
import '../dashboard/notifier/operations_notifier.dart';
import '../dashboard/notifier/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Module 3 — Ad-Hoc Mesh Network Protocol
// M3.1  Store-and-Forward message relay (TTL + hop count + deduplication)
// M3.2  Dual-Role Node Architecture  (Client ↔ Relay based on battery/signal)
// M3.3  End-to-End encryption (relay nodes cannot read payloads)
// ─────────────────────────────────────────────────────────────────────────────

class MeshScanScreen extends ConsumerStatefulWidget {
  const MeshScanScreen({super.key});

  @override
  ConsumerState<MeshScanScreen> createState() => _MeshScanScreenState();
}

class _MeshScanScreenState extends ConsumerState<MeshScanScreen> {
  StreamSubscription<List<MeshPeer>>? _peersSub;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMesh());
  }

  Future<void> _startMesh() async {
    if (!Platform.isAndroid) return;
    final nearbyService = getIt<NearbyMeshService>();
    if (nearbyService.isRunning) return;

    // Load the local node identity from the already-bootstrapped SyncMeshService.
    final snapshot =
        await ref.read(operationsNotifierProvider.notifier).loadSnapshotDirect();
    if (snapshot == null || !mounted) return;

    setState(() => _isScanning = true);

    await nearbyService.start(
      localNodeUuid: snapshot.summary.localNodeUuid,
      localDisplayName: snapshot.summary.localNodeName,
    );

    // Refresh the ops snapshot every time the peer list changes so the
    // Devices tab reflects newly discovered / disconnected nodes.
    _peersSub = nearbyService.peersStream.listen((_) {
      if (mounted) {
        ref.read(operationsNotifierProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _peersSub?.cancel();
    getIt<NearbyMeshService>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opsState = ref.watch(operationsNotifierProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B2A),
          foregroundColor: Colors.white,
          title: Text('Nearby Device Network',
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700, color: Colors.white)),
          actions: [
            // Scanning indicator
            if (_isScanning)
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Tooltip(
                  message: 'Searching for nearby devices…',
                  child: SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.tealAccent,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, size: 22.sp, color: Colors.white70),
              tooltip: 'Open chat with first connected peer',
              onPressed: () {
                final nearbyService = getIt<NearbyMeshService>();
                final connectedPeers = nearbyService.currentPeers
                    .where((p) => p.isConnected)
                    .toList();
                if (connectedPeers.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No connected peers yet — wait for a nearby device to appear.'),
                    ),
                  );
                  return;
                }
                final peer = connectedPeers.first;
                Navigator.pushNamed(context, Routes.meshChat, arguments: {
                  'peerNodeUuid': peer.nodeUuid,
                  'peerName':     peer.displayName,
                });
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primarySurfaceDefault,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Devices'),
              Tab(text: 'Messages'),
              Tab(text: 'Security'),
            ],
          ),
        ),
        body: opsState.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error:   (msg) => Center(child: Text(msg, style: const TextStyle(color: Colors.red))),
          loaded:  (snap) => _MeshTabs(snapshot: snap),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MeshTabs extends ConsumerWidget {
  final OperationsSnapshot snapshot;
  const _MeshTabs({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(operationsNotifierProvider.notifier);
    return TabBarView(
      children: [
        _TopologyTab(snapshot: snapshot, notifier: notifier),
        _RelayQueueTab(snapshot: snapshot, notifier: notifier),
        _EncryptionTab(snapshot: snapshot, notifier: notifier),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1 — Mesh Topology (M3.2 dual-role)
// ═════════════════════════════════════════════════════════════════════════════

class _TopologyTab extends StatelessWidget {
  final OperationsSnapshot snapshot;
  final OperationsNotifier notifier;
  const _TopologyTab({required this.snapshot, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final nodes      = snapshot.nodes;
    final summary    = snapshot.summary;
    final localNode  = summary.localNodeUuid;
    final peers      = nodes.where((n) => n.nodeUuid != localNode).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 120.h),
      children: [
        // ── M8.4 Battery Throttle Panel ───────────────────────────────
        const _BatteryThrottlePanel(),
        SizedBox(height: 14.h),

        // ── Quick stats ────────────────────────────────────────────────
        Row(children: [
          _MeshStat(icon: Icons.hub_outlined,    value: '${peers.length}',          label: 'Devices',   color: Colors.teal),
          SizedBox(width: 8.w),
          _MeshStat(icon: Icons.cell_tower,      value: '${summary.relayCapableNodes}', label: 'Helpers',  color: Colors.deepPurple),
          SizedBox(width: 8.w),
          _MeshStat(icon: Icons.mail_outline,    value: '${summary.queuedMessages}', label: 'Queued',  color: Colors.pink),
          SizedBox(width: 8.w),
          _MeshStat(icon: Icons.warning_amber_outlined, value: '${summary.openConflicts}',  label: 'Conflicts', color: Colors.orange),
        ]),
        SizedBox(height: 14.h),

        // ── Action row ─────────────────────────────────────────────────
        _DemoActionRow(children: [
          _DemoBtn(icon: Icons.send_outlined,   label: 'Queue Msg',  color: Colors.blue,       onTap: notifier.queueDemoMessage),
          _DemoBtn(icon: Icons.forward,         label: 'Forward',    color: Colors.deepPurple, onTap: notifier.relayNextMessage),
          _DemoBtn(icon: Icons.sync,            label: 'Refresh',    color: Colors.grey,       onTap: notifier.refresh),
        ]),
        SizedBox(height: 16.h),

        // ── Local node identity ────────────────────────────────────────
        _LocalNodeCard(summary: summary),
        SizedBox(height: 12.h),

        // ── Remote peers ───────────────────────────────────────────────
        _SectionHeader(title: 'Nearby Devices', subtitle: '${peers.length} found'),
        SizedBox(height: 8.h),
        if (peers.isEmpty)
          const _EmptyMesh()
        else
          ...peers.map((n) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _NodeTile(node: n),
          )),

        // ── Relay hop log ──────────────────────────────────────────────
        if (snapshot.relayLogs.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _SectionHeader(title: 'Relay Hop Log', subtitle: '${snapshot.relayLogs.length} hops'),
          SizedBox(height: 8.h),
          ...snapshot.relayLogs.take(6).map((log) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: _HopTile(log: log, snapshot: snapshot),
          )),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2 — Store-and-Forward Queue (M3.1)
// ═════════════════════════════════════════════════════════════════════════════

class _RelayQueueTab extends StatelessWidget {
  final OperationsSnapshot snapshot;
  final OperationsNotifier notifier;
  const _RelayQueueTab({required this.snapshot, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final msgs     = snapshot.messages;
    final pending  = msgs.where((m) => !m.isDelivered).toList();
    final delivered = msgs.where((m) => m.isDelivered).toList();

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // M3.1 info card
        _InfoCard(
          icon: Icons.swap_horiz,
          color: Colors.blue,
          title: 'Save & Forward Messages',
          body: 'Messages are saved and delivered even if some devices go offline along the way. '
              'Each message stays active for 24 hours and is forwarded across up to 10 devices. Tap "Send Msg" then "Forward" to try it.',
        ),
        SizedBox(height: 14.h),

        // Action row
        _DemoActionRow(children: [
          _DemoBtn(icon: Icons.send_outlined,  label: 'Send Msg',   color: Colors.blue,       onTap: notifier.queueDemoMessage),
          _DemoBtn(icon: Icons.forward,        label: 'Forward',    color: Colors.deepPurple, onTap: notifier.relayNextMessage),
          _DemoBtn(icon: Icons.sync,           label: 'Refresh',    color: Colors.grey,       onTap: notifier.refresh),
        ]),
        SizedBox(height: 16.h),

        // Pending messages
        _SectionHeader(title: 'Waiting to Send', subtitle: '${pending.length} messages'),
        SizedBox(height: 8.h),
        if (pending.isEmpty)
          _EmptyQueueCard()
        else
          ...pending.map((m) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _MessageTile(msg: m, snapshot: snapshot),
          )),

        if (delivered.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _SectionHeader(title: 'Delivered', subtitle: '${delivered.length} messages'),
          SizedBox(height: 8.h),
          ...delivered.take(4).map((m) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: _MessageTile(msg: m, snapshot: snapshot),
          )),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 3 — E2E Encryption (M3.3)
// ═════════════════════════════════════════════════════════════════════════════

class _EncryptionTab extends StatelessWidget {
  final OperationsSnapshot snapshot;
  final OperationsNotifier notifier;
  const _EncryptionTab({required this.snapshot, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final msgs = snapshot.messages;

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _InfoCard(
          icon: Icons.lock_outlined,
          color: Colors.green,
          title: 'Private Messaging',
          body: 'All messages are scrambled so only the intended recipient can read them. '
              'Other devices that pass the message along cannot see its contents. '
              'Only the person you are sending to can unlock and read the message.',
        ),
        SizedBox(height: 14.h),

        // Encryption proof: node key table
        _SectionHeader(title: 'Device Security Keys', subtitle: '${snapshot.nodes.length} devices'),
        SizedBox(height: 8.h),
        if (snapshot.nodes.isEmpty)
          _InfoCard(icon: Icons.key_off, color: Colors.grey,
              title: 'No devices yet',
              body: 'Add demo devices to see their security keys here')
        else
          ...snapshot.nodes.map((n) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: _KeyCard(node: n, isLocal: n.nodeUuid == snapshot.summary.localNodeUuid),
          )),

        SizedBox(height: 16.h),

        // Encrypted payload inspector
        _SectionHeader(title: 'Message Details', subtitle: '${msgs.length} messages'),
        SizedBox(height: 8.h),
        if (msgs.isEmpty)
          _InfoCard(icon: Icons.mail_lock_outlined, color: Colors.grey,
              title: 'No messages yet',
              body: 'Send a message to see its details here')
        else
          ...msgs.take(4).map((m) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _PayloadInspector(msg: m, snapshot: snapshot),
          )),

        SizedBox(height: 16.h),

        // Cryptographic standards compliance
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Security Standards',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.green)),
            SizedBox(height: 8.h),
            ...[
              ('Key Algorithm', 'Ed25519 (256-bit)'),
              ('Payload Encryption', 'AES-256-GCM (via Ed25519 KEM)'),
              ('Hash Function', 'SHA-256'),
              ('Banned', 'MD5, SHA-1, DES — never used'),
              ('Transport', 'TLS 1.3 for server channels'),
            ].map((e) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(children: [
                Icon(Icons.check_circle, size: 12.sp, color: Colors.green),
                SizedBox(width: 6.w),
                Text('${e.$1}: ', style: TextStyle(fontSize: 11.sp, color: Colors.white54)),
                Expanded(child: Text(e.$2, style: TextStyle(fontSize: 11.sp, color: Colors.white))),
              ]),
            )),
          ]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// M8.4 Battery Throttle Panel (collapsible)
// ─────────────────────────────────────────────────────────────────────────────

class _BatteryThrottlePanel extends StatefulWidget {
  const _BatteryThrottlePanel();

  @override
  State<_BatteryThrottlePanel> createState() => _BatteryThrottlePanelState();
}

class _BatteryThrottlePanelState extends State<_BatteryThrottlePanel> {
  final BatteryMeshThrottler _throttler = BatteryMeshThrottler();
  ThrottleStats? _simStats;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _throttler.addListener(_rebuild);
    _throttler.startMonitoring();
  }

  @override
  void dispose() {
    _throttler.removeListener(_rebuild);
    _throttler.stopMonitoring();
    _throttler.dispose();
    super.dispose();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  Future<void> _runSim() async {
    setState(() => _simStats = null);
    try {
      final s = await _throttler.runSimulation();
      if (mounted) setState(() => _simStats = s);
    } catch (_) {}
  }

  Color _factorColor(double f) =>
      f >= 0.8 ? Colors.green : f >= 0.4 ? Colors.orange : Colors.red;

  @override
  Widget build(BuildContext context) {
    final factor       = _throttler.throttleFactor;
    final intervalSecs = _throttler.currentIntervalSecs;
    final battery      = _throttler.batteryLevel;
    final rules        = _throttler.log.isNotEmpty ? _throttler.log.last.activeRules : <String>[];
    final isSim        = _throttler.isSimulating;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(children: [
                Icon(Icons.battery_charging_full, size: 15.sp, color: _factorColor(factor)),
                SizedBox(width: 8.w),
                Text('Battery Saving Mode',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _factorColor(factor).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text('×${factor.toStringAsFixed(2)}  ${intervalSecs}s',
                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600,
                          color: _factorColor(factor))),
                ),
                SizedBox(width: 6.w),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18.sp, color: Colors.white54),
              ]),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: Colors.white12),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _ThrottleStat('Battery', '$battery%${_throttler.isCharging ? ' ⚡' : ''}',
                      battery < 30 ? Colors.red : Colors.green),
                  SizedBox(width: 16.w),
                  _ThrottleStat('Interval', '${intervalSecs}s', AppColors.primarySurfaceDefault),
                  SizedBox(width: 16.w),
                  _ThrottleStat('Stationary', _throttler.isStationary ? 'Yes' : 'No',
                      _throttler.isStationary ? Colors.orange : Colors.green),
                ]),
                if (rules.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Wrap(spacing: 6.w, runSpacing: 4.h, children: rules.map((r) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Text(r, style: TextStyle(fontSize: 9.sp, color: Colors.orange)),
                  )).toList()),
                ],
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSim ? null : _runSim,
                    icon: isSim
                        ? SizedBox(width: 12.w, height: 12.h,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.play_arrow, size: 14.sp),
                    label: Text(isSim ? 'Simulating…' : 'Run 10-min Simulation',
                        style: TextStyle(fontSize: 11.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySurfaceDefault,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ),
                if (_simStats != null) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      _SimStat('Scans saved',   '${_simStats!.totalScansSaved}'),
                      _SimStat('Avg ×factor',   '×${_simStats!.avgThrottleFactor.toStringAsFixed(2)}'),
                      _SimStat('Energy saved',  '${_simStats!.energySavedMj.toStringAsFixed(1)} mJ'),
                    ]),
                  ),
                ],
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThrottleStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ThrottleStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white38)),
    SizedBox(height: 2.h),
    Text(value, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: color)),
  ]);
}

class _SimStat extends StatelessWidget {
  final String label;
  final String value;
  const _SimStat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.green)),
    Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white38), textAlign: TextAlign.center),
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white)),
      if (subtitle != null) ...[
        SizedBox(width: 8.w),
        Text(subtitle!, style: TextStyle(fontSize: 11.sp, color: Colors.white38)),
      ],
    ],
  );
}

class _MeshStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color  color;
  const _MeshStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(height: 4.h),
        Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white38)),
      ]),
    ),
  );
}

class _DemoActionRow extends StatelessWidget {
  final List<Widget> children;
  const _DemoActionRow({required this.children});

  @override
  Widget build(BuildContext context) => Row(
    children: children.map((c) => Expanded(child: c)).toList(),
  );
}

class _DemoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color  color;
  final VoidCallback? onTap;
  const _DemoBtn({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 3.w),
    child: Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18.sp, color: color),
            SizedBox(height: 3.h),
            Text(label, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600, color: color),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    ),
  );
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
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20.sp, color: color),
      SizedBox(width: 10.w),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: color)),
        SizedBox(height: 4.h),
        Text(body, style: TextStyle(fontSize: 11.sp, color: Colors.white54, height: 1.4)),
      ])),
    ]),
  );
}

// ── Local node identity card ──────────────────────────────────────────────

class _LocalNodeCard extends StatelessWidget {
  final OperationsSummary summary;
  const _LocalNodeCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isRelay = summary.localNodeRelay;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRelay
              ? [Colors.deepPurple.shade900, Colors.deepPurple.shade700]
              : [const Color(0xFF0A3D62), const Color(0xFF1A5276)],
        ),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24.r,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          child: Icon(isRelay ? Icons.cell_tower : Icons.phone_android,
              size: 22.sp, color: Colors.white),
        ),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(summary.localNodeName,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white)),
          SizedBox(height: 2.h),
          Text(isRelay ? 'Role: RELAY NODE' : 'Role: CLIENT NODE',
              style: TextStyle(fontSize: 11.sp, color: Colors.white70)),
          SizedBox(height: 2.h),
          Text(summary.localRoleReason,
              style: TextStyle(fontSize: 10.sp, color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        _RoleBadge(isRelay: isRelay),
      ]),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isRelay;
  const _RoleBadge({required this.isRelay});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
    decoration: BoxDecoration(
      color: (isRelay ? Colors.purple : Colors.blue).withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: isRelay ? Colors.purple : Colors.blue),
    ),
    child: Text(isRelay ? 'RELAY' : 'CLIENT',
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white)),
  );
}

// ── Remote node tile ──────────────────────────────────────────────────────

class _NodeTile extends StatelessWidget {
  final MeshNodeEntry node;
  const _NodeTile({required this.node});

  @override
  Widget build(BuildContext context) {
    final isOnline  = node.isConnected;
    final isRelay   = node.isRelay;
    final signalPct = ((node.signalStrength + 100) / 70).clamp(0.0, 1.0);
    final battColor = node.batteryLevel > 50 ? Colors.green : node.batteryLevel > 25 ? Colors.orange : Colors.red;

    return Material(
      color: const Color(0xFF122033),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: isOnline
            ? () => Navigator.pushNamed(
                  context,
                  Routes.meshChat,
                  arguments: {
                    'peerNodeUuid': node.nodeUuid,
                    'peerName': node.displayName,
                  },
                )
            : null,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isOnline
                ? (isRelay ? Colors.purple : AppColors.primarySurfaceDefault).withValues(alpha: 0.4)
                : Colors.white12),
          ),
          child: Row(children: [
            Stack(children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: (isRelay ? Colors.purple : Colors.blue).withValues(alpha: 0.15),
                child: Icon(isRelay ? Icons.cell_tower : Icons.phone_android,
                    size: 18.sp, color: isRelay ? Colors.purple : Colors.blue),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 10.w, height: 10.w,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF122033), width: 1.5),
                  ),
                ),
              ),
            ]),
            SizedBox(width: 12.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(node.displayName,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.white),
                    overflow: TextOverflow.ellipsis)),
                if (isRelay)
                  _SmallChip('RELAY', Colors.purple),
              ]),
              SizedBox(height: 4.h),
              Row(children: [
                Icon(Icons.signal_cellular_alt, size: 12.sp, color: Colors.white38),
                SizedBox(width: 3.w),
                SizedBox(
                  width: 50.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: signalPct, minHeight: 4.h,
                      backgroundColor: Colors.white12,
                      color: signalPct > 0.5 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Icon(Icons.battery_full, size: 12.sp, color: battColor),
                SizedBox(width: 3.w),
                Text('${node.batteryLevel.round()}%',
                    style: TextStyle(fontSize: 10.sp, color: battColor)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(isOnline ? 'Connected' : 'Offline',
                  style: TextStyle(fontSize: 10.sp, color: isOnline ? Colors.green : Colors.grey)),
              SizedBox(height: 4.h),
              if (isOnline)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chat_bubble_outline, size: 10.sp, color: Colors.teal),
                    SizedBox(width: 3.w),
                    Text('Chat', style: TextStyle(fontSize: 10.sp, color: Colors.teal, fontWeight: FontWeight.w600)),
                  ]),
                )
              else
                Text('${node.signalStrength} dBm',
                    style: TextStyle(fontSize: 10.sp, color: Colors.white38)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Message tile ──────────────────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  final MeshMessageEntry msg;
  final OperationsSnapshot snapshot;
  const _MessageTile({required this.msg, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final hopsLeft = msg.maxHops - msg.hopCount;
    final ttlPct   = 1.0 - (DateTime.now().difference(msg.createdAt).inHours / msg.ttlHours).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF122033),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: msg.isDelivered
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(msg.isDelivered ? Icons.check_circle : Icons.hourglass_top,
              size: 16.sp, color: msg.isDelivered ? Colors.green : Colors.blue),
          SizedBox(width: 8.w),
          Expanded(child: Text(msg.messageType.toUpperCase(),
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white))),
          _SmallChip('${msg.hopCount}/${msg.maxHops} hops',
              hopsLeft > 0 ? Colors.blue : Colors.orange),
        ]),
        SizedBox(height: 6.h),
        Row(children: [
          Text(_shortUuid(msg.senderNodeUuid),
              style: TextStyle(fontSize: 10.sp, color: Colors.white54)),
          Icon(Icons.arrow_forward, size: 11.sp, color: Colors.white38),
          Text(_shortUuid(msg.recipientNodeUuid),
              style: TextStyle(fontSize: 10.sp, color: Colors.white54)),
        ]),
        SizedBox(height: 6.h),
        // TTL bar
        Row(children: [
          Icon(Icons.timer_outlined, size: 11.sp, color: Colors.white38),
          SizedBox(width: 4.w),
          Text('TTL ${msg.ttlHours}h', style: TextStyle(fontSize: 10.sp, color: Colors.white38)),
          SizedBox(width: 8.w),
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: ttlPct, minHeight: 4.h,
              backgroundColor: Colors.white12,
              color: ttlPct > 0.5 ? Colors.green : ttlPct > 0.2 ? Colors.orange : Colors.red,
            ),
          )),
        ]),
      ]),
    );
  }

  static String _shortUuid(String uuid) =>
      uuid.length > 16 ? '${uuid.substring(0, 12)}…' : uuid;
}

// ── Key card ──────────────────────────────────────────────────────────────

class _KeyCard extends StatelessWidget {
  final MeshNodeEntry node;
  final bool isLocal;
  const _KeyCard({required this.node, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    final keySnippet = node.publicKey.length > 24
        ? '${node.publicKey.substring(0, 24)}…'
        : node.publicKey;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: (isLocal ? AppColors.primarySurfaceDefault : Colors.purple).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
            color: (isLocal ? AppColors.primarySurfaceDefault : Colors.purple).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.vpn_key_outlined, size: 16.sp,
            color: isLocal ? AppColors.primarySurfaceDefault : Colors.purple),
        SizedBox(width: 8.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(node.displayName,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white)),
          Text(keySnippet,
              style: TextStyle(fontSize: 10.sp, color: Colors.white38, fontFamily: 'monospace')),
        ])),
        if (isLocal) _SmallChip('LOCAL', AppColors.primarySurfaceDefault),
      ]),
    );
  }
}

// ── Payload inspector ─────────────────────────────────────────────────────

class _PayloadInspector extends StatefulWidget {
  final MeshMessageEntry msg;
  final OperationsSnapshot snapshot;
  const _PayloadInspector({required this.msg, required this.snapshot});

  @override
  State<_PayloadInspector> createState() => _PayloadInspectorState();
}

class _PayloadInspectorState extends State<_PayloadInspector> {
  bool _showEncrypted = true;

  @override
  Widget build(BuildContext context) {
    final encrypted = widget.msg.encryptedPayload;
    final hash      = widget.msg.payloadHash;
    final displayText = _showEncrypted
        ? (encrypted.length > 80 ? '${encrypted.substring(0, 80)}…' : encrypted)
        : hash;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lock, size: 14.sp, color: Colors.green),
          SizedBox(width: 6.w),
          Text('Message — ${widget.msg.messageType}',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.green)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showEncrypted = !_showEncrypted),
            child: _SmallChip(_showEncrypted ? 'Cipher' : 'Hash', Colors.teal),
          ),
        ]),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(displayText,
              style: TextStyle(fontSize: 10.sp, color: Colors.green.shade300, fontFamily: 'monospace')),
        ),
        SizedBox(height: 6.h),
        Row(children: [
          Icon(Icons.info_outline, size: 11.sp, color: Colors.white38),
          SizedBox(width: 4.w),
          Expanded(child: Text(
            'Relay nodes see only ciphertext — cannot read payload contents.',
            style: TextStyle(fontSize: 10.sp, color: Colors.white38),
          )),
        ]),
      ]),
    );
  }
}

// ── Hop tile ──────────────────────────────────────────────────────────────

class _HopTile extends StatelessWidget {
  final MeshRelayHopEntry log;
  final OperationsSnapshot snapshot;
  const _HopTile({required this.log, required this.snapshot});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    decoration: BoxDecoration(
      color: Colors.teal.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Icon(Icons.swap_horiz, size: 14.sp, color: Colors.teal),
      SizedBox(width: 8.w),
      Expanded(child: Text(
        'Relayed via ${snapshot.labelForNode(log.relayNodeUuid)}  ·  ${_timeAgo(log.relayedAt)}',
        style: TextStyle(fontSize: 10.sp, color: Colors.white54),
      )),
    ]),
  );

  static String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}

// ── Empty states ──────────────────────────────────────────────────────────

class _EmptyMesh extends StatelessWidget {
  const _EmptyMesh();

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
    decoration: BoxDecoration(
      color: const Color(0xFF122033),
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(children: [
      SizedBox(
        width: 48.w, height: 48.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.tealAccent.withValues(alpha: 0.7),
        ),
      ),
      SizedBox(height: 16.h),
      Text('Scanning for nearby devices',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white70)),
      SizedBox(height: 6.h),
      Text(
        'Make sure Bluetooth is on.\nOther phones running Digital Delta will appear here automatically.',
        style: TextStyle(fontSize: 11.sp, color: Colors.white38, height: 1.5),
        textAlign: TextAlign.center,
      ),
    ]),
  );
}

class _EmptyQueueCard extends StatelessWidget {
  const _EmptyQueueCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(20.w),
    decoration: BoxDecoration(
      color: const Color(0xFF122033),
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(children: [
      Icon(Icons.inbox, size: 40.sp, color: Colors.white24),
      SizedBox(height: 8.h),
      Text('Queue is empty', style: TextStyle(fontSize: 13.sp, color: Colors.white54)),
      SizedBox(height: 4.h),
      Text('Tap "Queue Msg" to create a store-and-forward relay message.',
          style: TextStyle(fontSize: 11.sp, color: Colors.white38), textAlign: TextAlign.center),
    ]),
  );
}

// ── Small chip ────────────────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _SmallChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20.r),
    ),
    child: Text(label, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: color)),
  );
}
