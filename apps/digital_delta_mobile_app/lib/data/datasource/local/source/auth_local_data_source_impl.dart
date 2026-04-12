import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../domain/model/auth/user_model.dart';
import 'auth_local_data_source.dart';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  final SharedPreferences _sharedPreferences;

  AuthLocalDataSourceImpl({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  @override
  String getAccessToken() {
    return _sharedPreferences.getString(_accessTokenKey) ?? '';
  }

  @override
  String getRefreshToken() {
    return _sharedPreferences.getString(_refreshTokenKey) ?? '';
  }

  @override
  UserModel? getCurrentUser() {
    final rawUser = _sharedPreferences.getString(_currentUserKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    return UserModel.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
  }

  @override
  Future<void> saveAccessToken(String token) async {
    await _sharedPreferences.setString(_accessTokenKey, token);
    print(
      '💾💾 AccessToken saved to SharedPreferences (length: ${token.length})',
    );
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    await _sharedPreferences.setString(_refreshTokenKey, token);
    print(
      '💾💾 RefreshToken saved to SharedPreferences (length: ${token.length})',
    );
  }

  @override
  Future<void> saveCurrentUser(UserModel user) async {
    await _sharedPreferences.setString(
      _currentUserKey,
      jsonEncode(user.toJson()),
    );
    await saveLoginState(true);
  }

  @override
  Future<void> saveLoginState(bool isLoggedIn) async {
    await _sharedPreferences.setBool(_isLoggedInKey, isLoggedIn);
  }

  @override
  Future<void> clearTokens() async {
    await _sharedPreferences.remove(_accessTokenKey);
    await _sharedPreferences.remove(_refreshTokenKey);
  }

  @override
  Future<void> clearCurrentUser() async {
    await _sharedPreferences.remove(_currentUserKey);
  }

  @override
  Future<void> clearSession() async {
    await clearTokens();
    await clearCurrentUser();
    await saveLoginState(false);
  }

  @override
  bool isLoggedIn() {
    return _sharedPreferences.getBool(_isLoggedInKey) ??
        getCurrentUser() != null;
  }
}
