import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/security/rbac.dart';
import '../../../core/security/rbac_provider.dart';
import '../../connectivity/notifier/provider.dart';
import '../../notifier/app_data_notifier.dart';
import '../../theme/color.dart';
import '../../util/routes.dart';
import '../main/main_shell_tab_provider.dart';

// ---------------------------------------------------------------------------
// Feature-card descriptor
// ---------------------------------------------------------------------------

class _Card {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback Function(BuildContext context) onTapBuilder;
  final Permission? permission;
  final List<Permission>? anyPermissions;

  const _Card({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTapBuilder,
    this.permission,
    this.anyPermissions,
  });

  bool visibleFor(RBACGuard guard) {
    if (permission != null) return guard.can(permission!);
    if (anyPermissions != null) return guard.canAny(anyPermissions!);
    return true;
  }
}

// ---------------------------------------------------------------------------
// Card definitions
// ---------------------------------------------------------------------------

List<_Card> _operationCards(BuildContext context) => [
  _Card(
    title: 'Fleet',
    icon: Icons.local_shipping_outlined,
    color: const Color(0xFF1565C0),
    onTapBuilder: (ctx) =>
        () => Navigator.pushNamed(ctx, Routes.droneDispatch),
    anyPermissions: [Permission.controlDrones, Permission.executeDelivery],
  ),
  _Card(
    title: 'Cargo',
    icon: Icons.inventory_2_outlined,
    color: AppColors.warningSurfaceDefault,
    onTapBuilder: (_) => () {},
    permission: Permission.manageInventory,
  ),
  _Card(
    title: 'Delivery Scan',
    icon: Icons.qr_code_scanner,
    color: AppColors.primarySurfaceDark,
    onTapBuilder: (ctx) =>
        () => Navigator.pushNamed(ctx, Routes.podScanner),
    permission: Permission.submitProofOfDelivery,
  ),
];

List<_Card> _toolCards(BuildContext context) => [
  _Card(
    title: 'Nearby Devices',
    icon: Icons.hub_rounded,
    color: const Color(0xFF37474F),
    onTapBuilder: (ctx) =>
        () => Navigator.pushNamed(ctx, Routes.nearbyDevices),
  ),
  _Card(
    title: 'Data Sync',
    icon: Icons.sync_problem_outlined,
    color: AppColors.dangerSurfaceDefault,
    onTapBuilder: (_) => () {},
    anyPermissions: [
      Permission.resolveCRDTConflicts,
      Permission.manageSyncNodes,
    ],
  ),
];

String _relativeRefreshLabel(DateTime? at) {
  if (at == null) return 'Local snapshot';
  final d = DateTime.now().difference(at);
  if (d.inSeconds < 45) return 'Updated just now';
  if (d.inMinutes < 60) return 'Updated ${d.inMinutes}m ago';
  if (d.inHours < 24) return 'Updated ${d.inHours}h ago';
  return 'Updated ${d.inDays}d ago';
}

// ---------------------------------------------------------------------------
// HomeScreen — operations dashboard (API-backed when online, cache offline)
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _onPullRefresh(WidgetRef ref) async {
    final online = ref
        .read(connectivityNotifierProvider)
        .maybeWhen(online: (_) => true, orElse: () => false);
    if (online) {
      await ref.read(appDataNotifierProvider.notifier).syncAndRefresh();
    } else {
      await ref.read(appDataNotifierProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guard = ref.watch(rbacGuardProvider);
    final role = ref.watch(currentRoleProvider);
    final connectivity = ref.watch(connectivityNotifierProvider);
    final dataState = ref.watch(appDataNotifierProvider);

    final isOnline = connectivity.maybeWhen(
      online: (_) => true,
      orElse: () => false,
    );

    final syncInfo = connectivity.when(
      initial: () =>
          ('Initializing', AppColors.statusIdle, Icons.hourglass_empty),
      online: (_) => ('Online', AppColors.statusOnline, Icons.cloud_done),
      offline: () => ('Offline', AppColors.statusPending, Icons.cloud_off),
    );

    final opCards = _operationCards(
      context,
    ).where((c) => c.visibleFor(guard)).toList();
    final toolCards = _toolCards(
      context,
    ).where((c) => c.visibleFor(guard)).toList();

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Image.asset(
            'assets/logo/digital_delta_logo.png',
            width: 32.w,
            height: 32.h,
          ),
        ),
        title: Text(
          'Operations',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _roleColor(role).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(_roleIcon(role), size: 13.sp, color: _roleColor(role)),
                SizedBox(width: 4.w),
                Text(
                  role.displayName,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: _roleColor(role),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: syncInfo.$2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(syncInfo.$3, size: 14.sp, color: syncInfo.$2),
                SizedBox(width: 4.w),
                Text(
                  syncInfo.$1,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: syncInfo.$2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primarySurfaceDefault,
        onRefresh: () => _onPullRefresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroHeader(role: role, isOnline: isOnline),
                    if (!isOnline) ...[
                      SizedBox(height: 12.h),
                      _OfflineBanner(),
                    ],
                    SizedBox(height: 16.h),
                    dataState.when(
                      loading: () => _MetricsLoadingGrid(),
                      error: (_, __) => _MetricsErrorStrip(
                        onRetry: () => ref
                            .read(appDataNotifierProvider.notifier)
                            .refresh(),
                      ),
                      data: (snap) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14.sp,
                                color: AppColors.secondaryTextDefault,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  _relativeRefreshLabel(snap.dataRefreshedAt),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.secondaryTextDefault,
                                  ),
                                ),
                              ),
                              if (isOnline)
                                Text(
                                  'Live sync',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.statusOnline,
                                  ),
                                )
                              else
                                Text(
                                  'Cached',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.statusPending,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          _MetricsGrid(snap: snap),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Quick access',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTextDefault,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _QuickAccessRow(
                      onMap: () =>
                          ref.read(mainShellTabProvider.notifier).state = 2,
                      onFleet: () =>
                          ref.read(mainShellTabProvider.notifier).state = 3,
                      onSync: () =>
                          ref.read(mainShellTabProvider.notifier).state = 1,
                    ),
                    SizedBox(height: 20.h),
                    _DonationBanner(
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.donation),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            if (opCards.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Operations',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTextDefault,
                    ),
                  ),
                ),
              ),
            if (opCards.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final c = opCards[i];
                    return _FeatureCard(
                      title: c.title,
                      icon: c.icon,
                      color: c.color,
                      onTap: c.onTapBuilder(context),
                    );
                  }, childCount: opCards.length),
                ),
              ),
            if (toolCards.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: Text(
                    'Tools & settings',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTextDefault,
                    ),
                  ),
                ),
              ),
            if (toolCards.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final c = toolCards[i];
                    return _FeatureCard(
                      title: c.title,
                      icon: c.icon,
                      color: c.color,
                      onTap: c.onTapBuilder(context),
                    );
                  }, childCount: toolCards.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(UserRole role) => switch (role) {
    UserRole.fieldVolunteer => AppColors.roleVolunteer,
    UserRole.supplyManager => AppColors.roleSupplyMgr,
    UserRole.droneOperator => AppColors.roleDroneOp,
    UserRole.campCommander => AppColors.roleCommander,
    UserRole.syncAdmin => AppColors.roleSyncAdmin,
  };

  IconData _roleIcon(UserRole role) => switch (role) {
    UserRole.fieldVolunteer => Icons.person_pin_outlined,
    UserRole.supplyManager => Icons.inventory_2_outlined,
    UserRole.droneOperator => Icons.air_outlined,
    UserRole.campCommander => Icons.campaign_outlined,
    UserRole.syncAdmin => Icons.admin_panel_settings_outlined,
  };
}

// ---------------------------------------------------------------------------
// Hero + offline
// ---------------------------------------------------------------------------

class _HeroHeader extends StatelessWidget {
  final UserRole role;
  final bool isOnline;

  const _HeroHeader({required this.role, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primarySurfaceDefault,
            AppColors.primarySurfaceDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primarySurfaceDefault.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                color: Colors.white.withValues(alpha: 0.95),
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Mission dashboard',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOnline ? Icons.cloud_done : Icons.cloud_off,
                      size: 14.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      isOnline ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Welcome, ${role.displayName}',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _subtitle(role),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(UserRole role) => switch (role) {
    UserRole.fieldVolunteer =>
      'Track missions and fleet from one place. Data stays available offline, then syncs when you reconnect.',
    UserRole.supplyManager =>
      'Inventory, routes, and deliveries — online for live DB sync, offline from your last snapshot.',
    UserRole.droneOperator =>
      'Fleet status and airspace context update from the API when online.',
    UserRole.campCommander =>
      'Camp-wide overview with flood and SLA signals from the operations database.',
    UserRole.syncAdmin =>
      'Full visibility — CRDT mesh sync and REST data reconcile when the device is online.',
  };
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.warningSurfaceDefault.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.warningSurfaceDefault.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 20.sp,
            color: AppColors.warningSurfaceDefault,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Working offline',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Showing cached dashboard, fleet, and map data. Pull down to refresh from the local cache; reconnect to sync with the server.',
                  style: TextStyle(
                    fontSize: 11.sp,
                    height: 1.35,
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

// ---------------------------------------------------------------------------
// Metrics
// ---------------------------------------------------------------------------

class _MetricsLoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _loadingTile()),
            SizedBox(width: 10.w),
            Expanded(child: _loadingTile()),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(child: _loadingTile()),
            SizedBox(width: 10.w),
            Expanded(child: _loadingTile()),
          ],
        ),
      ],
    );
  }

  Widget _loadingTile() => Container(
    height: 88.h,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: AppColors.borderDefault),
    ),
    child: const Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class _MetricsErrorStrip extends StatelessWidget {
  final VoidCallback onRetry;

  const _MetricsErrorStrip({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.dangerSurfaceTint,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.dangerSurfaceDefault.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.dangerSurfaceDefault,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Could not load dashboard metrics. Pull to retry or check your connection.',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primaryTextDefault,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final AppDataSnapshot snap;

  const _MetricsGrid({required this.snap});

  @override
  Widget build(BuildContext context) {
    final missionWarn = snap.slaBreached > 0;
    final stockWarn = snap.criticalLowStock > 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.task_alt_rounded,
                value: '${snap.activeMissions}',
                label: 'Active missions',
                color: missionWarn
                    ? AppColors.dangerSurfaceDefault
                    : AppColors.primarySurfaceDefault,
                accentIcon: missionWarn ? Icons.warning_amber_rounded : null,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetricTile(
                icon: Icons.local_shipping_outlined,
                value: '${snap.activeVehicles}/${snap.totalVehicles}',
                label: 'Fleet in mission',
                color: const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.inventory_2_outlined,
                value: '${snap.criticalLowStock}',
                label: 'Critical stock',
                color: stockWarn
                    ? AppColors.warningSurfaceDefault
                    : AppColors.statusOnline,
                accentIcon: stockWarn ? Icons.priority_high : null,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetricTile(
                icon: Icons.timer_off_outlined,
                value: '${snap.slaBreached}',
                label: 'SLA breach',
                color: missionWarn
                    ? AppColors.dangerSurfaceDefault
                    : AppColors.statusIdle,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.hub_outlined,
                value: '${snap.meshPending}',
                label: 'Mesh queue',
                color: AppColors.nodeCommand,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetricTile(
                icon: Icons.shield_moon_outlined,
                value: '${snap.triage24h}',
                label: 'Triage 24h',
                color: AppColors.priorityP2,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.water_damage_outlined,
                value: '${snap.floodedLocations}',
                label: 'Flooded nodes',
                color: snap.floodedLocations > 0
                    ? AppColors.dangerSurfaceDefault
                    : AppColors.statusOnline,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetricTile(
                icon: Icons.route_outlined,
                value: '${snap.idleVehicles}',
                label: 'Fleet idle',
                color: AppColors.secondaryTextDefault,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final IconData? accentIcon;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.accentIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault),
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
              Icon(icon, size: 18.sp, color: color),
              if (accentIcon != null) ...[
                SizedBox(width: 4.w),
                Icon(accentIcon, size: 16.sp, color: color),
              ],
              const Spacer(),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryTextDefault,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.secondaryTextDefault,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick access
// ---------------------------------------------------------------------------

class _QuickAccessRow extends StatelessWidget {
  final VoidCallback onMap;
  final VoidCallback onFleet;
  final VoidCallback onSync;

  const _QuickAccessRow({
    required this.onMap,
    required this.onFleet,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickChip(
            icon: Icons.map_outlined,
            label: 'Map',
            color: AppColors.primarySurfaceDefault,
            onTap: onMap,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _QuickChip(
            icon: Icons.local_shipping_outlined,
            label: 'Fleet',
            color: const Color(0xFF1565C0),
            onTap: onFleet,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _QuickChip(
            icon: Icons.sync_alt,
            label: 'Sync',
            color: AppColors.nodeDroneBase,
            onTap: onSync,
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26.sp),
              SizedBox(height: 6.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------// Donation banner
// ---------------------------------------------------------------------------

class _DonationBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _DonationBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0288D1).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Decorative circle
            Positioned(
              right: -18,
              top: -18,
              child: Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.volunteer_activism,
                      size: 28.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Support Relief Missions',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Donate to flood, medical & shelter relief — secured by EPS.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Donate',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------// Feature cards (grid)
// ---------------------------------------------------------------------------

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 32.sp, color: color),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTextDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
