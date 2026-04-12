import '../../enum/ble_connection_state.dart';
import '../../repository/ble_repository.dart';

class WatchBleConnectionStateUseCase {
  final BleRepository _repository;

  WatchBleConnectionStateUseCase({required BleRepository repository})
    : _repository = repository;

  Stream<BleDeviceConnectionState> call(String deviceId) =>
      _repository.watchConnectionState(deviceId);
}
