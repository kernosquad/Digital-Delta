import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color.dart';
import '../cargo/cargo_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../fleet/fleet_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DashboardScreen(),
    FleetScreen(),
    CargoScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
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
            icon: Icon(Icons.dashboard_outlined, size: 24.sp),
            selectedIcon: Icon(
              Icons.dashboard,
              size: 24.sp,
              color: AppColors.primarySurfaceDefault,
            ),
            label: 'Dashboard',
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
            icon: Icon(Icons.inventory_2_outlined, size: 24.sp),
            selectedIcon: Icon(
              Icons.inventory_2,
              size: 24.sp,
              color: AppColors.primarySurfaceDefault,
            ),
            label: 'Cargo',
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
