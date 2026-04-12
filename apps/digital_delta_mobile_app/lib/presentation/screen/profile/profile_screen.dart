import 'package:digital_delta/presentation/screen/auth/state/auth_ui_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/security/rbac.dart';
import '../../../core/security/rbac_provider.dart';
import '../../common/widget/custom_button.dart';
import '../../common/widget/role_gate.dart';
import '../../theme/color.dart';
import '../../util/routes.dart';
import '../auth/notifier/provider.dart';
import '../auth/notifier/user_profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(refreshableUserProfileProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final userProfileAsync = ref.watch(refreshableUserProfileProvider);
    final userProfileNotifier = ref.read(
      refreshableUserProfileProvider.notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: userProfileAsync.isLoading
                ? null
                : () {
                    userProfileNotifier.refresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshing profile...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No user data found',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.secondaryTextDefault,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.login,
                      (route) => false,
                    ),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => await userProfileNotifier.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primarySurfaceDefault,
                          AppColors.primarySurfaceDefault.withValues(
                            alpha: 0.8,
                          ),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primarySurfaceDefault.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40.r,
                          backgroundColor: Colors.white,
                          backgroundImage: user.avatar != null
                              ? NetworkImage(user.avatar!)
                              : null,
                          child: user.avatar == null
                              ? Icon(
                                  Icons.person,
                                  size: 48.sp,
                                  color: AppColors.primarySurfaceDefault,
                                )
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        if (user.phone != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            user.phone!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            _formatRole(user.role),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTextDefault,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _ProfileMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Security Setup',
                    subtitle: 'Set up your login verification code',
                    onTap: () => Navigator.pushNamed(context, Routes.otpSetup),
                  ),
                  SizedBox(height: 8.h),
                  _ProfileMenuItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Verify Security Code',
                    subtitle: 'Confirm your verification code works',
                    onTap: () => Navigator.pushNamed(context, Routes.otpVerify),
                  ),
                  SizedBox(height: 8.h),
                  _ProfileMenuItem(
                    icon: Icons.key_outlined,
                    title: 'Device Keys',
                    subtitle: 'Manage your device security keys',
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.keyProvision),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTextDefault,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _ProfileMenuItem(
                    icon: Icons.bluetooth_outlined,
                    title: 'Nearby Devices',
                    subtitle: 'Find and connect to nearby devices',
                    onTap: () => Navigator.pushNamed(context, Routes.ble),
                  ),
                  SizedBox(height: 8.h),
                  _ProfileMenuItem(
                    icon: Icons.sync_outlined,
                    title: 'Offline Sync',
                    subtitle: 'View data sync status when offline',
                    onTap: () {},
                  ),
                  SizedBox(height: 8.h),
                  _ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () {},
                  ),
                  SizedBox(height: 8.h),
                  _ProfileMenuItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {},
                  ),

                  // ── Audit Logs (camp_commander + sync_admin) ──────────────
                  RoleGate(
                    permission: Permission.readAuditLogs,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h),
                        Text(
                          'Audit & Compliance',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTextDefault,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _ProfileMenuItem(
                          icon: Icons.history_outlined,
                          title: 'Audit Logs',
                          subtitle: 'View immutable hash-chained event log',
                          onTap: () {},
                        ),
                        SizedBox(height: 8.h),
                        RoleGate(
                          permission: Permission.triagePriority,
                          child: _ProfileMenuItem(
                            icon: Icons.medical_services_outlined,
                            title: 'Triage Control',
                            subtitle: 'Manage P0–P3 SLA priority decisions',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Sync Admin section (sync_admin only) ─────────────────
                  RoleGate.any(
                    permissions: [
                      Permission.resolveCRDTConflicts,
                      Permission.manageSyncNodes,
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h),
                        Text(
                          'Sync Administration',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTextDefault,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _ProfileMenuItem(
                          icon: Icons.merge_type_outlined,
                          title: 'CRDT Conflicts',
                          subtitle: 'Resolve pending vector-clock conflicts',
                          onTap: () {},
                        ),
                        SizedBox(height: 8.h),
                        _ProfileMenuItem(
                          icon: Icons.device_hub_outlined,
                          title: 'Sync Nodes',
                          subtitle: 'Manage mesh synchronisation topology',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  // ── User Management (sync_admin only) ────────────────────
                  RoleGate(
                    permission: Permission.manageUsers,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h),
                        Text(
                          'User Management',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTextDefault,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _ProfileMenuItem(
                          icon: Icons.group_outlined,
                          title: 'All Users',
                          subtitle: 'View, suspend or activate accounts',
                          onTap: () {},
                        ),
                        SizedBox(height: 8.h),
                        RoleGate(
                          permission: Permission.manageRoles,
                          child: _ProfileMenuItem(
                            icon: Icons.manage_accounts_outlined,
                            title: 'Role Assignment',
                            subtitle: 'Change user roles & permissions',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),
                  CustomButton(
                    onPressed: authState is AuthLoadingState
                        ? null
                        : () async {
                            await authNotifier.logout();
                            if (context.mounted)
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                Routes.login,
                                (route) => false,
                              );
                          },
                    label: authState is AuthLoadingState
                        ? 'Logging out...'
                        : 'Logout',
                    backgroundColor: Colors.redAccent,
                    isLoading: authState is AuthLoadingState,
                  ),
                  SizedBox(height: 16.h),
                  Center(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.secondaryTextDefault,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text(
                'Loading profile...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                'Failed to load profile',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTextDefault,
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () => userProfileNotifier.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRole(String? role) {
    if (role == null || role.isEmpty) return 'Field Volunteer';
    return role
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primarySurfaceDefault.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: AppColors.primarySurfaceDefault,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextDefault,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.secondaryTextDefault,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.secondaryTextDefault,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
