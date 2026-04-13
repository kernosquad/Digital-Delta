import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Message model ────────────────────────────────────────────────────────────

class NearbyMessage {
  final String deviceId;
  final String deviceName;
  final String text;
  final bool isMe;
  final DateTime time;

  const NearbyMessage({
    required this.deviceId,
    required this.deviceName,
    required this.text,
    required this.isMe,
    required this.time,
  });
}

// ─── State ────────────────────────────────────────────────────────────────────

class NearbyConnectionsState {
  final bool isRunning;
  final bool isInitializing;
  final List<Device> devices;
  final List<Device> connectedDevices;
  final List<NearbyMessage> messages;
  final String? error;

  const NearbyConnectionsState({
    this.isRunning = false,
    this.isInitializing = false,
    this.devices = const [],
    this.connectedDevices = const [],
    this.messages = const [],
    this.error,
  });

  NearbyConnectionsState copyWith({
    bool? isRunning,
    bool? isInitializing,
    List<Device>? devices,
    List<Device>? connectedDevices,
    List<NearbyMessage>? messages,
    String? error,
    bool clearError = false,
  }) => NearbyConnectionsState(
    isRunning: isRunning ?? this.isRunning,
    isInitializing: isInitializing ?? this.isInitializing,
    devices: devices ?? this.devices,
    connectedDevices: connectedDevices ?? this.connectedDevices,
    messages: messages ?? this.messages,
    error: clearError ? null : (error ?? this.error),
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NearbyConnectionsNotifier extends StateNotifier<NearbyConnectionsState> {
  NearbyConnectionsNotifier() : super(const NearbyConnectionsState());

  final NearbyService _service = NearbyService();
  StreamSubscription? _stateSub;
  StreamSubscription? _dataSub;

  /// deviceId → display name cache (populated from stateChangedSubscription)
  final Map<String, String> _deviceNames = {};

  Future<void> init() async {
    if (state.isRunning || state.isInitializing) return;
    state = state.copyWith(isInitializing: true, clearError: true);

    try {
      await _requestPermissions();
      final deviceName = await _getDeviceName();

      await _service.init(
        serviceType: 'ddelta',
        deviceName: deviceName,
        strategy: Strategy.P2P_CLUSTER,
        // callback fires when the Android background service successfully binds
        callback: (_) async {
          try {
            await _service.stopAdvertisingPeer();
            await _service.stopBrowsingForPeers();
            await Future.delayed(const Duration(milliseconds: 300));
            await _service.startAdvertisingPeer();
            await _service.startBrowsingForPeers();
          } catch (_) {}
        },
      );

      _stateSub = _service.stateChangedSubscription(
        callback: (devicesList) {
          for (final d in devicesList) {
            _deviceNames[d.deviceId] = d.deviceName;
          }

          final connected = devicesList
              .where((d) => d.state == SessionState.connected)
              .toList();

          // On Android stop browsing once connected to conserve battery;
          // resume when the last connection drops.
          if (Platform.isAndroid) {
            if (connected.isNotEmpty) {
              _service.stopBrowsingForPeers();
            } else {
              _service.startBrowsingForPeers();
            }
          }

          if (mounted) {
            state = state.copyWith(
              devices: List.from(devicesList),
              connectedDevices: connected,
            );
          }
        },
      );

      _dataSub = _service.dataReceivedSubscription(
        callback: (data) {
          if (!mounted) return;
          final map = data as Map;
          final deviceId = map['deviceId']?.toString() ?? '';
          final text = map['message']?.toString() ?? '';
          if (text.isEmpty) return;

          final name = _deviceNames[deviceId] ?? deviceId;
          state = state.copyWith(
            messages: [
              ...state.messages,
              NearbyMessage(
                deviceId: deviceId,
                deviceName: name,
                text: text,
                isMe: false,
                time: DateTime.now(),
              ),
            ],
          );
        },
      );

      state = state.copyWith(isRunning: true, isInitializing: false);

      // Fallback: directly start advertising + browsing in case the service
      // binding callback (NEARBY_RUNNING) never fires on this device.
      Future.delayed(const Duration(seconds: 3), () async {
        if (!mounted || !state.isRunning) return;
        try {
          await _service.startAdvertisingPeer();
          await _service.startBrowsingForPeers();
        } catch (_) {}
      });
    } catch (e) {
      state = state.copyWith(isInitializing: false, error: e.toString());
    }
  }

  Future<void> stopAll() async {
    _stateSub?.cancel();
    _dataSub?.cancel();
    try {
      await _service.stopAdvertisingPeer();
      await _service.stopBrowsingForPeers();
    } catch (_) {}
    if (mounted) state = const NearbyConnectionsState();
  }

  void connect(Device device) => _service.invitePeer(
    deviceID: device.deviceId,
    deviceName: device.deviceName,
  );

  void disconnect(Device device) =>
      _service.disconnectPeer(deviceID: device.deviceId);

  /// Send a message to a specific device.
  void sendMessage(String deviceId, String text) {
    if (text.trim().isEmpty) return;
    _service.sendMessage(deviceId, text);
    state = state.copyWith(
      messages: [
        ...state.messages,
        NearbyMessage(
          deviceId: deviceId,
          deviceName: _deviceNames[deviceId] ?? deviceId,
          text: text,
          isMe: true,
          time: DateTime.now(),
        ),
      ],
    );
  }

  /// Broadcast a message to all currently connected devices.
  void sendBroadcast(String text) {
    if (text.trim().isEmpty || state.connectedDevices.isEmpty) return;
    for (final device in state.connectedDevices) {
      _service.sendMessage(device.deviceId, text);
    }
    state = state.copyWith(
      messages: [
        ...state.messages,
        NearbyMessage(
          deviceId: 'broadcast',
          deviceName: 'You',
          text: text,
          isMe: true,
          time: DateTime.now(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _dataSub?.cancel();
    _service.stopAdvertisingPeer();
    _service.stopBrowsingForPeers();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
    if (Platform.isAndroid) {
      permissions.add(Permission.nearbyWifiDevices);
    }
    await permissions.request();
  }

  Future<String> _getDeviceName() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      return (await info.androidInfo).model;
    }
    if (Platform.isIOS) {
      return (await info.iosInfo).localizedModel;
    }
    return 'Unknown Device';
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final nearbyConnectionsProvider =
    StateNotifierProvider<NearbyConnectionsNotifier, NearbyConnectionsState>(
      (ref) => NearbyConnectionsNotifier(),
    );
