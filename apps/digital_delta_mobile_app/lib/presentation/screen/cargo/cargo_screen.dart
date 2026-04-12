import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color.dart';

class CargoScreen extends StatefulWidget {
  const CargoScreen({super.key});

  @override
  State<CargoScreen> createState() => _CargoScreenState();
}

class _CargoScreenState extends State<CargoScreen> {
  String _selectedPriority = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'Cargo Management',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Priority Filter
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PriorityChip(
                    label: 'All',
                    isSelected: _selectedPriority == 'All',
                    onTap: () => setState(() => _selectedPriority = 'All'),
                  ),
                  SizedBox(width: 8.w),
                  _PriorityChip(
                    label: 'P0 Critical',
                    color: Colors.red,
                    isSelected: _selectedPriority == 'P0',
                    onTap: () => setState(() => _selectedPriority = 'P0'),
                  ),
                  SizedBox(width: 8.w),
                  _PriorityChip(
                    label: 'P1 High',
                    color: Colors.orange,
                    isSelected: _selectedPriority == 'P1',
                    onTap: () => setState(() => _selectedPriority = 'P1'),
                  ),
                  SizedBox(width: 8.w),
                  _PriorityChip(
                    label: 'P2 Standard',
                    color: Colors.blue,
                    isSelected: _selectedPriority == 'P2',
                    onTap: () => setState(() => _selectedPriority = 'P2'),
                  ),
                  SizedBox(width: 8.w),
                  _PriorityChip(
                    label: 'P3 Low',
                    color: Colors.grey,
                    isSelected: _selectedPriority == 'P3',
                    onTap: () => setState(() => _selectedPriority = 'P3'),
                  ),
                ],
              ),
            ),
          ),

          // Cargo List
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _CargoCard(
                  cargoId: 'CRG-8921',
                  description: 'Antivenom (Snake Bite)',
                  priority: 'P0',
                  priorityLabel: 'Critical Medical',
                  slaWindow: '2 hrs',
                  destination: 'Sylhet District Hospital',
                  assignedVehicle: 'TRK-001',
                  eta: '15 min',
                  status: 'In Transit',
                  breachRisk: false,
                ),
                SizedBox(height: 12.h),
                _CargoCard(
                  cargoId: 'CRG-8922',
                  description: 'Emergency Medical Kit',
                  priority: 'P0',
                  priorityLabel: 'Critical Medical',
                  slaWindow: '2 hrs',
                  destination: 'Sunamganj Relief Camp',
                  assignedVehicle: 'BOAT-007',
                  eta: '9 min',
                  status: 'In Transit',
                  breachRisk: false,
                ),
                SizedBox(height: 12.h),
                _CargoCard(
                  cargoId: 'CRG-8910',
                  description: 'Fresh Food Supplies',
                  priority: 'P1',
                  priorityLabel: 'High Priority',
                  slaWindow: '6 hrs',
                  destination: 'Netrokona Camp 4',
                  assignedVehicle: 'BOAT-012',
                  eta: '28 min',
                  status: 'In Transit',
                  breachRisk: false,
                ),
                SizedBox(height: 12.h),
                _CargoCard(
                  cargoId: 'CRG-8905',
                  description: 'Water Purification Tablets',
                  priority: 'P1',
                  priorityLabel: 'High Priority',
                  slaWindow: '6 hrs',
                  destination: 'Field Base Gamma',
                  assignedVehicle: 'Unassigned',
                  eta: '—',
                  status: 'Pending',
                  breachRisk: true,
                ),
                SizedBox(height: 12.h),
                _CargoCard(
                  cargoId: 'CRG-8898',
                  description: 'Blankets & Tarpaulin',
                  priority: 'P2',
                  priorityLabel: 'Standard',
                  slaWindow: '24 hrs',
                  destination: 'Relief Point 12',
                  assignedVehicle: 'TRK-008',
                  eta: '—',
                  status: 'Queued',
                  breachRisk: false,
                ),
                SizedBox(height: 12.h),
                _CargoCard(
                  cargoId: 'CRG-8876',
                  description: 'General Clothing',
                  priority: 'P3',
                  priorityLabel: 'Low Priority',
                  slaWindow: '72 hrs',
                  destination: 'Distribution Center C',
                  assignedVehicle: 'Unassigned',
                  eta: '—',
                  status: 'Pending',
                  breachRisk: false,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cargo_new_cargo',
        onPressed: () {},
        backgroundColor: AppColors.primarySurfaceDefault,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Cargo',
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

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primarySurfaceDefault;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.shade300, width: 1),
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

class _CargoCard extends StatelessWidget {
  final String cargoId;
  final String description;
  final String priority;
  final String priorityLabel;
  final String slaWindow;
  final String destination;
  final String assignedVehicle;
  final String eta;
  final String status;
  final bool breachRisk;

  const _CargoCard({
    required this.cargoId,
    required this.description,
    required this.priority,
    required this.priorityLabel,
    required this.slaWindow,
    required this.destination,
    required this.assignedVehicle,
    required this.eta,
    required this.status,
    required this.breachRisk,
  });

  Color _getPriorityColor() {
    switch (priority) {
      case 'P0':
        return Colors.red;
      case 'P1':
        return Colors.orange;
      case 'P2':
        return Colors.blue;
      case 'P3':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: breachRisk ? Border.all(color: Colors.red, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: breachRisk
                ? Colors.red.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Priority Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
                if (breachRisk)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 14.sp, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          'SLA Risk',
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
          ),

          // Cargo Details
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cargoId,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTextDefault,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
                SizedBox(height: 12.h),
                Divider(height: 1, color: Colors.grey.shade200),
                SizedBox(height: 12.h),
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'SLA Window',
                  value: slaWindow,
                ),
                SizedBox(height: 8.h),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Destination',
                  value: destination,
                ),
                SizedBox(height: 8.h),
                _InfoRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Vehicle',
                  value: assignedVehicle,
                ),
                if (eta != '—') ...[
                  SizedBox(height: 8.h),
                  _InfoRow(icon: Icons.schedule, label: 'ETA', value: eta),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'in transit':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'queued':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
          ),
        ),
      ],
    );
  }
}
