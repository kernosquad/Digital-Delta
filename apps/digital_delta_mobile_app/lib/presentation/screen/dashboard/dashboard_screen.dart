import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'Operations Dashboard',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          // Offline/Online Indicator
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.green, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done, size: 16.sp, color: Colors.green),
                SizedBox(width: 4.w),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
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
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_shipping_outlined,
                    value: '24',
                    label: 'Active Vehicles',
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _StatCard(
                    icon: Icons.inventory_2_outlined,
                    value: '156',
                    label: 'Pending Deliveries',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    value: '89',
                    label: 'Completed Today',
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _StatCard(
                    icon: Icons.error_outline,
                    value: '3',
                    label: 'Critical Alerts',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Map Placeholder
            Text(
              'Live Route Map',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              height: 250.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Map Background
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.grey.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Map Overlay
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 64.sp,
                          color: AppColors.secondaryTextDefault.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Map Integration Coming Soon',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.secondaryTextDefault,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Route Indicators
                  Positioned(
                    top: 16.h,
                    right: 16.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _MapLegendItem(color: Colors.blue, label: 'Road'),
                        SizedBox(height: 4.h),
                        _MapLegendItem(color: Colors.teal, label: 'Waterway'),
                        SizedBox(height: 4.h),
                        _MapLegendItem(color: Colors.purple, label: 'Airway'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Supply Inventory Heatmap
            Text(
              'Supply Inventory Status',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 12.h),
            _InventoryCard(
              item: 'Medical Supplies',
              quantity: '450 units',
              status: 'High',
              statusColor: Colors.green,
            ),
            SizedBox(height: 8.h),
            _InventoryCard(
              item: 'Food Packages',
              quantity: '280 units',
              status: 'Medium',
              statusColor: Colors.orange,
            ),
            SizedBox(height: 8.h),
            _InventoryCard(
              item: 'Water Purification',
              quantity: '45 units',
              status: 'Critical',
              statusColor: Colors.red,
            ),
            SizedBox(height: 24.h),

            // Node Status Panel
            Text(
              'Mesh Network Nodes',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 12.h),
            _NodeCard(
              nodeName: 'Node Alpha-01',
              location: 'Sylhet District Hospital',
              status: 'Active',
              connectionStrength: 95,
            ),
            SizedBox(height: 8.h),
            _NodeCard(
              nodeName: 'Node Beta-02',
              location: 'Sunamganj Relief Camp',
              status: 'Active',
              connectionStrength: 78,
            ),
            SizedBox(height: 8.h),
            _NodeCard(
              nodeName: 'Node Gamma-03',
              location: 'Netrokona Field Base',
              status: 'Degraded',
              connectionStrength: 42,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28.sp, color: color),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTextDefault,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.secondaryTextDefault,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryTextDefault,
          ),
        ),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final String item;
  final String quantity;
  final String status;
  final Color statusColor;

  const _InventoryCard({
    required this.item,
    required this.quantity,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  quantity,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final String nodeName;
  final String location;
  final String status;
  final int connectionStrength;

  const _NodeCard({
    required this.nodeName,
    required this.location,
    required this.status,
    required this.connectionStrength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nodeName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTextDefault,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.secondaryTextDefault,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.circle,
                size: 12.sp,
                color: status == 'Active' ? Colors.green : Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text(
                'Signal:',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: LinearProgressIndicator(
                  value: connectionStrength / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    connectionStrength > 70
                        ? Colors.green
                        : connectionStrength > 40
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '$connectionStrength%',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTextDefault,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
