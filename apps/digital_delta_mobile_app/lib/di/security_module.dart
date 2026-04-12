import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/security/audit_trail.dart';
import '../core/security/device_service.dart';
import '../core/security/secure_storage_service.dart';
import 'cache_module.dart' show getIt;

Future<void> setUpSecurityModule() async {
  // External dependencies
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final deviceInfo = DeviceInfoPlugin();

  // Register external dependencies if not already registered
  if (!getIt.isRegistered<FlutterSecureStorage>()) {
    getIt.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);
  }

  if (!getIt.isRegistered<DeviceInfoPlugin>()) {
    getIt.registerLazySingleton<DeviceInfoPlugin>(() => deviceInfo);
  }

  // Security services - singleton instances
  if (!getIt.isRegistered<AuditTrail>()) {
    getIt.registerLazySingleton<AuditTrail>(
      () => AuditTrail(getIt<SharedPreferences>()),
    );
  }

  if (!getIt.isRegistered<SecureStorageService>()) {
    getIt.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService(
        getIt<FlutterSecureStorage>(),
        getIt<SharedPreferences>(),
      ),
    );
  }

  if (!getIt.isRegistered<DeviceService>()) {
    getIt.registerLazySingleton<DeviceService>(
      () => DeviceService(
        getIt<SecureStorageService>(),
        getIt<DeviceInfoPlugin>(),
      ),
    );
  }
}
