import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'Fleet Management',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedFilter == 'All',
                    onTap: () => setState(() => _selectedFilter = 'All'),
                  ),
                  SizedBox(width: 8.w),
                  _FilterChip(
                    label: 'Trucks',
                    isSelected: _selectedFilter == 'Trucks',
                    onTap: () => setState(() => _selectedFilter = 'Trucks'),
                  ),
                  SizedBox(width: 8.w),
                  _FilterChip(
                    label: 'Boats',
                    isSelected: _selectedFilter == 'Boats',
                    onTap: () => setState(() => _selectedFilter = 'Boats'),
                  ),
                  SizedBox(width: 8.w),
                  _FilterChip(
                    label: 'Drones',
                    isSelected: _selectedFilter == 'Drones',
                    onTap: () => setState(() => _selectedFilter = 'Drones'),
                  ),
                ],
              ),
            ),
          ),

          // Vehicles List
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _VehicleCard(
                  vehicleId: 'TRK-001',
                  type: 'Truck',
                  icon: Icons.local_shipping,
                  driver: 'Karim Ahmed',
                  status: 'Active',
                  currentLoad: 'Medical Supplies (P0)',
                  location: 'En route to Sylhet Hospital',
                  battery: 85,
                  eta: '15 min',
                  statusColor: Colors.green,
                ),
                SizedBox(height: 12.h),
                _VehicleCard(
                  vehicleId: 'BOAT-012',
                  type: 'Speedboat',
                  icon: Icons.directions_boat,
                  driver: 'Rahim Mia',
                  status: 'Active',
                  currentLoad: 'Food Packages (P1)',
                  location: 'Waterway Route 4',
                  battery: 62,
                  eta: '28 min',
                  statusColor: Colors.green,
                ),
                SizedBox(height: 12.h),
                _VehicleCard(
                  vehicleId: 'DRN-005',
                  type: 'Drone',
                  icon: Icons.airplanemode_active,
                  driver: 'Auto-Pilot',
                  status: 'Charging',
                  currentLoad: 'None',
                  location: 'Base Station Alpha',
                  battery: 34,
                  eta: '—',
                  statusColor: Colors.orange,
                ),
                SizedBox(height: 12.h),
                _VehicleCard(
                  vehicleId: 'TRK-008',
                  type: 'Truck',
                  icon: Icons.local_shipping,
                  driver: 'Nasir Uddin',
                  status: 'Idle',
                  currentLoad: 'None',
                  location: 'Netrokona Depot',
                  battery: 100,
                  eta: '—',
                  statusColor: Colors.grey,
                ),
                SizedBox(height: 12.h),
                _VehicleCard(
                  vehicleId: 'BOAT-007',
                  type: 'Speedboat',
                  icon: Icons.directions_boat,
                  driver: 'Jamal Hossain',
                  status: 'Active',
                  currentLoad: 'Water Purification (P0)',
                  location: 'Canal Junction 12',
                  battery: 71,
                  eta: '9 min',
                  statusColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fleet_add_vehicle',
        onPressed: () {},
        backgroundColor: AppColors.primarySurfaceDefault,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Vehicle',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySurfaceDefault
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.secondaryTextDefault,
          ),
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String vehicleId;
  final String type;
  final IconData icon;
  final String driver;
  final String status;
  final String currentLoad;
  final String location;
  final int battery;
  final String eta;
  final Color statusColor;

  const _VehicleCard({
    required this.vehicleId,
    required this.type,
    required this.icon,
    required this.driver,
    required this.status,
    required this.currentLoad,
    required this.location,
    required this.battery,
    required this.eta,
    required this.statusColor,
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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 28.sp, color: statusColor),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          vehicleId,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTextDefault,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.secondaryTextDefault,
                      ),
                    ),
                  ],
                ),
              ),
              if (eta != '—')
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        eta,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'ETA',
                        style: TextStyle(fontSize: 10.sp, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, color: Colors.grey.shade200),
          SizedBox(height: 12.h),
          _InfoRow(icon: Icons.person_outline, label: 'Driver', value: driver),
          SizedBox(height: 8.h),
          _InfoRow(
            icon: Icons.inventory_2_outlined,
            label: 'Load',
            value: currentLoad,
          ),
          SizedBox(height: 8.h),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: location,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                Icons.battery_charging_full,
                size: 16.sp,
                color: battery > 60
                    ? Colors.green
                    : battery > 30
                    ? Colors.orange
                    : Colors.red,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: LinearProgressIndicator(
                  value: battery / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    battery > 60
                        ? Colors.green
                        : battery > 30
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '$battery%',
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.secondaryTextDefault),
        SizedBox(width: 8.w),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.secondaryTextDefault,
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextDefault,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
