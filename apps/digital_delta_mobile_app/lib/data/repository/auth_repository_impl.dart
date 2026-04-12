import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../domain/model/auth/auth_token_model.dart';
import '../../domain/model/auth/key_provision_result_model.dart';
import '../../domain/model/auth/otp_setup_result_model.dart';
import '../../domain/model/auth/user_model.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/util/failure.dart';
import '../../domain/util/result.dart';
import '../datasource/local/model/auth/pending_auth_action.dart';
import '../datasource/local/source/auth_local_data_source.dart';
import '../datasource/local/source/auth_offline_store.dart';
import '../datasource/local/source/connectivity_data_source.dart';
import '../datasource/remote/api/auth_api.dart';
import '../mapper/auth/auth_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;
  final AuthLocalDataSource _authLocalDataSource;
  final AuthOfflineStore _authOfflineStore;
  final ConnectivityDataSource _connectivityDataSource;
  final AuthMapper _authMapper;

  AuthRepositoryImpl({
    required AuthApi authApi,
    required AuthLocalDataSource authLocalDataSource,
    required AuthOfflineStore authOfflineStore,
    required ConnectivityDataSource connectivityDataSource,
    required AuthMapper authMapper,
  }) : _authApi = authApi,
       _authLocalDataSource = authLocalDataSource,
       _authOfflineStore = authOfflineStore,
       _connectivityDataSource = connectivityDataSource,
       _authMapper = authMapper;

  @override
  Future<Result<AuthTokenModel>> login({
    required String email,
    required String password,
  }) async {
    if (await _isOnline()) {
      try {
        final response = await _authApi.login(email: email, password: password);
        final tokenModel = _authMapper.toTokenModel(response);
        await _persistAuthenticatedUser(
          tokenModel: tokenModel,
          password: password,
          isSynced: true,
        );
        print('✅ Login successful! Token saved for ${tokenModel.user.email}');
        await _authOfflineStore.deletePendingActionsByTypeAndEmail(
          type: 'login',
          email: email,
        );
        return Result.success(tokenModel);
      } on DioException catch (error) {
        print(
          '❌ Login API error: ${error.response?.statusCode} - ${error.message}',
        );
        if (!_isConnectionError(error)) {
          return Result.failure(
            _mapDioFailure(error, fallbackMessage: 'Login failed'),
          );
        }
        print('⚠️ Connection error during login, falling back to offline');
      } catch (error) {
        print('❌ Login exception: $error');
        return Result.failure(
          Failure.unknownException(message: error.toString()),
        );
      }
    }

    return _loginLocally(email: email, password: password);
  }

  @override
  Future<Result<AuthTokenModel>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (await _isOnline()) {
      try {
        final response = await _authApi.register(
          name: name,
          email: email,
          password: password,
        );
        final tokenModel = _authMapper.toTokenModel(response);
        await _persistAuthenticatedUser(
          tokenModel: tokenModel,
          password: password,
          isSynced: true,
        );
        print(
          '✅ Registration successful - Token saved: ${tokenModel.accessToken.substring(0, 20)}...',
        );
        await _authOfflineStore.deletePendingActionsByTypeAndEmail(
          type: 'register',
          email: email,
        );
        return Result.success(tokenModel);
      } on DioException catch (error) {
        print('❌ Registration API error: ${error.response?.statusCode}');
        print('   Response: ${error.response?.data}');
        if (!_isConnectionError(error)) {
          // Server error (like 500) - return failure, don't fallback to offline
          return Result.failure(
            _mapDioFailure(error, fallbackMessage: 'Registration failed'),
          );
        }
        print(
          '⚠️ Connection error during registration, falling back to offline',
        );
      } catch (error) {
        print('❌ Registration exception: $error');
        return Result.failure(
          Failure.unknownException(message: error.toString()),
        );
      }
    }

    return _registerLocally(name: name, email: email, password: password);
  }

  @override
  Future<Result<UserModel>> getProfile() async {
    final isOnline = await _isOnline();
    final accessToken = _authLocalDataSource.getAccessToken();
    final hasToken = accessToken.isNotEmpty;

    print('🔍 getProfile - isOnline: $isOnline, hasToken: $hasToken');
    if (hasToken && accessToken.length > 20) {
      print('🔑 Token preview: ${accessToken.substring(0, 20)}...');
    } else if (hasToken) {
      print('🔑 Token found (length: ${accessToken.length})');
    } else {
      print('❌ NO ACCESS TOKEN stored - cannot make authenticated API calls!');
    }

    if (isOnline && hasToken) {
      try {
        print('📡 Fetching profile from API...');
        final response = await _authApi.getProfile();
        final user = _authMapper.toUserModel(response);
        await _authLocalDataSource.saveCurrentUser(user);

        final account = await _authOfflineStore.findAccountByEmail(user.email);
        if (account != null) {
          await _authOfflineStore.upsertAccount(
            user: user,
            passwordHash: account.passwordHash,
            isSynced: true,
          );
        }

        print('✅ Profile fetched from API: ${user.email}');
        return Result.success(user);
      } on DioException catch (error) {
        print('❌ DioException in getProfile: ${error.type} - ${error.message}');
        if (!_isConnectionError(error)) {
          return Result.failure(
            _mapDioFailure(error, fallbackMessage: 'Failed to fetch profile'),
          );
        }
        // Connection error - fall through to cached data
        print('⚠️ Connection error, using cached data');
      } catch (error) {
        print('❌ Exception in getProfile: $error');
        return Result.failure(
          Failure.unknownException(message: error.toString()),
        );
      }
    } else {
      if (!isOnline) {
        print('📴 Device is offline, using cached data');
      } else if (!hasToken) {
        print('⚠️ Device is online but NO ACCESS TOKEN - cannot call API');
        print(
          '   This usually means login/register did not complete successfully',
        );
      }
    }

    final currentUser = _authLocalDataSource.getCurrentUser();
    if (currentUser != null) {
      print('💾 Returning cached user: ${currentUser.email}');
      return Result.success(currentUser);
    }

    print('❌ No cached user available');
    return const Result.failure(
      Failure.connectionException(
        message:
            'Profile is unavailable offline until you sign in at least once.',
      ),
    );
  }

  @override
  Future<Result<void>> logout() async {
    try {
      if (await _isOnline() &&
          _authLocalDataSource.getAccessToken().isNotEmpty) {
        await _authApi.logout();
      }

      await _authLocalDataSource.clearSession();
      return const Result.success(null);
    } on DioException catch (error) {
      await _authLocalDataSource.clearSession();
      if (_isConnectionError(error)) {
        return const Result.success(null);
      }
      return Result.failure(
        _mapDioFailure(error, fallbackMessage: 'Logout failed'),
      );
    } catch (error) {
      return Result.failure(
        Failure.unknownException(message: error.toString()),
      );
    }
  }

  @override
  Future<Result<OtpSetupResultModel>> setupOtp({
    required String deviceId,
  }) async {
    final currentUser = _authLocalDataSource.getCurrentUser();
    if (currentUser == null) {
      return const Result.failure(
        Failure.unauthorizedException(
          message: 'You must be signed in to configure OTP.',
        ),
      );
    }

    if (await _isOnline() && _authLocalDataSource.getAccessToken().isNotEmpty) {
      try {
        final response = await _authApi.setupOtp(deviceId: deviceId);
        await _authOfflineStore.saveOtpDevice(
          email: currentUser.email,
          deviceId: deviceId,
        );
        return Result.success(_authMapper.toOtpSetupResultModel(response));
      } on DioException catch (error) {
        if (!_isConnectionError(error)) {
          return Result.failure(
            _mapDioFailure(error, fallbackMessage: 'OTP setup failed'),
          );
        }
      } catch (error) {
        return Result.failure(
          Failure.unknownException(message: error.toString()),
        );
      }
    }

    await _authOfflineStore.saveOtpDevice(
      email: currentUser.email,
      deviceId: deviceId,
    );
    await _authOfflineStore.queueAction(
      type: 'otp_setup',
      email: currentUser.email,
      payload: {'device_id': deviceId},
    );

    return Result.success(
      OtpSetupResultModel(
        deviceId: deviceId,
        userId: currentUser.id,
        qrCode:
            'otpauth://totp/DigitalDelta:${currentUser.email}?secret=OFFLINE&issuer=DigitalDelta',
        secret: 'OFFLINE_MODE_${deviceId.toUpperCase()}',
      ),
    );
  }

  @override
  Future<Result<bool>> verifyOtp({
    required String deviceId,
    required String code,
  }) async {
    final currentUser = _authLocalDataSource.getCurrentUser();
    if (currentUser == null) {
      return const Result.failure(
        Failure.unauthorizedException(
          message: 'You must be signed in to verify OTP.',
        ),
      );
    }

    if (await _isOnline() && _authLocalDataSource.getAccessToken().isNotEmpty) {
      try {
        final verified = await _authApi.verifyOtp(
          deviceId: deviceId,
          code: code,
        );
        return Result.success(verified);
      } on DioException catch (error) {
        if (!_isConnectionError(error)) {
          return Result.failure(
            _mapDioFailure(error, fallbackMessage: 'OTP verification failed'),
          );
        }
      } catch (error) {
        return Result.failure(
          Failure.unknownException(message: error.toString()),
        );
      }
    }

    final hasOtpDevice = await _authOfflineStore.hasOtpDevice(
      email: currentUser.email,
      deviceId: deviceId,
    );
    if (!hasOtpDevice) {
      return const Result.failure(
        Failure.validationException(
          message: 'No OTP configuration was found for this device.',
        ),
      );
    }

    await _authOfflineStore.queueAction(
      type: 'otp_verify',
      email: currentUser.email,
      payload: {'device_id': deviceId, 'code': code},
    );

    return const Result.success(true);
  }

  @override
  Future<Result<KeyProvisionResultModel>> provisionKey({
    required String deviceId,
    required String publicKey,
    required String keyType,
  }) async {
    final currentUser = _authLocalDataSource.getCurrentUser();
    if (currentUser == null) {
      return const Result.failure(
        Failure.unauthorizedException(
          message: 'You must be signed in to provision a key.',
        ),
      );
    }

    if (await _isOnline() && _authLocalDataSource.getAccessToken().isNotEmpty) {
      try {
        final response = await _authApi.provisionKey(
          deviceId: deviceId,
          publicKey: publicKey,
          keyType: keyType,
        );
        await _authOfflineStore.saveUserKey(
          email: currentUser.email,
          deviceId: deviceId,
          publicKey: publicKey,
          keyType: keyType,
        );
        return Result.success(_authMapper.toKeyProvisionResultModel(response));
      } on DioException catch (error) {
        if (!_isConnectionError(error)) {
          return Result.failure(
            _mapDioFailure(error, fallbackMessage: 'Key provisioning failed'),
          );
        }
      } catch (error) {
        return Result.failure(
          Failure.unknownException(message: error.toString()),
        );
      }
    }

    await _authOfflineStore.saveUserKey(
      email: currentUser.email,
      deviceId: deviceId,
      publicKey: publicKey,
      keyType: keyType,
    );
    await _authOfflineStore.queueAction(
      type: 'key_provision',
      email: currentUser.email,
      payload: {
        'device_id': deviceId,
        'public_key': publicKey,
        'key_type': keyType,
      },
    );

    return Result.success(
      KeyProvisionResultModel(
        deviceId: deviceId,
        keyId: 'offline_${deviceId}_${DateTime.now().millisecondsSinceEpoch}',
        expiresAt: DateTime.now()
            .add(const Duration(days: 365))
            .toIso8601String(),
      ),
    );
  }

  @override
  Future<Result<void>> syncPendingActions() async {
    if (!await _isOnline()) {
      return const Result.success(null);
    }

    try {
      final actions = await _authOfflineStore.getPendingActions();
      for (final action in actions) {
        await _syncAction(action);
      }
      return const Result.success(null);
    } on DioException catch (error) {
      if (_isConnectionError(error)) {
        return const Result.success(null);
      }
      return Result.failure(
        _mapDioFailure(error, fallbackMessage: 'Failed to sync auth changes'),
      );
    } catch (error) {
      return Result.failure(
        Failure.unknownException(message: error.toString()),
      );
    }
  }

  Future<Result<AuthTokenModel>> _loginLocally({
    required String email,
    required String password,
  }) async {
    final account = await _authOfflineStore.findAccountByEmail(email);
    if (account == null ||
        account.passwordHash !=
            _hashPassword(email: email, password: password)) {
      return const Result.failure(
        Failure.validationException(message: 'Invalid email or password.'),
      );
    }

    await _authLocalDataSource.clearTokens();
    await _authLocalDataSource.saveCurrentUser(account.user);
    await _authLocalDataSource.saveLoginState(true);

    if (account.isSynced) {
      await _authOfflineStore.queueAction(
        type: 'login',
        email: email,
        payload: {'email': email, 'password': password},
      );
    }

    return Result.success(
      AuthTokenModel(
        accessToken: '',
        user: account.user,
        isOffline: true,
        needsServerSync: true,
      ),
    );
  }

  Future<Result<AuthTokenModel>> _registerLocally({
    required String name,
    required String email,
    required String password,
  }) async {
    final existingAccount = await _authOfflineStore.findAccountByEmail(email);
    if (existingAccount != null) {
      return const Result.failure(
        Failure.validationException(
          message: 'Email already registered on this device.',
        ),
      );
    }

    final localUser = UserModel(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      email: email,
      name: name,
      role: 'field_volunteer',
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _authOfflineStore.upsertAccount(
      user: localUser,
      passwordHash: _hashPassword(email: email, password: password),
      isSynced: false,
    );
    await _authOfflineStore.queueAction(
      type: 'register',
      email: email,
      payload: {'name': name, 'email': email, 'password': password},
    );

    await _authLocalDataSource.clearTokens();
    await _authLocalDataSource.saveCurrentUser(localUser);
    await _authLocalDataSource.saveLoginState(true);

    return Result.success(
      AuthTokenModel(
        accessToken: '',
        user: localUser,
        isOffline: true,
        needsServerSync: true,
      ),
    );
  }

  Future<void> _persistAuthenticatedUser({
    required AuthTokenModel tokenModel,
    required String password,
    required bool isSynced,
  }) async {
    print('💾 Saving auth tokens for user: ${tokenModel.user.email}');
    await _authLocalDataSource.saveAccessToken(tokenModel.accessToken);
    await _authLocalDataSource.saveRefreshToken(tokenModel.refreshToken);
    await _authLocalDataSource.saveCurrentUser(tokenModel.user);
    await _authLocalDataSource.saveLoginState(true);
    print('✓ Access token saved (${tokenModel.accessToken.length} characters)');
    print('✓ User data saved');
    await _authOfflineStore.upsertAccount(
      user: tokenModel.user,
      passwordHash: _hashPassword(
        email: tokenModel.user.email,
        password: password,
      ),
      isSynced: isSynced,
    );
  }

  Future<void> _syncAction(PendingAuthAction action) async {
    switch (action.type) {
      case 'register':
        await _syncRegisterAction(action);
        return;
      case 'login':
        await _syncLoginAction(action);
        return;
      case 'otp_setup':
        await _syncOtpSetupAction(action);
        return;
      case 'otp_verify':
        await _syncOtpVerifyAction(action);
        return;
      case 'key_provision':
        await _syncKeyProvisionAction(action);
        return;
      default:
        await _authOfflineStore.deletePendingAction(action.id);
        return;
    }
  }

  Future<void> _syncRegisterAction(PendingAuthAction action) async {
    final payload = action.payload;

    try {
      await _authApi.register(
        name: payload['name'] as String,
        email: payload['email'] as String,
        password: payload['password'] as String,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 409) {
        rethrow;
      }
    }

    final loginResponse = await _authApi.login(
      email: payload['email'] as String,
      password: payload['password'] as String,
    );
    final tokenModel = _authMapper.toTokenModel(loginResponse);
    await _persistAuthenticatedUser(
      tokenModel: tokenModel,
      password: payload['password'] as String,
      isSynced: true,
    );
    await _authOfflineStore.deletePendingActionsByTypeAndEmail(
      type: 'login',
      email: action.email,
    );
    await _authOfflineStore.deletePendingAction(action.id);
  }

  Future<void> _syncLoginAction(PendingAuthAction action) async {
    final payload = action.payload;
    final response = await _authApi.login(
      email: payload['email'] as String,
      password: payload['password'] as String,
    );
    final tokenModel = _authMapper.toTokenModel(response);
    await _persistAuthenticatedUser(
      tokenModel: tokenModel,
      password: payload['password'] as String,
      isSynced: true,
    );
    await _authOfflineStore.deletePendingAction(action.id);
  }

  Future<void> _syncOtpSetupAction(PendingAuthAction action) async {
    if (_authLocalDataSource.getAccessToken().isEmpty) {
      return;
    }

    await _authApi.setupOtp(deviceId: action.payload['device_id'] as String);
    await _authOfflineStore.deletePendingAction(action.id);
  }

  Future<void> _syncOtpVerifyAction(PendingAuthAction action) async {
    if (_authLocalDataSource.getAccessToken().isEmpty) {
      return;
    }

    await _authApi.verifyOtp(
      deviceId: action.payload['device_id'] as String,
      code: action.payload['code'] as String,
    );
    await _authOfflineStore.deletePendingAction(action.id);
  }

  Future<void> _syncKeyProvisionAction(PendingAuthAction action) async {
    if (_authLocalDataSource.getAccessToken().isEmpty) {
      return;
    }

    await _authApi.provisionKey(
      deviceId: action.payload['device_id'] as String,
      publicKey: action.payload['public_key'] as String,
      keyType: action.payload['key_type'] as String,
    );
    await _authOfflineStore.deletePendingAction(action.id);
  }

  Future<bool> _isOnline() async {
    final status = await _connectivityDataSource.currentStatus;
    return status.maybeWhen(online: (_) => true, orElse: () => false);
  }

  bool _isConnectionError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown;
  }

  Failure _mapDioFailure(
    DioException error, {
    required String fallbackMessage,
  }) {
    final responseData = error.response?.data;
    final statusCode = error.response?.statusCode ?? 500;
    final message =
        _extractErrorMessage(responseData) ?? error.message ?? fallbackMessage;

    if (_isConnectionError(error)) {
      return Failure.connectionException(message: message);
    }

    if (statusCode == 401) {
      return Failure.unauthorizedException(message: message);
    }

    if (statusCode == 422 || statusCode == 409) {
      return Failure.validationException(message: message);
    }

    return Failure.serverException(
      message: message,
      statusCode: statusCode,
      data: responseData,
    );
  }

  String? _extractErrorMessage(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final errors = responseData['errors'];
    if (errors is List && errors.isNotEmpty) {
      final firstError = errors.first;
      if (firstError is Map<String, dynamic> &&
          firstError['message'] is String) {
        return firstError['message'] as String;
      }
    }

    final message = responseData['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return null;
  }

  String _hashPassword({required String email, required String password}) {
    final bytes = utf8.encode('$email::$password');
    return sha256.convert(bytes).toString();
  }
}
