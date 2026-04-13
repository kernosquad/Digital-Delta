// Module 2 — MeshCore BLE Device Scanner Screen
//
// Scans for nearby MeshCore LoRa companion radios via BLE,
// displays them with RSSI signal strength, and allows connecting.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/meshcore/meshcore_models.dart';
import '../../../data/service/meshcore_ble_service.dart';
import '../../theme/color.dart';
import '../../util/routes.dart';
import 'providers.dart';

class MeshCoreScannerScreen extends ConsumerStatefulWidget {
  const MeshCoreScannerScreen({super.key});

  @override
  ConsumerState<MeshCoreScannerScreen> createState() =>
      _MeshCoreScannerScreenState();
}

class _MeshCoreScannerScreenState extends ConsumerState<MeshCoreScannerScreen> {
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  Future<void> _startScan() async {
    final svc = ref.read(meshCoreBleServiceProvider);
    if (svc.isConnected) return;
    await svc.startScan();
  }

  Future<void> _connect(MeshCoreScanResult result) async {
    if (_connecting) return;
    setState(() => _connecting = true);
    try {
      await ref.read(meshCoreBleServiceProvider).connect(result.device);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.meshcoreContacts);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          backgroundColor: AppColors.dangerSurfaceDefault,
        ),
      );
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Widget _buildRssiIcon(int rssi) {
    Color color;
    IconData icon;
    if (rssi >= -60) {
      color = AppColors.primarySurfaceDefault;
      icon = Icons.signal_cellular_alt;
    } else if (rssi >= -75) {
      color = AppColors.warningSurfaceDefault;
      icon = Icons.signal_cellular_alt_2_bar;
    } else {
      color = AppColors.dangerSurfaceDefault;
      icon = Icons.signal_cellular_alt_1_bar;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 2.w),
        Text(
          '$rssi dBm',
          style: TextStyle(
            fontSize: 11.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final connStateAsync = ref.watch(meshCoreConnectionStateProvider);
    final scanAsync = ref.watch(meshCoreScanResultsProvider);

    final connState =
        connStateAsync.valueOrNull ?? MeshCoreConnectionState.disconnected;
    final isScanning = connState == MeshCoreConnectionState.scanning;
    final isConnected = connState == MeshCoreConnectionState.connected;

    final results = scanAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryTextDefault,
        elevation: 0,
        title: Text(
          'MeshCore Devices',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTextDefault,
          ),
        ),
        actions: [
          if (isScanning)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primarySurfaceDefault,
                ),
              ),
            ),
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.contacts_outlined),
              tooltip: 'Contacts',
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.meshcoreContacts),
            ),
          IconButton(
            icon: Icon(
              isScanning ? Icons.stop_circle_outlined : Icons.refresh,
              color: AppColors.primarySurfaceDefault,
            ),
            tooltip: isScanning ? 'Stop Scan' : 'Scan Again',
            onPressed: isScanning
                ? () => ref.read(meshCoreBleServiceProvider).stopScan()
                : _startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Connection banner ─────────────────────────────────────────
          if (isConnected)
            _ConnectedBanner(
              onContacts: () =>
                  Navigator.pushNamed(context, Routes.meshcoreContacts),
              onDisconnect: () async {
                await ref.read(meshCoreBleServiceProvider).disconnect();
              },
            ),

          // ── Scan results ──────────────────────────────────────────────
          Expanded(
            child: results.isEmpty
                ? _EmptyState(isScanning: isScanning)
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (_, i) {
                      final r = results[i];
                      return _DeviceCard(
                        result: r,
                        rssiWidget: _buildRssiIcon(r.rssi),
                        isConnecting: _connecting,
                        onConnect: () => _connect(r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ConnectedBanner extends StatelessWidget {
  final VoidCallback onContacts;
  final VoidCallback onDisconnect;

  const _ConnectedBanner({
    required this.onContacts,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primarySurfaceDefault,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected, color: Colors.white, size: 20),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Connected to MeshCore radio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onContacts,
            child: Text(
              'View Network',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.link_off, color: Colors.white, size: 18),
            tooltip: 'Disconnect',
            onPressed: onDisconnect,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final MeshCoreScanResult result;
  final Widget rssiWidget;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.result,
    required this.rssiWidget,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: AppColors.primarySurfaceTint,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.router_outlined,
            color: AppColors.primarySurfaceDefault,
            size: 22.sp,
          ),
        ),
        title: Text(
          result.name,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextDefault,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Row(
            children: [
              rssiWidget,
              SizedBox(width: 12.w),
              Text(
                result.device.remoteId.str,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
            ],
          ),
        ),
        trailing: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primarySurfaceDefault,
            minimumSize: Size(72.w, 36.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          onPressed: isConnecting ? null : onConnect,
          child: isConnecting
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Connect',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isScanning;

  const _EmptyState({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar, size: 64.sp, color: AppColors.borderDefault),
          SizedBox(height: 16.h),
          Text(
            isScanning
                ? 'Scanning for MeshCore devices…'
                : 'No MeshCore devices found.\nTap refresh to scan again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.secondaryTextDefault,
            ),
          ),
          if (isScanning) ...[
            SizedBox(height: 24.h),
            const CircularProgressIndicator(
              color: AppColors.primarySurfaceDefault,
            ),
          ],
        ],
      ),
    );
  }
}
