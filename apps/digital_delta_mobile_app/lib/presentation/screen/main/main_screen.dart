import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/security/rbac.dart';
import '../../../core/security/rbac_provider.dart';
import '../../theme/color.dart';
import '../dashboard/dashboard_screen.dart';
import '../fleet/drone_dispatch_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../routing/routing_screen.dart';

// ---------------------------------------------------------------------------
// Nav-item descriptor
// ---------------------------------------------------------------------------

class _NavItem {
  final Widget screen;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem({
    required this.screen,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

// ---------------------------------------------------------------------------
// Role → visible tabs
// ---------------------------------------------------------------------------

/// Returns the ordered list of nav items the [role] is allowed to see.
///
/// Access rules (align with [_rolePermissions] in rbac.dart):
///
/// | Tab        | field_volunteer | supply_manager | drone_operator | camp_commander | sync_admin |
/// |------------|:-:|:-:|:-:|:-:|:-:|
/// | Home       | ✓ | ✓ | ✓ | ✓ | ✓ |
/// | Dashboard  | ✓ | ✓ | ✓ | ✓ | ✓ |
/// | Routes     | ✓ | ✓ | ✓ | ✓ | ✓ |
/// | Fleet      |   |   | ✓ | ✓ | ✓ |
/// | Profile    | ✓ | ✓ | ✓ | ✓ | ✓ |
List<_NavItem> _itemsForRole(UserRole role) {
  const home = _NavItem(
    screen: HomeScreen(),
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  );
  const dashboard = _NavItem(
    screen: DashboardScreen(),
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  );
  const routes = _NavItem(
    screen: RoutingScreen(),
    label: 'Routes',
    icon: Icons.route_outlined,
    selectedIcon: Icons.route,
  );
  const fleet = _NavItem(
    screen: DroneDispatchScreen(),
    label: 'Fleet',
    icon: Icons.air_outlined,
    selectedIcon: Icons.air,
  );
  const profile = _NavItem(
    screen: ProfileScreen(),
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  );

  // Fleet requires controlDrones OR executeDelivery
  final canAccessFleet = role.hasPermission(Permission.controlDrones) ||
      role.hasPermission(Permission.executeDelivery);

  return [
    home,
    dashboard,
    routes,
    if (canAccessFleet) fleet,
    profile,
  ];
}

// ---------------------------------------------------------------------------
// MainScreen
// ---------------------------------------------------------------------------

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoleProvider);
    final items = _itemsForRole(role);

    // Guard against stale index when the role changes (e.g. after re-login)
    final safeIndex = _currentIndex.clamp(0, items.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: items.map((i) => i.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primarySurfaceDefault.withValues(alpha: 0.1),
        destinations: items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon, size: 24.sp),
                selectedIcon: Icon(
                  item.selectedIcon,
                  size: 24.sp,
                  color: AppColors.primarySurfaceDefault,
                ),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
