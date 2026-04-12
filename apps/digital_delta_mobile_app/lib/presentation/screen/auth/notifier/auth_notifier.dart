import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/audit_trail.dart';
import '../../../../core/security/device_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/security/totp_generator.dart';
import '../../../../data/datasource/local/source/auth_local_data_source.dart';
import '../../../../di/cache_module.dart';
import '../../../../domain/model/auth/key_provision_result_model.dart';
import '../../../../domain/model/auth/otp_setup_result_model.dart';
import '../../../../domain/model/auth/user_model.dart';
import '../../../../domain/usecase/auth/get_profile_use_case.dart';
import '../../../../domain/usecase/auth/login_use_case.dart';
import '../../../../domain/usecase/auth/logout_use_case.dart';
import '../../../../domain/usecase/auth/provision_key_use_case.dart';
import '../../../../domain/usecase/auth/register_use_case.dart';
import '../../../../domain/usecase/auth/setup_otp_use_case.dart';
import '../../../../domain/usecase/auth/verify_otp_use_case.dart';
import '../state/auth_ui_state.dart';

class AuthNotifier extends StateNotifier<AuthUiState> {
  AuthNotifier() : super(const AuthUiState.initial());

  Future<void> login({
    required String email,
    required String password,
    String? otpCode,
  }) async {
    state = const AuthUiState.loading();

    final deviceService = getIt<DeviceService>();
    final secureStorage = getIt<SecureStorageService>();
    final auditTrail = getIt<AuditTrail>();
    final deviceId = await deviceService.getDeviceId();

    // Check if OTP is configured for this device
    final otpData = await secureStorage.getOtpSecret(deviceId);

    if (otpData != null && otpCode == null) {
      state = const AuthUiState.error(
        'OTP code required for this device. Please enter your 6-digit code.',
      );
      return;
    }

    // Validate OTP locally before sending to server (offline-first)
    if (otpCode != null && otpData != null) {
      final isValidOtp = TotpGenerator.validateTOTP(
        code: otpCode,
        secret: otpData['secret'] as String,
        tolerance: 1, // Allow ±30s clock drift
      );

      if (!isValidOtp) {
        await auditTrail.appendEvent(
          eventType: AuthEventType.otpFail,
          deviceId: deviceId,
          payload: {'email': email, 'reason': 'invalid_code'},
        );
        state = const AuthUiState.error(
          'Invalid OTP code. Please check and try again.',
        );
        return;
      }
    }

    final useCase = getIt<LoginUseCase>();
    final result = await useCase(email: email, password: password);

    // Handle result and log to audit trail
    result.when(
      success: (authToken) async {
        // Log successful login
        await auditTrail.appendEvent(
          eventType: AuthEventType.loginSuccess,
          userId: int.tryParse(authToken.user.id),
          deviceId: deviceId,
          payload: {'email': email},
        );
        state = const AuthUiState.success();
      },
      failure: (failure) async {
        // Log failed login
        await auditTrail.appendEvent(
          eventType: AuthEventType.loginFail,
          deviceId: deviceId,
          payload: {'email': email, 'error': failure.message},
        );
        state = AuthUiState.error(failure.message);
      },
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = const AuthUiState.loading();

    final deviceService = getIt<DeviceService>();
    final auditTrail = getIt<AuditTrail>();
    final deviceId = await deviceService.getDeviceId();

    final useCase = getIt<RegisterUseCase>();
    final result = await useCase(name: name, email: email, password: password);

    // Handle result and log to audit trail
    result.when(
      success: (authToken) async {
        // Log registration
        await auditTrail.appendEvent(
          eventType: AuthEventType.loginSuccess,
          userId: int.tryParse(authToken.user.id),
          deviceId: deviceId,
          payload: {'email': email, 'action': 'register', 'role': role},
        );
        state = const AuthUiState.success();
      },
      failure: (failure) {
        state = AuthUiState.error(failure.message);
      },
    );
  }

  Future<void> logout() async {
    state = const AuthUiState.loading();

    final deviceService = getIt<DeviceService>();
    final auditTrail = getIt<AuditTrail>();
    final deviceId = await deviceService.getDeviceId();

    // Log logout before clearing session
    await auditTrail.appendEvent(
      eventType: AuthEventType.logout,
      deviceId: deviceId,
      payload: {'timestamp': DateTime.now().toIso8601String()},
    );

    final useCase = getIt<LogoutUseCase>();
    final result = await useCase();

    state = result.when(
      success: (_) => const AuthUiState.success(),
      failure: (failure) => AuthUiState.error(failure.message),
    );
  }

  Future<UserModel?> getProfile() async {
    state = const AuthUiState.loading();

    final useCase = getIt<GetProfileUseCase>();
    final result = await useCase();

    UserModel? user;

    state = result.when(
      success: (data) {
        user = data;
        return const AuthUiState.success();
      },
      failure: (failure) => AuthUiState.error(failure.message),
    );

    return user;
  }

  Future<OtpSetupResultModel?> setupOtp({required String deviceId}) async {
    state = const AuthUiState.loading();

    final secureStorage = getIt<SecureStorageService>();
    final auditTrail = getIt<AuditTrail>();
    final authLocal = getIt<AuthLocalDataSource>();

    try {
      // M1.1 - Generate TOTP secret locally (offline-first)
      final secret = TotpGenerator.generateSecret();

      // Get user email for QR code label
      final user = authLocal.getCurrentUser();
      final userEmail = user?.email ?? 'user@digitaldelta.com';

      // Create otpauth URI for QR code (Google Authenticator format)
      final otpauthUri =
          'otpauth://totp/Digital%20Delta:$userEmail?secret=$secret&issuer=Digital%20Delta&algorithm=SHA256&digits=6&period=30';

      // Save OTP secret locally in secure storage
      await secureStorage.saveOtpSecret(
        deviceId: deviceId,
        secret: secret,
        algorithm: 'totp',
      );

      await auditTrail.appendEvent(
        eventType: AuthEventType.otpSuccess,
        deviceId: deviceId,
        payload: {'action': 'setup', 'offline': true},
      );

      // Try to sync to server (optional - don't fail if offline)
      try {
        final useCase = getIt<SetupOtpUseCase>();
        await useCase(deviceId: deviceId);
        print('✅ OTP secret synced to server');
      } catch (e) {
        print('⚠️ OTP server sync failed (offline mode): $e');
        // Continue anyway - offline OTP works without server
      }

      final otpResult = OtpSetupResultModel(
        deviceId: deviceId,
        userId: user?.id ?? 'local',
        qrCode: otpauthUri,
        secret: secret,
      );

      state = const AuthUiState.success();
      return otpResult;
    } catch (e) {
      print('❌ OTP local setup error: $e');
      state = AuthUiState.error('Failed to setup OTP: $e');
      return null;
    }
  }

  Future<bool> verifyOtp({
    required String deviceId,
    required String code,
  }) async {
    state = const AuthUiState.loading();

    final secureStorage = getIt<SecureStorageService>();
    final auditTrail = getIt<AuditTrail>();

    try {
      // M1.1 - Verify TOTP locally (offline-first)
      // Get the secret from secure storage
      final otpData = await secureStorage.getOtpSecret(deviceId);

      if (otpData == null || otpData['secret'] == null) {
        print('❌ No OTP secret found for device: $deviceId');
        state = const AuthUiState.error(
          'OTP not configured. Please setup OTP first.',
        );

        await auditTrail.appendEvent(
          eventType: AuthEventType.otpFail,
          deviceId: deviceId,
          payload: {'action': 'verify', 'error': 'No OTP secret found'},
        );

        return false;
      }

      final secret = otpData['secret'] as String;

      // Validate TOTP code locally (RFC 6238)
      final isValid = TotpGenerator.validateTOTP(
        code: code,
        secret: secret,
        tolerance: 1, // ±30s clock drift tolerance
      );

      if (isValid) {
        print('✅ OTP verified locally (offline)');

        await auditTrail.appendEvent(
          eventType: AuthEventType.otpSuccess,
          deviceId: deviceId,
          payload: {'action': 'verify', 'offline': true},
        );

        // Update device setup status
        await secureStorage.saveDeviceSetupStatus(
          deviceId: deviceId,
          otpConfigured: true,
          keyProvisioned: false,
        );

        // Try to sync to server (optional - don't fail if offline)
        try {
          final useCase = getIt<VerifyOtpUseCase>();
          await useCase(deviceId: deviceId, code: code);
          print('✅ OTP verification synced to server');
        } catch (e) {
          print('⚠️ OTP server sync failed (offline mode): $e');
          // Continue anyway - local validation succeeded
        }

        state = const AuthUiState.success();
        return true;
      } else {
        print('❌ Invalid OTP code');

        await auditTrail.appendEvent(
          eventType: AuthEventType.otpFail,
          deviceId: deviceId,
          payload: {
            'action': 'verify',
            'error': 'Invalid code',
            'offline': true,
          },
        );

        state = const AuthUiState.error('Invalid OTP code. Please try again.');
        return false;
      }
    } catch (e) {
      print('❌ OTP verification error: $e');

      await auditTrail.appendEvent(
        eventType: AuthEventType.otpFail,
        deviceId: deviceId,
        payload: {'action': 'verify', 'error': e.toString()},
      );

      state = AuthUiState.error('OTP verification failed: $e');
      return false;
    }
  }

  Future<KeyProvisionResultModel?> provisionKey({
    required String deviceId,
    required String publicKey,
    required String keyType,
  }) async {
    state = const AuthUiState.loading();

    final useCase = getIt<ProvisionKeyUseCase>();
    final secureStorage = getIt<SecureStorageService>();
    final auditTrail = getIt<AuditTrail>();

    final result = await useCase(
      deviceId: deviceId,
      publicKey: publicKey,
      keyType: keyType,
    );

    KeyProvisionResultModel? keyResult;

    // Handle result
    result.when(
      success: (data) async {
        await auditTrail.appendEvent(
          eventType: AuthEventType.keyProvision,
          deviceId: deviceId,
          payload: {'keyType': keyType},
        );

        // Update device setup status
        final currentStatus = await secureStorage.getDeviceSetupStatus(
          deviceId,
        );
        await secureStorage.saveDeviceSetupStatus(
          deviceId: deviceId,
          otpConfigured: currentStatus?['otpConfigured'] ?? false,
          keyProvisioned: true,
        );

        keyResult = data;
        state = const AuthUiState.success();
      },
      failure: (failure) {
        state = AuthUiState.error(failure.message);
      },
    );

    return keyResult;
  }
}
