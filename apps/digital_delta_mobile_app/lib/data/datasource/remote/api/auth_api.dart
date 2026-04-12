import '../model/response/auth/auth_response.dart';
import '../model/response/auth/key_provision_response.dart';
import '../model/response/auth/otp_setup_response.dart';
import '../model/response/auth/user_response.dart';

abstract class AuthApi {
  Future<AuthResponse> login({required String email, required String password});

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  });

  Future<UserResponse> getProfile();

  Future<void> logout();

  Future<OtpSetupResponse> setupOtp({required String deviceId});

  Future<bool> verifyOtp({required String deviceId, required String code});

  Future<KeyProvisionResponse> provisionKey({
    required String deviceId,
    required String publicKey,
    required String keyType,
  });
}
