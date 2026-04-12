import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color.dart';

class PodScannerScreen extends StatefulWidget {
  const PodScannerScreen({super.key});

  @override
  State<PodScannerScreen> createState() => _PodScannerScreenState();
}

class _PodScannerScreenState extends State<PodScannerScreen> {
  bool _isScanning = false;
  String? _scannedData;

  void _startScan() {
    setState(() {
      _isScanning = true;
      // Simulate scan after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _scannedData = 'CRG-8921|TRK-001|SIGNED';
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'Proof of Delivery',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanner View
            Container(
              width: double.infinity,
              height: 350.h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Camera placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isScanning)
                          Column(
                            children: [
                              SizedBox(
                                width: 60.w,
                                height: 60.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Scanning QR Code...',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else if (_scannedData != null)
                          Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 80.sp,
                                color: Colors.green,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'QR Code Scanned',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 80.sp,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Position QR Code in Frame',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Scan frame overlay
                  if (!_isScanning && _scannedData == null)
                    Center(
                      child: Container(
                        width: 250.w,
                        height: 250.h,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primarySurfaceDefault,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Scan Button
            if (!_isScanning && _scannedData == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySurfaceDefault,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Start Scanning',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Scanned Data Display
            if (_scannedData != null) ...[
              Text(
                'Delivery Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTextDefault,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
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
                    _DetailRow(
                      label: 'Cargo ID',
                      value: 'CRG-8921',
                      icon: Icons.inventory_2,
                    ),
                    SizedBox(height: 12.h),
                    _DetailRow(
                      label: 'Vehicle ID',
                      value: 'TRK-001',
                      icon: Icons.local_shipping,
                    ),
                    SizedBox(height: 12.h),
                    _DetailRow(
                      label: 'Driver',
                      value: 'Karim Ahmed',
                      icon: Icons.person,
                    ),
                    SizedBox(height: 12.h),
                    _DetailRow(
                      label: 'Destination',
                      value: 'Sylhet District Hospital',
                      icon: Icons.location_on,
                    ),
                    SizedBox(height: 12.h),
                    _DetailRow(
                      label: 'Signature Status',
                      value: 'Driver Signed',
                      icon: Icons.verified,
                      valueColor: Colors.green,
                    ),
                    SizedBox(height: 12.h),
                    Divider(height: 1, color: Colors.grey.shade200),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 20.sp,
                          color: Colors.green,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Cryptographic Verification Passed',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _scannedData = null);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(
                          color: AppColors.primarySurfaceDefault,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Scan Again',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primarySurfaceDefault,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Show success dialog
                        _showConfirmationDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Confirm Receipt',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 24.h),

            // Instructions
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20.sp, color: Colors.blue),
                      SizedBox(width: 8.w),
                      Text(
                        'How it Works',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _InstructionItem(
                    number: '1',
                    text:
                        'Driver generates a signed QR code containing delivery details',
                  ),
                  SizedBox(height: 8.h),
                  _InstructionItem(
                    number: '2',
                    text:
                        'Recipient scans QR code to verify cryptographic signature',
                  ),
                  SizedBox(height: 8.h),
                  _InstructionItem(
                    number: '3',
                    text:
                        'Both parties countersign to create immutable delivery receipt',
                  ),
                  SizedBox(height: 8.h),
                  _InstructionItem(
                    number: '4',
                    text: 'Receipt is synced to distributed ledger when online',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28.sp),
            SizedBox(width: 12.w),
            const Text('Delivery Confirmed'),
          ],
        ),
        content: Text(
          'The delivery has been verified and recorded to the blockchain. Chain of custody updated.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _scannedData = null);
            },
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primarySurfaceDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.secondaryTextDefault),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.primaryTextDefault,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24.w,
          height: 24.h,
          decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, color: Colors.blue.shade900),
          ),
        ),
      ],
    );
  }
}
