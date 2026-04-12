import '../../model/ble/ble_device_model.dart';
import '../../repository/ble_repository.dart';
import '../../util/result.dart';

class GetConnectedBleDevicesUseCase {
  final BleRepository _repository;

  GetConnectedBleDevicesUseCase({required BleRepository repository})
    : _repository = repository;

  Future<Result<List<BleDeviceModel>>> call() =>
      _repository.getConnectedDevices();
}
