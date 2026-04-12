import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as rble;

/// Shared BLE display-name rules: prefer human-readable Bluetooth names and
/// never surface raw MAC / UUID strings in the UI when avoidable.
class BleDisplayName {
  BleDisplayName._();

  static final RegExp _mac = RegExp(
    r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
  );
  static final RegExp _uuidLike = RegExp(
    r'^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$',
  );

  /// True when [value] is a hardware identifier, not a user-visible name.
  static bool looksLikeHardwareId(String value) {
    final v = value.trim();
    if (v.isEmpty) return true;
    if (_mac.hasMatch(v)) return true;
    if (_uuidLike.hasMatch(v)) return true;
    if (v.length >= 32 && RegExp(r'^[0-9A-Fa-f:]+$').hasMatch(v)) {
      return true;
    }
    return false;
  }

  /// Best-effort name from a reactive_ble discovered device.
  static String fromDiscoveredDevice(rble.DiscoveredDevice r) {
    for (final candidate in [
      r.name.trim(),
    ]) {
      if (candidate.isNotEmpty && !looksLikeHardwareId(candidate)) {
        return candidate;
      }
    }
    return _unnamedLabel;
  }

  /// Name for an already-connected [BluetoothDevice] (e.g. system cache).
  static String fromConnectedDevice(BluetoothDevice d) {
    for (final candidate in [d.advName.trim(), d.platformName.trim()]) {
      if (candidate.isNotEmpty && !looksLikeHardwareId(candidate)) {
        return candidate;
      }
    }
    return _unnamedLabel;
  }

  static const String _unnamedLabel = 'Unnamed Bluetooth device';
}
