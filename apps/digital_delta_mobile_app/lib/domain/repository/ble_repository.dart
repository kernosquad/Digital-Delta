import '../enum/ble_connection_state.dart';
import '../model/ble/ble_device_model.dart';
import '../util/result.dart';

abstract class BleRepository {
  /// Emits updated scan results whenever a new advertisement is received.
  Stream<List<BleDeviceModel>> get scanResults;

  /// Emits `true` while a scan is active.
  Stream<bool> get isScanning;

  /// Watch live connection state changes for a specific [deviceId].
  Stream<BleDeviceConnectionState> watchConnectionState(String deviceId);

  Future<Result<void>> startScan();
  Future<Result<void>> stopScan();
  Future<Result<void>> connect(String deviceId);
  Future<Result<void>> disconnect(String deviceId);
  Future<Result<List<BleDeviceModel>>> getConnectedDevices();
}
