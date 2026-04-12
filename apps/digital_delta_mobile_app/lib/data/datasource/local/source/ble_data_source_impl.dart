import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as rble;

import '../../../../domain/enum/ble_connection_state.dart';
import '../../../../domain/model/ble/ble_device_model.dart';
import 'ble_data_source.dart';
import 'ble_display_name.dart';

/// Custom GATT service UUID advertising the Digital Delta mesh node.
const String _kDdServiceUuidStr = '0000dd01-0000-1000-8000-00805f9b34fb';

class BleDataSourceImpl implements BleDataSource {
  /// Cache of discovered devices keyed by device ID string.
  final Map<String, fbp.BluetoothDevice> _deviceCache = {};

  final rble.FlutterReactiveBle _reactiveBle = rble.FlutterReactiveBle();

  final _scanController = StreamController<List<BleDeviceModel>>.broadcast();
  final Map<String, rble.DiscoveredDevice> _discoveredCache = {};
  StreamSubscription? _scanSub;
  bool _isScanningRaw = false;
  final _isScanningController = StreamController<bool>.broadcast();

  /// Returns true if the device is advertising the Digital Delta service UUID.
  static bool _isDigitalDeltaNode(rble.DiscoveredDevice r) {
    return r.serviceUuids.any(
      (u) => u.toString().toLowerCase() == _kDdServiceUuidStr,
    );
  }

  @override
  Stream<List<BleDeviceModel>> get scanResults => _scanController.stream;

  @override
  Stream<bool> get isScanning => _isScanningController.stream;

  @override
  Stream<BleDeviceConnectionState> watchConnectionState(String deviceId) {
    final device = _deviceCache[deviceId];
    if (device == null) return const Stream.empty();
    return device.connectionState.map(_mapConnectionState);
  }

  @override
  Future<void> startScan() async {
    if (_isScanningRaw) return;
    _isScanningRaw = true;
    _isScanningController.add(true);
    _discoveredCache.clear();

    _scanSub?.cancel();
    _scanSub = _reactiveBle.scanForDevices(withServices: [], scanMode: rble.ScanMode.lowLatency).listen((device) {
       _discoveredCache[device.id] = device;

       // In flutter_blue_plus 2.x, RemoteId is used to construct a BluetoothDevice or fromId
       try {
         // Attempt to instantiate using fromId (recent versions)
         _deviceCache[device.id] = fbp.BluetoothDevice.fromId(device.id);
       } catch (_) {
         // Fallback if fromId isn't available
       }

       final sorted = _discoveredCache.values.toList()
        ..sort((a, b) {
          final aIsDd = _isDigitalDeltaNode(a) ? 0 : 1;
          final bIsDd = _isDigitalDeltaNode(b) ? 0 : 1;
          if (aIsDd != bIsDd) return aIsDd - bIsDd;
          return b.rssi - a.rssi; // stronger signal first
        });

       _scanController.add(sorted.map((r) => BleDeviceModel(
         id: r.id,
         name: BleDisplayName.fromDiscoveredDevice(r),
         rssi: r.rssi,
         isDigitalDeltaNode: _isDigitalDeltaNode(r),
       )).toList());
    }, onError: (Object e) {});

    // Auto stop after 30 sec
    Future.delayed(const Duration(seconds: 30), stopScan);
  }

  @override
  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    _isScanningRaw = false;
    _isScanningController.add(false);
  }

  @override
  Future<void> connect(String deviceId) async {
    fbp.BluetoothDevice? device = _deviceCache[deviceId];
    if (device == null) {
      device = fbp.BluetoothDevice.fromId(deviceId);
      _deviceCache[deviceId] = device;
    }
    await device.connect(license: fbp.License.free, autoConnect: false);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    final device = _deviceCache[deviceId];
    if (device != null) {
      await device.disconnect();
    }
  }

  @override
  Future<List<BleDeviceModel>> getConnectedDevices() async {
    return fbp.FlutterBluePlus.connectedDevices
        .map(
          (d) => BleDeviceModel(
            id: d.remoteId.str,
            name: BleDisplayName.fromConnectedDevice(d),
            rssi: 0,
            connectionState: BleDeviceConnectionState.connected,
          ),
        )
        .toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  BleDeviceConnectionState _mapConnectionState(fbp.BluetoothConnectionState state) {
    return state == fbp.BluetoothConnectionState.connected
        ? BleDeviceConnectionState.connected
        : BleDeviceConnectionState.disconnected;
  }
}
//hfkjashdkf@mail.com
//289e0f1d-20f9-4abd-aed4-f822d6989d76
