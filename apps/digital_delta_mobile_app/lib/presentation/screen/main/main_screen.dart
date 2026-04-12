import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../connectivity/notifier/provider.dart';
import '../../notifier/app_data_notifier.dart';
import '../../theme/color.dart';
import '../dashboard/dashboard_screen.dart';
import '../fleet/fleet_screen.dart';
import '../home/home_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';

// ---------------------------------------------------------------------------
// MainScreen — 5-tab shell with connectivity-triggered data sync
// Tabs: Home | CRDT Sync | Map | Fleet | Mesh
// ---------------------------------------------------------------------------

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    DashboardScreen(),
    MapScreen(),
    FleetScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Whenever the device goes from offline → online, invalidate caches and
    // pull fresh data so all screens reflect the latest server state.
    ref.listenManual(connectivityNotifierProvider, (prev, next) {
      bool wasOnline = false;
      bool isNowOnline = false;
      prev?.when(
        initial: () {},
        online: (_) => wasOnline = true,
        offline: () {},
      );
      next.when(
        initial: () {},
        online: (_) => isNowOnline = true,
        offline: () {},
      );
      if (isNowOnline && !wasOnline) {
        ref.read(appDataNotifierProvider.notifier).syncAndRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primarySurfaceDefault.withValues(alpha: 0.1),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 24.sp),
            selectedIcon: Icon(
              Icons.home,
              size: 24.sp,
              color: AppColors.primarySurfaceDefault,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_outlined, size: 24.sp),
            selectedIcon: Icon(
              Icons.sync,
              size: 24.sp,
              color: AppColors.primarySurfaceDefault,
            ),
            label: 'Sync',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined, size: 24.sp),
            selectedIcon: Icon(
              Icons.map,
              size: 24.sp,
              color: AppColors.primarySurfaceDefault,
            ),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined, size: 24.sp),
            selectedIcon: Icon(
              Icons.local_shipping,
              size: 24.sp,
              color: AppColors.primarySurfaceDefault,
            ),
            label: 'Fleet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 24.sp),
            selectedIcon: Icon(
              Icons.person,
              size: 24.sp,
              color: AppColors.primarySurfaceDefault,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
