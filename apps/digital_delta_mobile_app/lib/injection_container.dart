import 'data/service/auth_sync_manager.dart';
import 'di/cache_module.dart';
import 'di/data_source_module.dart';
import 'di/network_module.dart';
import 'di/repository_module.dart';
import 'di/security_module.dart';
import 'di/use_case_module.dart';

Future<void> setup() async {
  await setUpCacheModule();
  await setUpSecurityModule();
  await setUpDataSourceModule();
  await setUpNetworkModule();
  await setUpRepositoryModule();
  await setUpUseCaseModule();
  await getIt<AuthSyncManager>().start();
}
