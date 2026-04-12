import '../../repository/ble_repository.dart';
import '../../util/result.dart';

class StopBleScanUseCase {
  final BleRepository _repository;

  StopBleScanUseCase({required BleRepository repository})
    : _repository = repository;

  Future<Result<void>> call() => _repository.stopScan();
}
