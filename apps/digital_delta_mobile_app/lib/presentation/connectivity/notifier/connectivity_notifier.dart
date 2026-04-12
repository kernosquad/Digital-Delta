import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasource/local/source/connectivity_data_source.dart';
import '../../../di/cache_module.dart';
import '../../../domain/model/connectivity/connectivity_status_model.dart';
import '../state/connectivity_ui_state.dart';

class ConnectivityNotifier extends StateNotifier<ConnectivityUiState> {
  ConnectivityNotifier() : super(const ConnectivityUiState.initial()) {
    _initialize();
  }

  StreamSubscription<ConnectivityStatusModel>? _subscription;
  bool _bleAutoStarted = false;

  Future<void> _initialize() async {
    final dataSource = getIt<ConnectivityDataSource>();

    // Determine current status immediately on startup
    final current = await dataSource.currentStatus;
    _applyStatus(current);

    // Stream all future changes
    _subscription = dataSource.onStatusChanged.listen(_applyStatus);
  }

  void _applyStatus(ConnectivityStatusModel status) {
    state = status.when(
      online: (type) {
        _bleAutoStarted = false;
        return ConnectivityUiState.online(type: type);
      },
      offline: () {
        // Auto-enable BLE scanning when network goes offline (M2/M3)
        _autoStartBleScan();
        return const ConnectivityUiState.offline();
      },
    );
  }

  /// Automatically turn on BLE and start scanning when offline.
  /// This enables mesh networking (M3) and offline CRDT sync (M2).
  Future<void> _autoStartBleScan() async {
    if (_bleAutoStarted) return;
    _bleAutoStarted = true;

    try {
      // Check if BLE adapter is available and turn it on
      if (await FlutterBluePlus.isSupported) {
        final adapterState = FlutterBluePlus.adapterStateNow;
        if (adapterState != BluetoothAdapterState.on) {
          // On Android, we can request to turn on Bluetooth
          await FlutterBluePlus.turnOn();
        }

        // Start scanning for nearby mesh peers
        if (!FlutterBluePlus.isScanningNow) {
          await FlutterBluePlus.startScan(
            timeout: const Duration(seconds: 30),
            androidScanMode: AndroidScanMode.lowLatency,
          );
        }
      }
    } catch (_) {
      // BLE auto-start failed — user can still manually scan
      _bleAutoStarted = false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
