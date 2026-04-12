import '../../repository/ble_repository.dart';
import '../../util/result.dart';

class ConnectBleDeviceUseCase {
  final BleRepository _repository;

  ConnectBleDeviceUseCase({required BleRepository repository})
    : _repository = repository;

  Future<Result<void>> call({required String deviceId}) =>
      _repository.connect(deviceId);
}
