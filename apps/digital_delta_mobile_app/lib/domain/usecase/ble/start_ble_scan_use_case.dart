import '../../repository/ble_repository.dart';
import '../../util/result.dart';

class StartBleScanUseCase {
  final BleRepository _repository;

  StartBleScanUseCase({required BleRepository repository})
    : _repository = repository;

  Future<Result<void>> call() => _repository.startScan();
}
