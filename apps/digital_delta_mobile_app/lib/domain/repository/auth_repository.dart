import '../model/auth/auth_token_model.dart';
import '../model/auth/key_provision_result_model.dart';
import '../model/auth/otp_setup_result_model.dart';
import '../model/auth/user_model.dart';
import '../util/result.dart';

abstract class AuthRepository {
  Future<Result<AuthTokenModel>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthTokenModel>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Result<UserModel>> getProfile();

  Future<Result<void>> logout();

  Future<Result<OtpSetupResultModel>> setupOtp({required String deviceId});

  Future<Result<bool>> verifyOtp({
    required String deviceId,
    required String code,
  });

  Future<Result<KeyProvisionResultModel>> provisionKey({
    required String deviceId,
    required String publicKey,
    required String keyType,
  });

  Future<Result<void>> syncPendingActions();
}
