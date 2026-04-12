import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../domain/enum/ble_connection_state.dart';
import '../../../../domain/model/ble/ble_device_model.dart';
import '../../../theme/color.dart';

class BleDeviceTile extends StatelessWidget {
  final BleDeviceModel device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const BleDeviceTile({
    super.key,
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _borderColor,
          width: device.connectionState.isConnected ? 1.5 : 0.8,
        ),
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
          // Signal / status icon
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: _iconBgColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(_deviceIcon, color: _iconColor, size: 24.sp),
          ),
          SizedBox(width: 12.w),

          // Name + live signal (no raw device IDs in UI)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTextDefault,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (device.isDigitalDeltaNode) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: Colors.deepPurple.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'DD Node',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.deepPurple,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (device.rssi != 0) ...[
                  SizedBox(height: 4.h),
                  Text(
                    _rssiDescription(device.rssi),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.secondaryTextDefault,
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
                _StatusBadge(state: device.connectionState),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // RSSI bars (only while scanning / idle)
          if (device.rssi != 0) ...[
            _RssiBars(rssi: device.rssi),
            SizedBox(width: 12.w),
          ],

          // Action button
          _ActionButton(
            state: device.connectionState,
            onConnect: onConnect,
            onDisconnect: onDisconnect,
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _rssiDescription(int rssi) {
    final quality = switch (rssi) {
      >= -55 => 'Excellent signal',
      >= -70 => 'Good signal',
      >= -85 => 'Fair signal',
      _ => 'Weak signal',
    };
    return '$quality · $rssi dBm';
  }

  IconData get _deviceIcon {
    switch (device.connectionState) {
      case BleDeviceConnectionState.connected:
        return Icons.bluetooth_connected_rounded;
      case BleDeviceConnectionState.connecting:
      case BleDeviceConnectionState.disconnecting:
        return Icons.bluetooth_searching_rounded;
      case BleDeviceConnectionState.disconnected:
        return Icons.bluetooth_rounded;
    }
  }

  Color get _iconColor {
    switch (device.connectionState) {
      case BleDeviceConnectionState.connected:
        return AppColors.primarySurfaceDefault;
      case BleDeviceConnectionState.connecting:
      case BleDeviceConnectionState.disconnecting:
        return Colors.orange;
      case BleDeviceConnectionState.disconnected:
        return AppColors.secondaryTextDefault;
    }
  }

  Color get _iconBgColor => _iconColor.withValues(alpha: 0.12);

  Color get _borderColor {
    switch (device.connectionState) {
      case BleDeviceConnectionState.connected:
        return AppColors.primarySurfaceDefault.withValues(alpha: 0.4);
      case BleDeviceConnectionState.connecting:
      case BleDeviceConnectionState.disconnecting:
        return Colors.orange.withValues(alpha: 0.4);
      case BleDeviceConnectionState.disconnected:
        return Colors.grey.shade200;
    }
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final BleDeviceConnectionState state;
  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          state.label,
          style: TextStyle(
            fontSize: 11.sp,
            color: _dotColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color get _dotColor {
    switch (state) {
      case BleDeviceConnectionState.connected:
        return AppColors.primarySurfaceDefault;
      case BleDeviceConnectionState.connecting:
      case BleDeviceConnectionState.disconnecting:
        return Colors.orange;
      case BleDeviceConnectionState.disconnected:
        return Colors.grey;
    }
  }
}

// ── RSSI bars ─────────────────────────────────────────────────────────────────

class _RssiBars extends StatelessWidget {
  final int rssi;
  const _RssiBars({required this.rssi});

  int get _bars {
    if (rssi >= -60) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -80) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < _bars;
        return Container(
          width: 4.w,
          height: (6 + i * 4).h,
          margin: EdgeInsets.only(left: 2.w),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primarySurfaceDefault
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2.r),
          ),
        );
      }),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final BleDeviceConnectionState state;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _ActionButton({
    required this.state,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isBusy) {
      return SizedBox(
        width: 20.w,
        height: 20.w,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
      );
    }

    if (state.isConnected) {
      return TextButton(
        onPressed: onDisconnect,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.dangerSurfaceDefault,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Disconnect',
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
      );
    }

    return TextButton(
      onPressed: onConnect,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primarySurfaceDefault,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Connect',
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}
