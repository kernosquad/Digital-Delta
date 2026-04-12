import '../domain/usecase/auth/get_profile_use_case.dart';
import '../domain/usecase/auth/login_use_case.dart';
import '../domain/usecase/auth/logout_use_case.dart';
import '../domain/usecase/auth/provision_key_use_case.dart';
import '../domain/usecase/auth/register_use_case.dart';
import '../domain/usecase/auth/setup_otp_use_case.dart';
import '../domain/usecase/auth/verify_otp_use_case.dart';
import '../domain/usecase/ble/connect_ble_device_use_case.dart';
import '../domain/usecase/ble/disconnect_ble_device_use_case.dart';
import '../domain/usecase/ble/get_connected_ble_devices_use_case.dart';
import '../domain/usecase/ble/start_ble_scan_use_case.dart';
import '../domain/usecase/ble/stop_ble_scan_use_case.dart';
import '../domain/usecase/ble/watch_ble_connection_state_use_case.dart';
import '../domain/usecase/ble/watch_ble_devices_use_case.dart';
import 'cache_module.dart';

Future<void> setUpUseCaseModule() async {
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<GetProfileUseCase>(
    () => GetProfileUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<SetupOtpUseCase>(
    () => SetupOtpUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<VerifyOtpUseCase>(
    () => VerifyOtpUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<ProvisionKeyUseCase>(
    () => ProvisionKeyUseCase(repository: getIt()),
  );

  // BLE
  getIt.registerLazySingleton<StartBleScanUseCase>(
    () => StartBleScanUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<StopBleScanUseCase>(
    () => StopBleScanUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<ConnectBleDeviceUseCase>(
    () => ConnectBleDeviceUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<DisconnectBleDeviceUseCase>(
    () => DisconnectBleDeviceUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<WatchBleDevicesUseCase>(
    () => WatchBleDevicesUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<WatchBleConnectionStateUseCase>(
    () => WatchBleConnectionStateUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<GetConnectedBleDevicesUseCase>(
    () => GetConnectedBleDevicesUseCase(repository: getIt()),
  );
}
