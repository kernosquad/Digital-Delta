import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Secure Storage Service
///
/// Manages secure storage of sensitive data using:
/// - FlutterSecureStorage for cryptographic keys, tokens, passwords
/// - SharedPreferences for non-sensitive settings
///
/// Platform-specific security:
/// - iOS: Keychain (SecureEnclave when available)
/// - Android: EncryptedSharedPreferences backed by Android Keystore
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  // Security constants
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    keyCipherAlgorithm:
        KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  SecureStorageService(this._secureStorage, this._prefs);

  // ── Authentication Tokens ────────────────────────────────────────────

  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(
      key: 'access_token',
      value: token,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(
      key: 'access_token',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<void> deleteAccessToken() async {
    await _secureStorage.delete(key: 'access_token');
  }

  // ── Device ID ────────────────────────────────────────────────────────

  Future<void> saveDeviceId(String deviceId) async {
    await _prefs.setString('device_id', deviceId);
  }

  Future<String?> getDeviceId() async {
    return _prefs.getString('device_id');
  }

  // ── TOTP Secret (M1.1) ───────────────────────────────────────────────

  Future<void> saveOtpSecret({
    required String deviceId,
    required String secret,
    required String algorithm,
  }) async {
    final key = 'otp_secret_$deviceId';
    final data = jsonEncode({
      'secret': secret,
      'algorithm': algorithm,
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': true,
    });

    await _secureStorage.write(
      key: key,
      value: data,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<Map<String, dynamic>?> getOtpSecret(String deviceId) async {
    final key = 'otp_secret_$deviceId';
    final data = await _secureStorage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );

    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<void> deleteOtpSecret(String deviceId) async {
    await _secureStorage.delete(key: 'otp_secret_$deviceId');
  }

  // ── Ed25519/RSA Key Pairs (M1.2) ─────────────────────────────────────

  Future<void> saveKeyPair({
    required String deviceId,
    required String publicKey,
    required String privateKey,
    required String keyType,
  }) async {
    // Public key can be stored in SharedPreferences (not sensitive)
    await _prefs.setString('public_key_$deviceId', publicKey);
    await _prefs.setString('key_type_$deviceId', keyType);

    // Private key MUST be in secure storage
    await _secureStorage.write(
      key: 'private_key_$deviceId',
      value: privateKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );

    await _prefs.setString(
      'key_provisioned_at_$deviceId',
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, String>?> getKeyPair(String deviceId) async {
    final publicKey = _prefs.getString('public_key_$deviceId');
    final privateKey = await _secureStorage.read(
      key: 'private_key_$deviceId',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    final keyType = _prefs.getString('key_type_$deviceId');

    if (publicKey == null || privateKey == null || keyType == null) {
      return null;
    }

    return {
      'publicKey': publicKey,
      'privateKey': privateKey,
      'keyType': keyType,
    };
  }

  Future<String?> getPrivateKey(String deviceId) async {
    return await _secureStorage.read(
      key: 'private_key_$deviceId',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<String?> getPublicKey(String deviceId) async {
    return _prefs.getString('public_key_$deviceId');
  }

  Future<void> deleteKeyPair(String deviceId) async {
    await _prefs.remove('public_key_$deviceId');
    await _prefs.remove('key_type_$deviceId');
    await _prefs.remove('key_provisioned_at_$deviceId');
    await _secureStorage.delete(key: 'private_key_$deviceId');
  }

  // ── User Credentials (for offline login) ────────────────────────────

  Future<void> saveUserCredentials({
    required String email,
    required String passwordHash,
  }) async {
    await _secureStorage.write(
      key: 'offline_credentials_$email',
      value: jsonEncode({
        'email': email,
        'passwordHash': passwordHash,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<Map<String, dynamic>?> getUserCredentials(String email) async {
    final data = await _secureStorage.read(
      key: 'offline_credentials_$email',
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );

    if (data == null) return null;
    return jsonDecode(data);
  }

  // ── User Session Data ────────────────────────────────────────────────

  Future<void> saveCurrentUser(Map<String, dynamic> user) async {
    await _prefs.setString('current_user', jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final data = _prefs.getString('current_user');
    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<void> deleteCurrentUser() async {
    await _prefs.remove('current_user');
  }

  // ── Device Setup Status ──────────────────────────────────────────────

  Future<void> saveDeviceSetupStatus({
    required String deviceId,
    required bool otpConfigured,
    required bool keyProvisioned,
  }) async {
    await _prefs.setString(
      'device_setup_$deviceId',
      jsonEncode({
        'otpConfigured': otpConfigured,
        'keyProvisioned': keyProvisioned,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<Map<String, dynamic>?> getDeviceSetupStatus(String deviceId) async {
    final data = _prefs.getString('device_setup_$deviceId');
    if (data == null) return null;
    return jsonDecode(data);
  }

  // ── Complete Wipe (logout) ───────────────────────────────────────────

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    // Keep device_id for next login
    final deviceId = await getDeviceId();
    await _prefs.clear();
    if (deviceId != null) {
      await saveDeviceId(deviceId);
    }
  }

  // ── Utility Methods ──────────────────────────────────────────────────

  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    final user = await getCurrentUser();
    return token != null && user != null;
  }

  Future<bool> isDeviceFullyProvisioned(String deviceId) async {
    final setupStatus = await getDeviceSetupStatus(deviceId);
    if (setupStatus == null) return false;

    return setupStatus['otpConfigured'] == true &&
        setupStatus['keyProvisioned'] == true;
  }
}
