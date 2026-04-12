import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'secure_storage_service.dart';

/// Device Service
///
/// Manages device identification and metadata for:
/// - M1.1: TOTP device binding
/// - M1.2: Key pair provisioning per device
/// - M3: Mesh networking node identification
/// - M8.4: Battery-aware mesh throttling
class DeviceService {
  final SecureStorageService _secureStorage;
  final DeviceInfoPlugin _deviceInfo;
  final Battery _battery = Battery();

  DeviceService(this._secureStorage, this._deviceInfo);

  /// Gets or creates a unique, persistent device ID
  ///
  /// Device ID is generated once on first app launch and persists
  /// across app reinstalls (if device allows).
  ///
  /// Format: UUID v4 (e.g., 550e8400-e29b-41d4-a716-446655440000)
  Future<String> getDeviceId() async {
    String? storedId = await _secureStorage.getDeviceId();

    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }

    // Generate new UUID-based device ID
    final uuid = const Uuid().v4();
    await _secureStorage.saveDeviceId(uuid);

    print('📱 New device ID generated: $uuid');
    return uuid;
  }

  /// Gets comprehensive device metadata
  ///
  /// Returns device information including:
  /// - Platform (iOS/Android)
  /// - Device model
  /// - OS version
  /// - Device fingerprint (deterministic hash of hardware IDs)
  Future<DeviceMetadata> getDeviceMetadata() async {
    final deviceId = await getDeviceId();

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return DeviceMetadata(
        deviceId: deviceId,
        platform: 'android',
        model: androidInfo.model,
        manufacturer: androidInfo.manufacturer,
        osVersion: androidInfo.version.release,
        sdkVersion: androidInfo.version.sdkInt.toString(),
        isPhysicalDevice: androidInfo.isPhysicalDevice,
        fingerprint: _generateFingerprint([
          androidInfo.id,
          androidInfo.device,
          androidInfo.product,
        ]),
      );
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return DeviceMetadata(
        deviceId: deviceId,
        platform: 'ios',
        model: iosInfo.utsname.machine,
        manufacturer: 'Apple',
        osVersion: iosInfo.systemVersion,
        sdkVersion: iosInfo.systemVersion,
        isPhysicalDevice: iosInfo.isPhysicalDevice,
        fingerprint: _generateFingerprint([
          iosInfo.identifierForVendor ?? '',
          iosInfo.utsname.machine,
        ]),
      );
    }

    // Fallback for other platforms (web, desktop)
    return DeviceMetadata(
      deviceId: deviceId,
      platform: Platform.operatingSystem,
      model: 'Unknown',
      manufacturer: 'Unknown',
      osVersion: Platform.operatingSystemVersion,
      sdkVersion: 'Unknown',
      isPhysicalDevice: true,
      fingerprint: _generateFingerprint([deviceId]),
    );
  }

  /// Gets current battery level (for M8.4: Battery-Aware Mesh Throttling)
  ///
  /// Returns battery percentage (0-100) or null if unavailable
  ///
  /// Note: Requires battery_plus package (add if not present)
  /// For now, returns mock value. Implement with battery_plus in production.
  Future<int?> getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      return level.clamp(0, 100);
    } catch (_) {
      return null;
    }
  }

  /// Checks if device is charging
  Future<bool> isCharging() async {
    // TODO: Implement actual charging status check with battery_plus
    return false; // Mock: not charging
  }

  /// Checks if device is stationary (for M8.4 mesh optimization)
  ///
  /// Uses accelerometer data to detect if device hasn't moved.
  /// Returns true if device is stationary for mesh throttling.
  ///
  /// Note: Requires sensors_plus package
  Future<bool> isStationary() async {
    // TODO: Implement accelerometer monitoring with sensors_plus
    return false; // Mock: device is moving
  }

  /// Generates a deterministic device fingerprint
  ///
  /// Used for detecting device changes or duplicate devices.
  /// Computed from hardware IDs (not user-modifiable).
  String _generateFingerprint(List<String> components) {
    final combined = components.join('|');
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Checks if device setup is complete for offline operation
  ///
  /// Returns true if both OTP and key pair are provisioned
  Future<bool> isFullyProvisioned() async {
    final deviceId = await getDeviceId();
    return await _secureStorage.isDeviceFullyProvisioned(deviceId);
  }

  /// Gets list of pending setup steps
  Future<List<String>> getPendingSetupSteps() async {
    final deviceId = await getDeviceId();
    final setupStatus = await _secureStorage.getDeviceSetupStatus(deviceId);

    final steps = <String>[];
    if (setupStatus == null || setupStatus['otpConfigured'] != true) {
      steps.add('POST /api/auth/otp/setup');
    }
    if (setupStatus == null || setupStatus['keyProvisioned'] != true) {
      steps.add('POST /api/auth/keys/provision');
    }

    return steps;
  }
}

/// Device Metadata Model
class DeviceMetadata {
  final String deviceId;
  final String platform;
  final String model;
  final String manufacturer;
  final String osVersion;
  final String sdkVersion;
  final bool isPhysicalDevice;
  final String fingerprint;

  DeviceMetadata({
    required this.deviceId,
    required this.platform,
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    required this.sdkVersion,
    required this.isPhysicalDevice,
    required this.fingerprint,
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'platform': platform,
    'model': model,
    'manufacturer': manufacturer,
    'os_version': osVersion,
    'sdk_version': sdkVersion,
    'is_physical_device': isPhysicalDevice,
    'fingerprint': fingerprint,
  };

  @override
  String toString() {
    return '$manufacturer $model ($platform $osVersion) - ID: $deviceId';
  }
}
