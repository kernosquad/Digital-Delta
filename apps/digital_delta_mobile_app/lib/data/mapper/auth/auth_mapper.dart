import '../../../domain/model/auth/auth_token_model.dart';
import '../../../domain/model/auth/key_provision_result_model.dart';
import '../../../domain/model/auth/otp_setup_result_model.dart';
import '../../../domain/model/auth/user_model.dart';
import '../../datasource/remote/model/response/auth/auth_response.dart';
import '../../datasource/remote/model/response/auth/key_provision_response.dart';
import '../../datasource/remote/model/response/auth/otp_setup_response.dart';
import '../../datasource/remote/model/response/auth/user_response.dart';

class AuthMapper {
  AuthTokenModel toTokenModel(AuthResponse response) {
    return AuthTokenModel(
      accessToken: response.accessToken,
      tokenType: response.tokenType,
      expiresIn: response.expiresIn,
      user: toUserModel(response.user),
    );
  }

  UserModel toUserModel(UserResponse response) {
    return UserModel(
      id: response.id,
      email: response.email,
      name: response.name,
      avatar: response.avatar,
      phone: response.phone,
      role: response.role,
      status: response.status,
      lastSeenAt: response.lastSeenAt,
      createdAt: response.createdAt,
      updatedAt: response.updatedAt,
    );
  }

  OtpSetupResultModel toOtpSetupResultModel(OtpSetupResponse response) {
    return OtpSetupResultModel(
      deviceId: response.deviceId,
      userId: response.userId,
      qrCode: response.qrCode,
      secret: response.secret,
    );
  }

  KeyProvisionResultModel toKeyProvisionResultModel(
    KeyProvisionResponse response,
  ) {
    return KeyProvisionResultModel(
      deviceId: response.deviceId,
      keyId: response.keyId,
      expiresAt: response.expiresAt,
    );
  }
}
