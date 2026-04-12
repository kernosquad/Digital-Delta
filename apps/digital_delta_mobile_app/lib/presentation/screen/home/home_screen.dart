import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../connectivity/notifier/provider.dart';
import '../../theme/color.dart';
import '../../util/routes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityNotifierProvider);
    final syncInfo = connectivity.when(
      initial: () => ('Initializing', Colors.grey, Icons.hourglass_empty),
      online: (_) => ('Online', Colors.green, Icons.cloud_done),
      offline: () => ('Offline', Colors.orange, Icons.cloud_off),
    );

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'Digital Delta',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
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
            // Welcome Section
            Text(
              'Welcome to Digital Delta',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Resilient Logistics & Disaster Response System',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.secondaryTextDefault,
              ),
            ),
            SizedBox(height: 24.h),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.local_shipping,
                    value: '24',
                    label: 'Active Vehicles',
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.inventory_2,
                    value: '156',
                    label: 'Deliveries',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Main Features
            Text(
              'Operations',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 12.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.1,
              children: [
                _FeatureCard(
                  title: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to dashboard tab in main screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Switch to Dashboard tab')),
                    );
                  },
                ),
                _FeatureCard(
                  title: 'Fleet',
                  icon: Icons.local_shipping_outlined,
                  color: Colors.green,
                  onTap: () {},
                ),
                _FeatureCard(
                  title: 'Cargo',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.orange,
                  onTap: () {},
                ),
                _FeatureCard(
                  title: 'PoD Scanner',
                  icon: Icons.qr_code_scanner,
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(context, Routes.podScanner),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Tools & Settings
            Text(
              'Tools & Settings',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 12.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.1,
              children: [
                _FeatureCard(
                  title: 'Mesh & BLE',
                  icon: Icons.hub_rounded,
                  color: Colors.indigo,
                  onTap: () => Navigator.pushNamed(context, Routes.meshNetwork),
                ),
                _FeatureCard(
                  title: 'OTP Setup',
                  icon: Icons.shield_outlined,
                  color: Colors.teal,
                  onTap: () => Navigator.pushNamed(context, Routes.otpSetup),
                ),
                _FeatureCard(
                  title: 'Key Provision',
                  icon: Icons.key_rounded,
                  color: Colors.deepOrange,
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.keyProvision),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
