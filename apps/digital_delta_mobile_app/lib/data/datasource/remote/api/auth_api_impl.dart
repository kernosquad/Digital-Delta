import '../model/request/auth/login_request.dart';
import '../model/request/auth/register_request.dart';
import '../model/response/auth/auth_response.dart';
import '../model/response/auth/key_provision_response.dart';
import '../model/response/auth/otp_setup_response.dart';
import '../model/response/auth/user_response.dart';
import '../util/api_client.dart';
import 'auth_api.dart';

class AuthApiImpl implements AuthApi {
  static const String _basePath = '/auth';

  final ApiClient _client;

  AuthApiImpl({required ApiClient client}) : _client = client;

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(email: email, password: password);
    final response = await _client.post(
      '$_basePath/login',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(_extractData(response.data));
  }

  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final request = RegisterRequest(
      name: name,
      email: email,
      password: password,
    );
    final response = await _client.post(
      '$_basePath/register',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(_extractData(response.data));
  }

  @override
  Future<UserResponse> getProfile() async {
    final response = await _client.get('$_basePath/me');
    return UserResponse.fromJson(_extractData(response.data));
  }

  @override
  Future<void> logout() async {
    await _client.post('$_basePath/logout');
  }

  @override
  Future<OtpSetupResponse> setupOtp({required String deviceId}) async {
    final response = await _client.post(
      '$_basePath/otp/setup',
      data: {'device_id': deviceId},
    );
    return OtpSetupResponse.fromJson(_extractData(response.data));
  }

  @override
  Future<bool> verifyOtp({
    required String deviceId,
    required String code,
  }) async {
    final response = await _client.post(
      '$_basePath/otp/verify',
      data: {'device_id': deviceId, 'code': code},
    );
    final data = _extractData(response.data);
    return data['verified'] == true;
  }

  @override
  Future<KeyProvisionResponse> provisionKey({
    required String deviceId,
    required String publicKey,
    required String keyType,
  }) async {
    final response = await _client.post(
      '$_basePath/keys/provision',
      data: {
        'device_id': deviceId,
        'public_key': publicKey,
        'key_type': keyType,
      },
    );
    return KeyProvisionResponse.fromJson(_extractData(response.data));
  }

  Map<String, dynamic> _extractData(dynamic rawResponse) {
    final payload = Map<String, dynamic>.from(rawResponse as Map);
    final data = payload['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }
}
