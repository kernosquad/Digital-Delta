import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../../domain/enum/ble_connection_state.dart';
import '../../../../domain/model/ble/ble_device_model.dart';
import 'ble_data_source.dart';

class BleDataSourceImpl implements BleDataSource {
  /// Cache of discovered devices keyed by device ID string.
  final Map<String, BluetoothDevice> _deviceCache = {};

  @override
  Stream<List<BleDeviceModel>> get scanResults {
    return FlutterBluePlus.scanResults.map((results) {
      for (final r in results) {
        _deviceCache[r.device.remoteId.str] = r.device;
      }

      return results
          .map(
            (r) => BleDeviceModel(
              id: r.device.remoteId.str,
              name: r.device.platformName.isEmpty
                  ? 'Unknown Device'
                  : r.device.platformName,
              rssi: r.rssi,
            ),
          )
          .toList();
    });
  }

  @override
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  @override
  Stream<BleDeviceConnectionState> watchConnectionState(String deviceId) {
    final device = _deviceCache[deviceId];
    if (device == null) return const Stream.empty();
    return device.connectionState.map(_mapConnectionState);
  }

  @override
  Future<void> startScan() async {
    if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Future<void> connect(String deviceId) async {
    final device = _deviceCache[deviceId];
    if (device == null) {
      throw Exception('Device $deviceId not in scan cache. Scan first.');
    }
    await device.connect(license: License.free, autoConnect: false);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    final device = _deviceCache[deviceId];
    if (device == null) {
      throw Exception('Device $deviceId not in scan cache.');
    }
    await device.disconnect();
  }

  @override
  Future<List<BleDeviceModel>> getConnectedDevices() async {
    return FlutterBluePlus.connectedDevices
        .map(
          (d) => BleDeviceModel(
            id: d.remoteId.str,
            name: d.platformName.isEmpty ? 'Unknown Device' : d.platformName,
            rssi: 0,
            connectionState: BleDeviceConnectionState.connected,
          ),
        )
        .toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  BleDeviceConnectionState _mapConnectionState(BluetoothConnectionState state) {
    return state == BluetoothConnectionState.connected
        ? BleDeviceConnectionState.connected
        : BleDeviceConnectionState.disconnected;
  }
}
