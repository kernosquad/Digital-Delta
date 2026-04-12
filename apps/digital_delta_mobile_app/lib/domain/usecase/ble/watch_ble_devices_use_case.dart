import '../../model/ble/ble_device_model.dart';
import '../../repository/ble_repository.dart';

class WatchBleDevicesUseCase {
  final BleRepository _repository;

  WatchBleDevicesUseCase({required BleRepository repository})
    : _repository = repository;

  Stream<List<BleDeviceModel>> call() => _repository.scanResults;
}
