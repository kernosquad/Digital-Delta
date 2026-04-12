import 'package:dio/dio.dart';

import '../core/config/environment_config.dart';
import '../data/datasource/remote/util/auth_interceptor.dart';
import '../data/datasource/remote/util/api_client.dart';
import '../data/datasource/remote/util/logging_interceptor.dart';
import '../data/datasource/local/source/auth_local_data_source.dart';
import 'cache_module.dart';

Future<void> setUpNetworkModule() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: EnvironmentConfig.apiBaseUrl,
      connectTimeout: Duration(seconds: EnvironmentConfig.connectionTimeout),
      receiveTimeout: Duration(seconds: EnvironmentConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true', // Required for ngrok
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(authLocalDataSource: getIt<AuthLocalDataSource>()),
    LoggingInterceptor(),
  ]);

  getIt.registerLazySingleton<Dio>(() => dio);
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(dio: getIt()));
}
