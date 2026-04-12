import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../di/cache_module.dart';
import '../../../../domain/enum/ble_connection_state.dart';
import '../../../../domain/model/ble/ble_device_model.dart';
import '../../../../domain/usecase/ble/connect_ble_device_use_case.dart';
import '../../../../domain/usecase/ble/disconnect_ble_device_use_case.dart';
import '../../../../domain/usecase/ble/get_connected_ble_devices_use_case.dart';
import '../../../../domain/usecase/ble/start_ble_scan_use_case.dart';
import '../../../../domain/usecase/ble/stop_ble_scan_use_case.dart';
import '../../../../domain/usecase/ble/watch_ble_connection_state_use_case.dart';
import '../../../../domain/usecase/ble/watch_ble_devices_use_case.dart';
import '../state/ble_ui_state.dart';

class BleNotifier extends StateNotifier<BleUiState> {
  BleNotifier() : super(const BleUiState.initial()) {
    _loadConnectedDevices();
  }

  StreamSubscription<List<BleDeviceModel>>? _scanSub;
  final Map<String, StreamSubscription<BleDeviceConnectionState>> _connSubs =
      {};
  final Map<String, BleDeviceConnectionState> _connStates = {};

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<BleDeviceModel> get _currentDevices => state.when(
    initial: () => [],
    scanning: (d) => d,
    idle: (d) => d,
    error: (_) => [],
  );

  bool get _isScanning =>
      state.maybeWhen(scanning: (_) => true, orElse: () => false);

  void _rebuildState(List<BleDeviceModel> devices) {
    if (_isScanning) {
      state = BleUiState.scanning(devices: devices);
    } else {
      state = BleUiState.idle(devices: devices);
    }
  }

  List<BleDeviceModel> _mergeConnStates(List<BleDeviceModel> incoming) {
    return incoming
        .map(
          (d) => d.copyWith(
            connectionState:
                _connStates[d.id] ?? BleDeviceConnectionState.disconnected,
          ),
        )
        .toList();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    final result = await getIt<StartBleScanUseCase>().call();
    result.when(
      success: (_) {
        state = BleUiState.scanning(devices: _currentDevices);
        _subscribeToScanResults();
      },
      failure: (f) => state = BleUiState.error(f.message),
    );
  }

  Future<void> stopScan() async {
    _scanSub?.cancel();
    _scanSub = null;
    await getIt<StopBleScanUseCase>().call();
    state = BleUiState.idle(devices: _currentDevices);
  }

  Future<void> connect(String deviceId) async {
    _updateDeviceConnectionState(deviceId, BleDeviceConnectionState.connecting);

    // Watch live connection state for this device
    _connSubs[deviceId]?.cancel();
    _connSubs[deviceId] = getIt<WatchBleConnectionStateUseCase>()
        .call(deviceId)
        .listen((s) {
          _connStates[deviceId] = s;
          _updateDeviceConnectionState(deviceId, s);
        });

    final result = await getIt<ConnectBleDeviceUseCase>().call(
      deviceId: deviceId,
    );
    result.when(
      success: (_) {},
      failure: (f) {
        _connStates[deviceId] = BleDeviceConnectionState.disconnected;
        _connSubs[deviceId]?.cancel();
        _connSubs.remove(deviceId);
        _updateDeviceConnectionState(
          deviceId,
          BleDeviceConnectionState.disconnected,
        );
      },
    );
  }

  Future<void> disconnect(String deviceId) async {
    _updateDeviceConnectionState(
      deviceId,
      BleDeviceConnectionState.disconnecting,
    );
    await getIt<DisconnectBleDeviceUseCase>().call(deviceId: deviceId);
    _connStates[deviceId] = BleDeviceConnectionState.disconnected;
    _connSubs[deviceId]?.cancel();
    _connSubs.remove(deviceId);
    _updateDeviceConnectionState(
      deviceId,
      BleDeviceConnectionState.disconnected,
    );
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _subscribeToScanResults() {
    _scanSub?.cancel();
    _scanSub = getIt<WatchBleDevicesUseCase>().call().listen((rawDevices) {
      final merged = _mergeConnStates(rawDevices);
      state = BleUiState.scanning(devices: merged);
    });
  }

  Future<void> _loadConnectedDevices() async {
    final result = await getIt<GetConnectedBleDevicesUseCase>().call();
    result.when(
      success: (devices) {
        if (devices.isNotEmpty) {
          for (final d in devices) {
            _connStates[d.id] = BleDeviceConnectionState.connected;
          }
          state = BleUiState.idle(devices: devices);
        }
      },
      failure: (_) {},
    );
  }

  void _updateDeviceConnectionState(
    String deviceId,
    BleDeviceConnectionState connState,
  ) {
    _connStates[deviceId] = connState;
    final updated = _currentDevices.map((d) {
      if (d.id == deviceId) return d.copyWith(connectionState: connState);
      return d;
    }).toList();
    _rebuildState(updated);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    for (final sub in _connSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
