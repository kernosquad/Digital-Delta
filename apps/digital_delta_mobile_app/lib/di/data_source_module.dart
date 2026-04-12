import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../data/datasource/local/source/auth_local_data_source.dart';
import '../data/datasource/local/source/auth_local_data_source_impl.dart';
import '../data/datasource/local/source/auth_offline_store.dart';
import '../data/datasource/local/source/auth_offline_store_impl.dart';
import '../data/datasource/local/source/ble_data_source.dart';
import '../data/datasource/local/source/ble_data_source_impl.dart';
import '../data/datasource/local/source/connectivity_data_source.dart';
import '../data/datasource/local/source/connectivity_data_source_impl.dart';
import '../data/datasource/remote/api/auth_api.dart';
import '../data/datasource/remote/api/auth_api_impl.dart';
import '../data/service/ble_sync_service.dart';
import '../data/service/nearby_mesh_service.dart';
import '../data/service/sync_mesh_service.dart';
import 'cache_module.dart';

Future<void> setUpDataSourceModule() async {
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: getIt()),
  );
  getIt.registerSingleton<AuthOfflineStore>(
    await AuthOfflineStoreImpl.create(),
  );

  getIt.registerLazySingleton<AuthApi>(() => AuthApiImpl(client: getIt()));

  // Connectivity
  getIt.registerLazySingleton<InternetConnection>(() => InternetConnection());
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<ConnectivityDataSource>(
    () => ConnectivityDataSourceImpl(
      internetConnection: getIt(),
      connectivity: getIt(),
    ),
  );

  // BLE
  getIt.registerLazySingleton<BleDataSource>(() => BleDataSourceImpl());

  getIt.registerSingleton<SyncMeshService>(
    await SyncMeshService.create(
      deviceService: getIt(),
      secureStorageService: getIt(),
    ),
  );

  // BLE CRDT Sync Service (M2 + M3 integration)
  getIt.registerLazySingleton<BleSyncService>(
    () => BleSyncService(syncMeshService: getIt<SyncMeshService>()),
  );

  // Real P2P mesh: device discovery + direct chat transport
  getIt.registerSingleton<NearbyMeshService>(
    NearbyMeshService(syncMeshService: getIt<SyncMeshService>()),
  );
}
