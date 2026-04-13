import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/service/meshcore_ble_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setUpCacheModule() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // MeshCore BLE service (Module 2/3)
  getIt.registerSingleton<MeshCoreBleService>(MeshCoreBleService());
}
