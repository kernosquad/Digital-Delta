import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../di/cache_module.dart';
import '../../../domain/enum/ble_connection_state.dart';
import '../../../domain/model/ble/ble_device_model.dart';
import '../../../domain/model/operations/operations_snapshot_model.dart';
import '../../connectivity/notifier/provider.dart';
import '../../theme/color.dart';
import '../../util/routes.dart';
import '../../util/toaster.dart';
import '../ble/notifier/provider.dart';
import '../ble/state/ble_ui_state.dart';
import '../dashboard/notifier/provider.dart';
import '../../../data/service/sync_mesh_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Messaging mode — how this device can be reached right now.
// ─────────────────────────────────────────────────────────────────────────────

enum _MsgMode {
  /// BLE-connected, real-time messaging possible.
  direct,

  /// Not connected directly, but an active relay can forward the message
  /// (M3.1 store-and-forward via intermediate BLE-connected relay node).
  viaRelay,

  /// Not reachable by any relay path right now; message will be stored and
  /// delivered once ANY path becomes available (offline queue / future relay).
  stored,

  /// Non-DD device or completely unknown peer; offline messaging not possible.
  unavailable,
}

// ─────────────────────────────────────────────────────────────────────────────
// Immutable display model merging BLE scan data + mesh node data.
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceEntry {
  final String id;
  final String displayName;
  final int rssi;
  final BleDeviceConnectionState connState;
  final bool isDigitalDeltaNode;

  // from mesh node (may be null for non-DD BLE devices)
  final MeshNodeEntry? meshNode;

  // undelivered chat messages queued for this peer
  final int pendingMessages;

  // resolved messaging capability
  final _MsgMode msgMode;

  // if mode == viaRelay, name of the best relay
  final String? relayName;

  const _DeviceEntry({
    required this.id,
    required this.displayName,
    required this.rssi,
    required this.connState,
    required this.isDigitalDeltaNode,
    required this.msgMode,
    this.meshNode,
    this.pendingMessages = 0,
    this.relayName,
  });

  bool get isConnected => connState == BleDeviceConnectionState.connected;
  bool get isBusy =>
      connState == BleDeviceConnectionState.connecting ||
      connState == BleDeviceConnectionState.disconnecting;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: resolve messaging mode for a peer
// ─────────────────────────────────────────────────────────────────────────────

_MsgMode _resolveMsgMode(
  BleDeviceModel bleDevice,
  MeshNodeEntry? meshNode,
  List<MeshNodeEntry> allMeshNodes,
) {
  if (!bleDevice.isDigitalDeltaNode && meshNode == null) {
    return _MsgMode.unavailable;
  }
  if (bleDevice.connectionState == BleDeviceConnectionState.connected ||
      meshNode?.isConnected == true) {
    return _MsgMode.direct;
  }
  // look for a connected relay that can forward
  final hasActiveRelay = allMeshNodes.any(
    (n) => n.isRelay && n.isConnected && n.nodeUuid != meshNode?.nodeUuid,
  );
  return hasActiveRelay ? _MsgMode.viaRelay : _MsgMode.stored;
}

String? _findRelayName(
  MeshNodeEntry? meshNode,
  List<MeshNodeEntry> allMeshNodes,
) {
  for (final n in allMeshNodes) {
    if (n.isRelay && n.isConnected && n.nodeUuid != meshNode?.nodeUuid) {
      return n.displayName;
    }
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class MeshScanScreen extends ConsumerStatefulWidget {
  const MeshScanScreen({super.key});

  @override
  ConsumerState<MeshScanScreen> createState() => _MeshScanScreenState();
}

class _MeshScanScreenState extends ConsumerState<MeshScanScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
      // periodically refresh mesh snapshot so relay/delivery status is live
      _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) ref.read(operationsNotifierProvider.notifier).refresh();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Permissions ─────────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    final denied = statuses.values.any(
      (s) => s.isDenied || s.isPermanentlyDenied,
    );
    if (denied && mounted) {
      Toaster.showWarning(
        context,
        'Bluetooth & Location permissions are required for mesh scanning.',
      );
    }
  }

  // ── Scan toggle ──────────────────────────────────────────────────────────────

  void _toggleScan() {
    final notifier = ref.read(bleNotifierProvider.notifier);
    final isScanning = ref
        .read(bleNotifierProvider)
        .maybeWhen(scanning: (_) => true, orElse: () => false);
    if (isScanning) {
      notifier.stopScan();
    } else {
      notifier.startScan();
    }
  }

  // ── Error listener ───────────────────────────────────────────────────────────

  void _listenBleErrors() {
    ref.listen<BleUiState>(bleNotifierProvider, (_, curr) {
      curr.maybeWhen(
        error: (msg) => Toaster.showError(context, msg),
        orElse: () {},
      );
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _listenBleErrors();

    final bleState = ref.watch(bleNotifierProvider);
    final opsState = ref.watch(operationsNotifierProvider);
    final connectivity = ref.watch(connectivityNotifierProvider);

    final isOffline = connectivity.maybeWhen(
      offline: () => true,
      orElse: () => false,
    );
    final isScanning = bleState.maybeWhen(
      scanning: (_) => true,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'Mesh & Devices',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          _ConnBadge(isOffline: isOffline, isScanning: isScanning),
          SizedBox(width: 12.w),
        ],
      ),
      body: opsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (msg) => Center(child: Text(msg)),
        loaded: (snapshot) => _Body(
          snapshot: snapshot,
          bleState: bleState,
          isScanning: isScanning,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'mesh_scan_fab',
        onPressed: _toggleScan,
        backgroundColor: isScanning
            ? AppColors.dangerSurfaceDefault
            : AppColors.primarySurfaceDefault,
        icon: Icon(
          isScanning ? Icons.stop_rounded : Icons.bluetooth_searching_rounded,
          color: Colors.white,
        ),
        label: Text(
          isScanning ? 'Stop Scan' : 'Scan Nearby',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connectivity badge (top-right appbar)
// ─────────────────────────────────────────────────────────────────────────────

class _ConnBadge extends StatelessWidget {
  final bool isOffline;
  final bool isScanning;
  const _ConnBadge({required this.isOffline, required this.isScanning});

  @override
  Widget build(BuildContext context) {
    final color = isScanning
        ? AppColors.primarySurfaceDefault
        : isOffline
        ? Colors.orange
        : Colors.green;
    final label = isScanning
        ? 'Scanning…'
        : isOffline
        ? 'Mesh Mode'
        : 'Online';
    final icon = isScanning
        ? Icons.bluetooth_searching_rounded
        : isOffline
        ? Icons.bluetooth
        : Icons.cloud_done;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main body — builds merged device entries from BLE + mesh data
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final OperationsSnapshot snapshot;
  final BleUiState bleState;
  final bool isScanning;

  const _Body({
    required this.snapshot,
    required this.bleState,
    required this.isScanning,
  });

  // Build pending chat message count per peer
  Map<String, int> _pendingMsgCounts() {
    final svc = getIt<SyncMeshService>();
    final counts = <String, int>{};
    for (final node in snapshot.nodes) {
      final messages = svc.getChatMessages(node.nodeUuid);
      final pending = messages.where((m) => m.isSent && !m.isDelivered).length;
      if (pending > 0) counts[node.nodeUuid] = pending;
    }
    return counts;
  }

  // Merge BLE devices with mesh node data
  List<_DeviceEntry> _buildEntries(List<BleDeviceModel> bleDevices) {
    final meshByUuid = {for (final n in snapshot.nodes) n.nodeUuid: n};
    // Some BLE device IDs may map to canonical UUIDs via
    // consolidateBleNodeIntoCanonical — try to find by id as well.
    final meshById = <String, MeshNodeEntry>{};
    for (final n in snapshot.nodes) {
      meshById[n.nodeUuid] = n;
    }

    final pendingCounts = _pendingMsgCounts();
    final seenUuids = <String>{};
    final entries = <_DeviceEntry>[];

    // 1. BLE-visible devices (currently in scan results)
    for (final ble in bleDevices) {
      final meshNode = meshByUuid[ble.id] ?? meshById[ble.id];
      final mode = _resolveMsgMode(ble, meshNode, snapshot.nodes);
      final relayName = mode == _MsgMode.viaRelay
          ? _findRelayName(meshNode, snapshot.nodes)
          : null;
      entries.add(
        _DeviceEntry(
          id: ble.id,
          displayName: ble.name.isNotEmpty ? ble.name : 'Unknown Device',
          rssi: ble.rssi,
          connState: ble.connectionState,
          isDigitalDeltaNode: ble.isDigitalDeltaNode,
          meshNode: meshNode,
          pendingMessages:
              pendingCounts[ble.id] ??
              pendingCounts[meshNode?.nodeUuid ?? ''] ??
              0,
          msgMode: mode,
          relayName: relayName,
        ),
      );
      seenUuids.add(ble.id);
      if (meshNode != null) seenUuids.add(meshNode.nodeUuid);
    }

    // 2. Known mesh peers NOT visible in current BLE scan
    //    (they are out-of-range but we have message history or relay can reach them)
    for (final node in snapshot.nodes) {
      if (seenUuids.contains(node.nodeUuid)) continue;
      if (node.nodeUuid == snapshot.summary.localNodeUuid) continue;

      final hasActiveRelay = snapshot.nodes.any(
        (n) => n.isRelay && n.isConnected && n.nodeUuid != node.nodeUuid,
      );
      final mode = node.isConnected
          ? _MsgMode.direct
          : hasActiveRelay
          ? _MsgMode.viaRelay
          : _MsgMode.stored;
      final relayName = mode == _MsgMode.viaRelay
          ? _findRelayName(node, snapshot.nodes)
          : null;

      entries.add(
        _DeviceEntry(
          id: node.nodeUuid,
          displayName: node.displayName,
          rssi: node.signalStrength,
          connState: node.isConnected
              ? BleDeviceConnectionState.connected
              : BleDeviceConnectionState.disconnected,
          isDigitalDeltaNode: true,
          meshNode: node,
          pendingMessages: pendingCounts[node.nodeUuid] ?? 0,
          msgMode: mode,
          relayName: relayName,
        ),
      );
    }

    // Sort: connected first, then relay-reachable, then stored, then unavailable
    entries.sort((a, b) {
      final order = {
        _MsgMode.direct: 0,
        _MsgMode.viaRelay: 1,
        _MsgMode.stored: 2,
        _MsgMode.unavailable: 3,
      };
      final cmp = order[a.msgMode]!.compareTo(order[b.msgMode]!);
      if (cmp != 0) return cmp;
      return b.rssi.compareTo(a.rssi);
    });

    return entries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleDevices = bleState.maybeWhen(
      scanning: (d) => d,
      idle: (d) => d,
      orElse: () => <BleDeviceModel>[],
    );

    final entries = _buildEntries(bleDevices);
    final summary = snapshot.summary;

    return RefreshIndicator(
      onRefresh: ref.read(operationsNotifierProvider.notifier).refresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 120.h),
        children: [
          // Scan progress bar
          if (isScanning)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: LinearProgressIndicator(
                color: AppColors.primarySurfaceDefault,
                backgroundColor: AppColors.primarySurfaceDefault.withValues(
                  alpha: 0.15,
                ),
              ),
            ),

          // ── Local node identity card (M3.2 dual-role) ──────────────────
          _LocalNodeCard(summary: summary),
          SizedBox(height: 14.h),

          // ── Stats row ───────────────────────────────────────────────────
          _StatsRow(
            nearby: summary.nearbyNodes,
            relays: summary.relayCapableNodes,
            queued: summary.queuedMessages,
            conflicts: summary.openConflicts,
          ),
          SizedBox(height: 20.h),

          // ── Devices section ─────────────────────────────────────────────
          _SectionHeader(
            title: 'Devices & Peers',
            trailing: '${entries.length} found',
          ),
          SizedBox(height: 8.h),

          if (entries.isEmpty)
            _EmptyDevices(isScanning: isScanning)
          else
            ...entries.map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _DeviceTile(entry: e),
              ),
            ),

          // ── Message queue summary ───────────────────────────────────────
          if (snapshot.messages.isNotEmpty) ...[
            SizedBox(height: 20.h),
            _SectionHeader(
              title: 'Store-and-Forward Queue',
              trailing: '${summary.queuedMessages} pending',
            ),
            SizedBox(height: 8.h),
            ...snapshot.messages
                .where((m) => !m.isDelivered)
                .take(5)
                .map(
                  (msg) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: _QueuedMessageTile(msg: msg, snapshot: snapshot),
                  ),
                ),
          ],

          // ── Relay hop log ────────────────────────────────────────────────
          if (snapshot.relayLogs.isNotEmpty) ...[
            SizedBox(height: 20.h),
            _SectionHeader(
              title: 'Relay Hop Log',
              trailing: '${snapshot.relayLogs.length} hops',
            ),
            SizedBox(height: 8.h),
            ...snapshot.relayLogs
                .take(5)
                .map(
                  (log) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: _RelayHopTile(log: log, snapshot: snapshot),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTextDefault,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.secondaryTextDefault,
            ),
          ),
      ],
    );
  }
}

// ── Local node card ────────────────────────────────────────────────────────────

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
              ? [Colors.deepPurple.shade700, Colors.deepPurple.shade400]
              : [Colors.teal.shade700, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(
            isRelay ? Icons.cell_tower : Icons.phone_android,
            size: 32.sp,
            color: Colors.white,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.localNodeName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isRelay
                      ? 'RELAY NODE  ·  This Device'
                      : 'CLIENT NODE  ·  This Device',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  summary.localRoleReason,
                  style: TextStyle(fontSize: 10.sp, color: Colors.white60),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              isRelay ? 'Relay' : 'Client',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int nearby;
  final int relays;
  final int queued;
  final int conflicts;
  const _StatsRow({
    required this.nearby,
    required this.relays,
    required this.queued,
    required this.conflicts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(
          icon: Icons.hub,
          value: '$nearby',
          label: 'Nearby',
          color: Colors.teal,
        ),
        SizedBox(width: 8.w),
        _Stat(
          icon: Icons.cell_tower,
          value: '$relays',
          label: 'Relays',
          color: Colors.deepPurple,
        ),
        SizedBox(width: 8.w),
        _Stat(
          icon: Icons.forward_to_inbox,
          value: '$queued',
          label: 'Queued',
          color: Colors.pink,
        ),
        SizedBox(width: 8.w),
        _Stat(
          icon: Icons.warning_amber_rounded,
          value: '$conflicts',
          label: 'Conflicts',
          color: conflicts > 0 ? Colors.orange : Colors.grey,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18.sp, color: color),
            SizedBox(height: 3.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.sp,
                color: AppColors.secondaryTextDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyDevices extends StatelessWidget {
  final bool isScanning;
  const _EmptyDevices({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Icon(
              isScanning
                  ? Icons.bluetooth_searching_rounded
                  : Icons.bluetooth_disabled_rounded,
              size: 56.sp,
              color: isScanning
                  ? AppColors.primarySurfaceDefault
                  : AppColors.secondaryTextDefault,
            ),
            SizedBox(height: 12.h),
            Text(
              isScanning ? 'Scanning for nearby devices…' : 'No devices found',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              isScanning
                  ? 'Digital Delta peers appear automatically'
                  : 'Tap "Scan Nearby" to discover mesh nodes',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.secondaryTextDefault,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Device tile — main combined BLE + mesh node card
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceTile extends ConsumerWidget {
  final _DeviceEntry entry;
  // ignore: unused_element
  const _DeviceTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meshNode = entry.meshNode;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _borderColor,
          width: entry.isConnected ? 1.5 : 0.8,
        ),
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
          // ── Row 1: icon + name + badges + RSSI + connect btn ──
          Row(
            children: [
              // Device icon
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: _iconBgColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(_deviceIcon, color: _iconColor, size: 22.sp),
              ),
              SizedBox(width: 10.w),
              // Name + badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.displayName,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTextDefault,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // DD Node badge
                        if (entry.isDigitalDeltaNode) ...[
                          SizedBox(width: 4.w),
                          _Chip(label: 'DD', color: Colors.deepPurple),
                        ],
                      ],
                    ),
                    SizedBox(height: 3.h),
                    // Relay / Client role + signal
                    Row(
                      children: [
                        if (meshNode != null)
                          _Chip(
                            label: meshNode.isRelay ? 'RELAY' : 'CLIENT',
                            color: meshNode.isRelay
                                ? Colors.deepPurple
                                : Colors.teal,
                          ),
                        if (meshNode != null) SizedBox(width: 6.w),
                        if (entry.rssi != 0)
                          Text(
                            '${entry.rssi} dBm',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.secondaryTextDefault,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // RSSI bars
              if (entry.rssi != 0) ...[
                _RssiBars(rssi: entry.rssi),
                SizedBox(width: 10.w),
              ],
              // Connect / Disconnect button
              _ConnBtn(entry: entry, ref: ref),
            ],
          ),

          // ── Row 2: battery + signal bars (if mesh node known) ──────────
          if (meshNode != null) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _BarRow(
                    label: 'Battery ${meshNode.batteryLevel.toInt()}%',
                    value: meshNode.batteryLevel / 100,
                    color: meshNode.batteryLevel > 30
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _BarRow(
                    label: 'Signal ${_signalLabel(meshNode.signalStrength)}',
                    value:
                        ((meshNode.signalStrength + 100).clamp(0, 100)) / 100,
                    color: _signalColor(meshNode.signalStrength),
                  ),
                ),
              ],
            ),
          ],

          // ── Row 3: offline messaging capability badge ────────────────────
          SizedBox(height: 10.h),
          _OfflineBadge(
            mode: entry.msgMode,
            relayName: entry.relayName,
            proximityMeters: meshNode?.proximityMeters,
          ),

          // ── Row 4: pending messages + message button ─────────────────────
          if (entry.isDigitalDeltaNode) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                if (entry.pendingMessages > 0) ...[
                  Icon(Icons.schedule_send, size: 13.sp, color: Colors.orange),
                  SizedBox(width: 4.w),
                  Text(
                    '${entry.pendingMessages} message${entry.pendingMessages > 1 ? "s" : ""} queued',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),
                // Message button
                SizedBox(
                  height: 32.h,
                  child: OutlinedButton.icon(
                    onPressed: entry.msgMode != _MsgMode.unavailable
                        ? () => Navigator.of(context).pushNamed(
                            Routes.meshChat,
                            arguments: {
                              'peerNodeUuid': entry.id,
                              'peerName': entry.displayName,
                            },
                          )
                        : null,
                    icon: Icon(Icons.chat_bubble_outline, size: 13.sp),
                    label: Text(
                      entry.isConnected
                          ? 'Message'
                          : entry.msgMode == _MsgMode.viaRelay
                          ? 'Message (relay)'
                          : 'Message (stored)',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primarySurfaceDefault,
                      side: BorderSide(
                        color: AppColors.primarySurfaceDefault.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Row 5: E2E encryption notice ─────────────────────────────────
          if (entry.isDigitalDeltaNode && meshNode != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 11.sp,
                  color: AppColors.secondaryTextDefault,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'E2E encrypted — relay nodes cannot read content (M3.3)',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.secondaryTextDefault,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Icon helpers ─────────────────────────────────────────────────────────────

  IconData get _deviceIcon {
    switch (entry.connState) {
      case BleDeviceConnectionState.connected:
        return Icons.bluetooth_connected_rounded;
      case BleDeviceConnectionState.connecting:
      case BleDeviceConnectionState.disconnecting:
        return Icons.bluetooth_searching_rounded;
      case BleDeviceConnectionState.disconnected:
        return entry.isDigitalDeltaNode
            ? Icons.cell_tower
            : Icons.bluetooth_rounded;
    }
  }

  Color get _iconColor {
    switch (entry.msgMode) {
      case _MsgMode.direct:
        return AppColors.primarySurfaceDefault;
      case _MsgMode.viaRelay:
        return Colors.orange;
      case _MsgMode.stored:
        return Colors.amber.shade700;
      case _MsgMode.unavailable:
        return AppColors.secondaryTextDefault;
    }
  }

  Color get _iconBgColor => _iconColor.withValues(alpha: 0.12);

  Color get _borderColor {
    switch (entry.msgMode) {
      case _MsgMode.direct:
        return AppColors.primarySurfaceDefault.withValues(alpha: 0.4);
      case _MsgMode.viaRelay:
        return Colors.orange.withValues(alpha: 0.4);
      case _MsgMode.stored:
        return Colors.amber.withValues(alpha: 0.4);
      case _MsgMode.unavailable:
        return Colors.grey.shade200;
    }
  }

  static String _signalLabel(int rssi) => switch (rssi) {
    >= -55 => 'Excellent',
    >= -70 => 'Good',
    >= -85 => 'Fair',
    _ => 'Weak',
  };

  static Color _signalColor(int rssi) => switch (rssi) {
    >= -55 => Colors.green,
    >= -70 => Colors.lightGreen,
    >= -85 => Colors.orange,
    _ => Colors.red,
  };
}

// ── Offline capability badge ───────────────────────────────────────────────────

class _OfflineBadge extends StatelessWidget {
  final _MsgMode mode;
  final String? relayName;
  final int? proximityMeters;

  const _OfflineBadge({
    required this.mode,
    this.relayName,
    this.proximityMeters,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (mode) {
      _MsgMode.direct => (
        Icons.bluetooth_connected,
        'Direct · BLE Connected',
        Colors.green,
      ),
      _MsgMode.viaRelay => (
        Icons.cell_tower,
        relayName != null
            ? 'Offline · Via ${relayName!} (relay)'
            : 'Offline · Via relay',
        Colors.orange,
      ),
      _MsgMode.stored => (
        Icons.inbox_outlined,
        'Offline · Stored — delivers when in range',
        Colors.amber.shade700,
      ),
      _MsgMode.unavailable => (
        Icons.bluetooth_disabled,
        'Not a mesh node — offline messaging unavailable',
        Colors.grey,
      ),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          if (proximityMeters != null && proximityMeters! > 0)
            Text(
              '~${proximityMeters}m',
              style: TextStyle(
                fontSize: 9.sp,
                color: AppColors.secondaryTextDefault,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Connect button ─────────────────────────────────────────────────────────────

class _ConnBtn extends StatelessWidget {
  final _DeviceEntry entry;
  final WidgetRef ref;
  const _ConnBtn({required this.entry, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (entry.isBusy) {
      return SizedBox(
        width: 18.w,
        height: 18.w,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
      );
    }

    // Out-of-range known peers (not visible in BLE scan) don't show connect button
    if (entry.rssi == 0 && !entry.isConnected) {
      return const SizedBox.shrink();
    }

    if (entry.isConnected) {
      return TextButton(
        onPressed: () =>
            ref.read(bleNotifierProvider.notifier).disconnect(entry.id),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.dangerSurfaceDefault,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Disconnect',
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        ),
      );
    }

    return TextButton(
      onPressed: () => ref.read(bleNotifierProvider.notifier).connect(entry.id),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primarySurfaceDefault,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Connect',
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Small chip badge ───────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5.sp,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── RSSI signal bars ───────────────────────────────────────────────────────────

class _RssiBars extends StatelessWidget {
  final int rssi;
  const _RssiBars({required this.rssi});

  int get _bars {
    if (rssi >= -60) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -80) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < _bars;
        return Container(
          width: 4.w,
          height: (6 + i * 4).h,
          margin: EdgeInsets.only(left: 2.w),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primarySurfaceDefault
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2.r),
          ),
        );
      }),
    );
  }
}

// ── Progress bar row ───────────────────────────────────────────────────────────

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _BarRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.sp,
            color: AppColors.secondaryTextDefault,
          ),
        ),
        SizedBox(height: 3.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(3.r),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 5.h,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ── Queued message tile ────────────────────────────────────────────────────────

class _QueuedMessageTile extends StatelessWidget {
  final MeshMessageEntry msg;
  final OperationsSnapshot snapshot;
  const _QueuedMessageTile({required this.msg, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final remaining = msg.ttlRemaining;
    final ttlLabel = remaining.isNegative
        ? 'Expired'
        : remaining.inHours >= 1
        ? '${remaining.inHours}h left'
        : '${remaining.inMinutes}m left';

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.forward_to_inbox, size: 16.sp, color: Colors.pink),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${snapshot.labelForNode(msg.senderNodeUuid)} → ${snapshot.labelForNode(msg.recipientNodeUuid)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
                Text(
                  '${msg.messageType}  ·  ${msg.hopCount}/${msg.maxHops} hops  ·  TTL: $ttlLabel',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
                Text(
                  msg.payloadPreview,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontFamily: 'monospace',
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Relay hop tile ─────────────────────────────────────────────────────────────

class _RelayHopTile extends StatelessWidget {
  final MeshRelayHopEntry log;
  final OperationsSnapshot snapshot;
  const _RelayHopTile({required this.log, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.swap_horiz, size: 14.sp, color: Colors.teal),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Relayed via ${snapshot.labelForNode(log.relayNodeUuid)}  ·  '
              '${_formatTime(log.relayedAt)}',
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.secondaryTextDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}
