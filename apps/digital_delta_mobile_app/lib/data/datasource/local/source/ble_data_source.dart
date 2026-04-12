import '../../../../domain/enum/ble_connection_state.dart';
import '../../../../domain/model/ble/ble_device_model.dart';

abstract class BleDataSource {
  /// Emits scanned device list whenever a new advertisement is received.
  Stream<List<BleDeviceModel>> get scanResults;

  /// Emits `true` while a BLE scan is active.
  Stream<bool> get isScanning;

  /// Watch connection state changes for [deviceId].
  Stream<BleDeviceConnectionState> watchConnectionState(String deviceId);

  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(String deviceId);
  Future<void> disconnect(String deviceId);
  Future<List<BleDeviceModel>> getConnectedDevices();
}
