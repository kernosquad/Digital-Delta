import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/security/rbac.dart';
import '../../../core/security/rbac_provider.dart';
import '../../connectivity/notifier/provider.dart';
import '../../notifier/app_data_notifier.dart';
import '../../theme/color.dart';
import '../../util/routes.dart';

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
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        color: AppColors.primarySurfaceDefault,
        onTapBuilder: (_) => () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Switch to Dashboard tab')),
          );
        },
        // ALL roles have readSupplyData / readRouteData
      ),
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
            () => Navigator.pushNamed(ctx, Routes.meshNetwork),
        // All roles need offline mesh / BLE
      ),
      _Card(
        title: 'Security Setup',
        icon: Icons.shield_outlined,
        color: AppColors.primarySurfaceDefault,
        onTapBuilder: (ctx) => () => Navigator.pushNamed(ctx, Routes.otpSetup),
        // All roles configure their own 2FA
      ),
      _Card(
        title: 'Device Keys',
        icon: Icons.key_rounded,
        color: AppColors.warningSurfaceDefault,
        onTapBuilder: (ctx) =>
            () => Navigator.pushNamed(ctx, Routes.keyProvision),
        // All roles manage their own device keys
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

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guard = ref.watch(rbacGuardProvider);
    final role = ref.watch(currentRoleProvider);
    final connectivity = ref.watch(connectivityNotifierProvider);
    final dataState = ref.watch(appDataNotifierProvider);

    final syncInfo = connectivity.when(
      initial: () => ('Initializing', Colors.grey, Icons.hourglass_empty),
      online: (_) => ('Online', Colors.green, Icons.cloud_done),
      offline: () => ('Offline', Colors.orange, Icons.cloud_off),
    );

    final opCards =
        _operationCards(context).where((c) => c.visibleFor(guard)).toList();
    final toolCards =
        _toolCards(context).where((c) => c.visibleFor(guard)).toList();

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'Digital Delta',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          // Role badge
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
          // Connectivity badge
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeBanner(role: role),
            SizedBox(height: 24.h),

            // Quick stats — live data from AppDataService
            dataState.when(
              loading: () => Row(
                children: [
                  Expanded(
                    child: _QuickStatCard(
                      icon: Icons.local_shipping,
                      value: '…',
                      label: 'Active Vehicles',
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _QuickStatCard(
                      icon: Icons.task_alt,
                      value: '…',
                      label: 'Active Missions',
                      color: AppColors.primarySurfaceDefault,
                    ),
                  ),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  Expanded(
                    child: _QuickStatCard(
                      icon: Icons.local_shipping,
                      value: '?',
                      label: 'Active Vehicles',
                      color: AppColors.secondaryTextDefault,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _QuickStatCard(
                      icon: Icons.task_alt,
                      value: '?',
                      label: 'Active Missions',
                      color: AppColors.secondaryTextDefault,
                    ),
                  ),
                ],
              ),
              data: (snap) => Row(
                children: [
                  Expanded(
                    child: _QuickStatCard(
                      icon: Icons.local_shipping,
                      value: '${snap.activeVehicles}',
                      label: 'Active Vehicles',
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _QuickStatCard(
                      icon: snap.slaBreached > 0
                          ? Icons.warning_amber_rounded
                          : Icons.task_alt,
                      value: '${snap.activeMissions}',
                      label: 'Active Missions',
                      color: snap.slaBreached > 0
                          ? AppColors.dangerSurfaceDefault
                          : AppColors.primarySurfaceDefault,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Operations cards (role-filtered)
            if (opCards.isNotEmpty) ...[
              Text(
                'Operations',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTextDefault,
                ),
              ),
              SizedBox(height: 12.h),
              _CardGrid(cards: opCards),
              SizedBox(height: 24.h),
            ],

            // Tools & settings (role-filtered)
            if (toolCards.isNotEmpty) ...[
              Text(
                'Tools & Settings',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTextDefault,
                ),
              ),
              SizedBox(height: 12.h),
              _CardGrid(cards: toolCards),
            ],
          ],
        ),
      ),
    );
  }

  Color _roleColor(UserRole role) => switch (role) {
        UserRole.fieldVolunteer => Colors.green,
        UserRole.supplyManager => Colors.blue,
        UserRole.droneOperator => Colors.indigo,
        UserRole.campCommander => Colors.orange,
        UserRole.syncAdmin => Colors.red,
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
// Welcome banner
// ---------------------------------------------------------------------------

class _WelcomeBanner extends StatelessWidget {
  final UserRole role;
  const _WelcomeBanner({required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${role.displayName}',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTextDefault,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          _subtitle(role),
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.secondaryTextDefault,
          ),
        ),
      ],
    );
  }

  String _subtitle(UserRole role) => switch (role) {
        UserRole.fieldVolunteer =>
          'Submit deliveries, update location & stay connected offline.',
        UserRole.supplyManager =>
          'Manage inventory, approve deliveries & coordinate routes.',
        UserRole.droneOperator =>
          'Control drones, track airspace & execute last-mile drops.',
        UserRole.campCommander =>
          'Oversee camp resources, triage priorities & fleet dispatch.',
        UserRole.syncAdmin =>
          'Full access — resolve data conflicts, manage sync devices & users.',
      };
}

// ---------------------------------------------------------------------------
// Grid helper
// ---------------------------------------------------------------------------

class _CardGrid extends StatelessWidget {
  final List<_Card> cards;
  const _CardGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.1,
      children: cards
          .map(
            (c) => _FeatureCard(
              title: c.title,
              icon: c.icon,
              color: c.color,
              onTap: c.onTapBuilder(context),
            ),
          )
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable stat + feature-card widgets
// ---------------------------------------------------------------------------

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28.sp, color: Colors.white),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

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
