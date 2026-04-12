import '../../../domain/enum/ble_connection_state.dart';
import '../../../domain/model/ble/ble_device_model.dart';
import '../../../domain/repository/ble_repository.dart';
import '../../../domain/util/failure.dart';
import '../../../domain/util/result.dart';
import '../datasource/local/source/ble_data_source.dart';

class BleRepositoryImpl implements BleRepository {
  final BleDataSource _dataSource;

  BleRepositoryImpl({required BleDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Stream<List<BleDeviceModel>> get scanResults => _dataSource.scanResults;

  @override
  Stream<bool> get isScanning => _dataSource.isScanning;

  @override
  Stream<BleDeviceConnectionState> watchConnectionState(String deviceId) =>
      _dataSource.watchConnectionState(deviceId);

  @override
  Future<Result<void>> startScan() => _execute(_dataSource.startScan);

  @override
  Future<Result<void>> stopScan() => _execute(_dataSource.stopScan);

  @override
  Future<Result<void>> connect(String deviceId) =>
      _execute(() => _dataSource.connect(deviceId));

  @override
  Future<Result<void>> disconnect(String deviceId) =>
      _execute(() => _dataSource.disconnect(deviceId));

  @override
  Future<Result<List<BleDeviceModel>>> getConnectedDevices() async {
    try {
      final devices = await _dataSource.getConnectedDevices();
      return Result.success(devices);
    } catch (e) {
      return Result.failure(Failure.unknownException(message: e.toString()));
    }
  }

  // ── Internal helper ────────────────────────────────────────────────────────

  Future<Result<void>> _execute(Future<void> Function() action) async {
    try {
      await action();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unknownException(message: e.toString()));
    }
  }
}
