import '../data/mapper/auth/auth_mapper.dart';
import '../data/repository/auth_repository_impl.dart';
import '../data/repository/ble_repository_impl.dart';
import '../data/service/auth_sync_manager.dart';
import '../domain/repository/auth_repository.dart';
import '../domain/repository/ble_repository.dart';
import 'cache_module.dart';

Future<void> setUpRepositoryModule() async {
  getIt.registerLazySingleton<AuthMapper>(() => AuthMapper());

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authApi: getIt(),
      authLocalDataSource: getIt(),
      authOfflineStore: getIt(),
      connectivityDataSource: getIt(),
      authMapper: getIt(),
    ),
  );

  getIt.registerLazySingleton<AuthSyncManager>(
    () => AuthSyncManager(
      authRepository: getIt(),
      connectivityDataSource: getIt(),
    ),
  );

  getIt.registerLazySingleton<BleRepository>(
    () => BleRepositoryImpl(dataSource: getIt()),
  );
}
