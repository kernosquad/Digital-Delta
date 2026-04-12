import '../../repository/ble_repository.dart';
import '../../util/result.dart';

class DisconnectBleDeviceUseCase {
  final BleRepository _repository;

  DisconnectBleDeviceUseCase({required BleRepository repository})
    : _repository = repository;

  Future<Result<void>> call({required String deviceId}) =>
      _repository.disconnect(deviceId);
}
