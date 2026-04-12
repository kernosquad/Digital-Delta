import '../../../../../domain/model/auth/user_model.dart';

abstract class AuthLocalDataSource {
  String getAccessToken();
  String getRefreshToken();
  UserModel? getCurrentUser();
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<void> saveCurrentUser(UserModel user);
  Future<void> saveLoginState(bool isLoggedIn);
  Future<void> clearTokens();
  Future<void> clearCurrentUser();
  Future<void> clearSession();
  bool isLoggedIn();
}
