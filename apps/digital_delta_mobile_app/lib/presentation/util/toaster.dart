import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../domain/enum/connection_type.dart';

class Toaster {
  Toaster._();

  static void showSuccess(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
      showProgressBar: true,
      dragToClose: true,
    );
  }

  static void showError(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 4),
      alignment: Alignment.topCenter,
      showProgressBar: true,
      dragToClose: true,
    );
  }

  static void showWarning(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
      showProgressBar: true,
      dragToClose: true,
    );
  }

  static void showInfo(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
      showProgressBar: true,
      dragToClose: true,
    );
  }

  // ── Connectivity specific ─────────────────────────────────────────────────

  static void showConnected(BuildContext context, ConnectionType type) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: Text('Back Online · ${type.displayName}'),
      description: Text(type.onlineMessage),
      icon: Icon(_connectionIcon(type)),
      autoCloseDuration: const Duration(seconds: 4),
      alignment: Alignment.topCenter,
      showProgressBar: true,
      dragToClose: true,
      pauseOnHover: true,
    );
  }

  static void showDisconnected(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: const Text('No Internet Connection'),
      description: const Text(
        'Please check your Wi-Fi, Mobile Data or Bluetooth and try again.',
      ),
      icon: const Icon(Icons.wifi_off_rounded),
      // No auto-close — stays until user dismisses or connection is restored
      autoCloseDuration: const Duration(seconds: 6),
      alignment: Alignment.topCenter,
      showProgressBar: true,
      dragToClose: true,
      pauseOnHover: true,
    );
  }

  static IconData _connectionIcon(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
        return Icons.wifi_rounded;
      case ConnectionType.mobile:
        return Icons.signal_cellular_alt_rounded;
      case ConnectionType.ethernet:
        return Icons.cable_rounded;
      case ConnectionType.bluetooth:
        return Icons.bluetooth_rounded;
      case ConnectionType.vpn:
        return Icons.vpn_lock_rounded;
      case ConnectionType.other:
        return Icons.language_rounded;
      case ConnectionType.none:
        return Icons.wifi_off_rounded;
    }
  }
}
