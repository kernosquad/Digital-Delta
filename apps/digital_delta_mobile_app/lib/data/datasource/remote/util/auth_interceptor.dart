import 'package:dio/dio.dart';

import '../../local/source/auth_local_data_source.dart';

class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _authLocalDataSource;

  AuthInterceptor({required AuthLocalDataSource authLocalDataSource})
    : _authLocalDataSource = authLocalDataSource;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authLocalDataSource.getAccessToken();
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('🔑 Auth token added to ${options.method} ${options.path}');
    } else {
      print('⚠️ No auth token for ${options.method} ${options.path}');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
