import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/color.dart';
import '../../util/toaster.dart';
import 'notifier/provider.dart';
import 'state/ble_ui_state.dart';
import 'widget/ble_device_tile.dart';

class BleScreen extends ConsumerStatefulWidget {
  const BleScreen({super.key});

  @override
  ConsumerState<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends ConsumerState<BleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissions());
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final denied = statuses.values.any(
      (s) => s.isDenied || s.isPermanentlyDenied,
    );

    if (denied && mounted) {
      Toaster.showWarning(
        context,
        'Bluetooth & Location permissions are required to scan for devices.',
      );
    }
  }

  // ── Listeners ──────────────────────────────────────────────────────────────

  void _setupListeners() {
    ref.listen<BleUiState>(bleNotifierProvider, (_, curr) {
      curr.maybeWhen(
        error: (msg) => Toaster.showError(context, msg),
        orElse: () {},
      );
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _toggleScan() {
    final notifier = ref.read(bleNotifierProvider.notifier);
    final isScanning = ref
        .read(bleNotifierProvider)
        .maybeWhen(scanning: (_) => true, orElse: () => false);
    if (isScanning) {
      notifier.stopScan();
    } else {
      notifier.startScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    _setupListeners();

    final state = ref.watch(bleNotifierProvider);

    final deviceList = state.maybeWhen(
      scanning: (d) => d,
      idle: (d) => d,
      orElse: () => [],
    );

    final isScanning = state.maybeWhen(
      scanning: (_) => true,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text(
          'BLE Scanner',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          if (isScanning)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: Text(
                  'Scanning…',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.primarySurfaceDefault,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Scan progress bar
          if (isScanning)
            LinearProgressIndicator(
              color: AppColors.primarySurfaceDefault,
              backgroundColor: AppColors.primarySurfaceDefault.withValues(
                alpha: 0.15,
              ),
            ),

          // Device list
          Expanded(
            child: deviceList.isEmpty
                ? _EmptyState(isScanning: isScanning)
                : ListView.builder(
                    padding: EdgeInsets.only(top: 8.h, bottom: 100.h),
                    itemCount: deviceList.length,
                    itemBuilder: (_, index) {
                      final device = deviceList[index];
                      return BleDeviceTile(
                        device: device,
                        onConnect: () => ref
                            .read(bleNotifierProvider.notifier)
                            .connect(device.id),
                        onDisconnect: () => ref
                            .read(bleNotifierProvider.notifier)
                            .disconnect(device.id),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Scan toggle FAB
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'ble_scan_toggle',
        onPressed: _toggleScan,
        backgroundColor: isScanning
            ? AppColors.dangerSurfaceDefault
            : AppColors.primarySurfaceDefault,
        icon: Icon(
          isScanning ? Icons.stop_rounded : Icons.bluetooth_searching_rounded,
          color: Colors.white,
        ),
        label: Text(
          isScanning ? 'Stop Scan' : 'Start Scan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isScanning;
  const _EmptyState({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isScanning
                ? Icons.bluetooth_searching_rounded
                : Icons.bluetooth_disabled_rounded,
            size: 64.sp,
            color: isScanning
                ? AppColors.primarySurfaceDefault
                : AppColors.secondaryTextDefault,
          ),
          SizedBox(height: 16.h),
          Text(
            isScanning ? 'Searching for devices…' : 'No devices found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextDefault,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isScanning
                ? 'Make sure Bluetooth is enabled on your device.'
                : 'Tap Start Scan to discover nearby Bluetooth devices.',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.secondaryTextDefault,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
