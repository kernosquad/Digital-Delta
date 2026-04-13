// Module 2/3 — MeshCore Contacts Screen
//
// Shows all contacts/nodes discovered on the connected MeshCore mesh.
// Each node displays its type (Chat / Repeater / Room / Sensor),
// hop count, last seen time, and unread message badge.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/meshcore/meshcore_models.dart';
import '../../../core/meshcore/meshcore_protocol.dart';
import '../../theme/color.dart';
import '../../util/routes.dart';
import 'providers.dart';

class MeshCoreContactsScreen extends ConsumerStatefulWidget {
  const MeshCoreContactsScreen({super.key});

  @override
  ConsumerState<MeshCoreContactsScreen> createState() =>
      _MeshCoreContactsScreenState();
}

class _MeshCoreContactsScreenState
    extends ConsumerState<MeshCoreContactsScreen> {
  // Local snapshot of contacts, updated when contacts stream fires
  List<MeshCoreContact> _contacts = [];
  StreamSubscription<List<MeshCoreContact>>? _sub;

  @override
  void initState() {
    super.initState();
    // Seed from service immediately
    final svc = ref.read(meshCoreBleServiceProvider);
    _contacts = svc.contacts;

    // Listen for updates
    _sub = svc.contactsStream.listen((contacts) {
      if (mounted) setState(() => _contacts = contacts);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(meshCoreBleServiceProvider).refreshContacts();
  }

  @override
  Widget build(BuildContext context) {
    final connState =
        ref.watch(meshCoreConnectionStateProvider).valueOrNull ??
        MeshCoreConnectionState.disconnected;
    final deviceInfo = ref.watch(meshCoreDeviceInfoProvider).valueOrNull;

    final isConnected = connState == MeshCoreConnectionState.connected;

    final chatNodes = _contacts.where((c) => c.type == advTypeChat).toList();
    final repeaters = _contacts
        .where((c) => c.type == advTypeRepeater)
        .toList();
    final others = _contacts
        .where((c) => c.type != advTypeChat && c.type != advTypeRepeater)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryTextDefault,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mesh Network',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            if (deviceInfo != null)
              Text(
                deviceInfo.deviceName,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_tree_outlined,
              color: AppColors.primarySurfaceDefault,
            ),
            tooltip: 'Node Graph',
            onPressed: () =>
                Navigator.pushNamed(context, Routes.meshcoreNodeGraph),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status bar ────────────────────────────────────────────────
          _StatusBar(
            isConnected: isConnected,
            deviceInfo: deviceInfo,
            totalNodes: _contacts.length,
            onScan: () => Navigator.pushNamed(context, Routes.meshcoreScanner),
          ),

          // ── Contacts list ─────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primarySurfaceDefault,
              onRefresh: _refresh,
              child: _contacts.isEmpty
                  ? _EmptyContacts(isConnected: isConnected)
                  : CustomScrollView(
                      slivers: [
                        if (chatNodes.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Chat Nodes',
                            count: chatNodes.length,
                            color: AppColors.primarySurfaceDefault,
                          ),
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _ContactTile(
                                  contact: chatNodes[i],
                                  onTap: () => _openChat(chatNodes[i]),
                                ),
                                childCount: chatNodes.length,
                              ),
                            ),
                          ),
                        ],
                        if (repeaters.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Repeaters',
                            count: repeaters.length,
                            color: AppColors.nodeDroneBase,
                          ),
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _ContactTile(
                                  contact: repeaters[i],
                                  onTap: () {},
                                ),
                                childCount: repeaters.length,
                              ),
                            ),
                          ),
                        ],
                        if (others.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Other Nodes',
                            count: others.length,
                            color: AppColors.secondaryTextDefault,
                          ),
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _ContactTile(
                                  contact: others[i],
                                  onTap: () {},
                                ),
                                childCount: others.length,
                              ),
                            ),
                          ),
                        ],
                        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(MeshCoreContact contact) {
    Navigator.pushNamed(
      context,
      Routes.meshcoreChat,
      arguments: {
        'contactKeyHex': contact.publicKeyHex,
        'contactName': contact.name,
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final bool isConnected;
  final MeshCoreDeviceInfo? deviceInfo;
  final int totalNodes;
  final VoidCallback onScan;

  const _StatusBar({
    required this.isConnected,
    required this.deviceInfo,
    required this.totalNodes,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected
                  ? AppColors.statusOnline
                  : AppColors.dangerSurfaceDefault,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              isConnected
                  ? '${deviceInfo?.selfName.isEmpty == false ? deviceInfo!.selfName : deviceInfo?.deviceName ?? 'Connected'} — $totalNodes nodes'
                  : 'Not connected',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.secondaryTextDefault,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (deviceInfo?.batteryMv != null)
            _BatteryChip(percent: deviceInfo!.batteryPercent),
          SizedBox(width: 8.w),
          if (!isConnected)
            OutlinedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.bluetooth_searching, size: 14),
              label: Text('Scan', style: TextStyle(fontSize: 11.sp)),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, 28.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
                side: const BorderSide(color: AppColors.primarySurfaceDefault),
                foregroundColor: AppColors.primarySurfaceDefault,
              ),
            ),
        ],
      ),
    );
  }
}

class _BatteryChip extends StatelessWidget {
  final int percent;

  const _BatteryChip({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent > 40
        ? AppColors.primarySurfaceDefault
        : percent > 20
        ? AppColors.warningSurfaceDefault
        : AppColors.dangerSurfaceDefault;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.battery_full, size: 12.sp, color: color),
          SizedBox(width: 2.w),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 6.h),
        child: Row(
          children: [
            Container(
              width: 3.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final MeshCoreContact contact;
  final VoidCallback onTap;

  const _ContactTile({required this.contact, required this.onTap});

  Color _typeColor() {
    switch (contact.type) {
      case advTypeRepeater:
        return AppColors.nodeDroneBase;
      case advTypeRoom:
        return AppColors.roleSupplyMgr;
      case advTypeSensor:
        return AppColors.warningSurfaceDefault;
      default:
        return AppColors.primarySurfaceDefault;
    }
  }

  IconData _typeIcon() {
    switch (contact.type) {
      case advTypeRepeater:
        return Icons.cell_tower;
      case advTypeRoom:
        return Icons.meeting_room_outlined;
      case advTypeSensor:
        return Icons.sensors;
      default:
        return Icons.person_outline;
    }
  }

  String _lastSeenLabel() {
    final diff = DateTime.now().difference(contact.lastSeen);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: ListTile(
        onTap: contact.isChatNode ? onTap : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        leading: Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(_typeIcon(), color: color, size: 20.sp),
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextDefault,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 3.h),
          child: Row(
            children: [
              _PillLabel(label: contact.typeLabel, color: color),
              SizedBox(width: 6.w),
              _PillLabel(
                label: contact.hopLabel,
                color: contact.pathLength == 0
                    ? AppColors.primarySurfaceDefault
                    : AppColors.secondaryTextDefault,
              ),
              SizedBox(width: 6.w),
              Text(
                _lastSeenLabel(),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
            ],
          ),
        ),
        trailing: contact.isChatNode
            ? Icon(
                Icons.chevron_right,
                color: AppColors.secondaryTextDefault,
                size: 18.sp,
              )
            : null,
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _PillLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyContacts extends StatelessWidget {
  final bool isConnected;

  const _EmptyContacts({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_outlined, size: 64.sp, color: AppColors.borderDefault),
          SizedBox(height: 16.h),
          Text(
            isConnected
                ? 'No mesh nodes discovered yet.\nPull down to refresh.'
                : 'Not connected to a MeshCore radio.\nGo back and connect.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.secondaryTextDefault,
            ),
          ),
        ],
      ),
    );
  }
}
