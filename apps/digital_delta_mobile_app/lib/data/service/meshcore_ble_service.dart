// MeshCore BLE service — Module 2/3 core implementation.
//
// Handles:
//  • BLE scanning for MeshCore devices (NUS + name prefix filter)
//  • Connect / disconnect lifecycle
//  • Binary frame exchange over NUS (TX notify / RX write)
//  • Frame reassembly for multi-packet payloads
//  • Parsing: device info, contacts, messages, advertisements
//  • Reactive state via StreamControllers (observed by Riverpod providers
//    in the presentation layer)
//
// Architecture note: This service is registered as a singleton in GetIt.
// Screens access state via the Riverpod providers in
// `lib/presentation/screen/meshcore/providers.dart`.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../core/meshcore/meshcore_models.dart';
import '../../core/meshcore/meshcore_protocol.dart';
import '../../core/meshcore/meshcore_uuids.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public event models
// ─────────────────────────────────────────────────────────────────────────────

/// A BLE scan result matching a MeshCore device name prefix.
class MeshCoreScanResult {
  final BluetoothDevice device;
  final String name;
  final int rssi;

  const MeshCoreScanResult({
    required this.device,
    required this.name,
    required this.rssi,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

/// Main service for all MeshCore BLE operations.
///
/// Lifecycle:
///   1. Call [startScan] to discover nearby MeshCore radios.
///   2. Call [connect] with one of the discovered devices.
///   3. Observe [connectionStateStream], [contactsStream], [messagesStream].
///   4. Call [sendMessage] to send a direct text message to a contact.
///   5. Call [disconnect] or wait for the radio to drop the link.
class MeshCoreBleService {
  MeshCoreBleService();

  // ── State ──────────────────────────────────────────────────────────────────

  MeshCoreConnectionState _state = MeshCoreConnectionState.disconnected;
  MeshCoreDeviceInfo? _deviceInfo;
  final List<MeshCoreScanResult> _scanResults = [];
  final List<MeshCoreContact> _contacts = [];
  final Map<String, List<MeshCoreMessage>> _conversations = {};

  // ── BLE handles ───────────────────────────────────────────────────────────

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxChar; // write to device
  BluetoothCharacteristic? _txChar; // notify from device
  StreamSubscription<BluetoothConnectionState>? _connStateSub;
  StreamSubscription<List<int>>? _txSub;
  StreamSubscription<List<ScanResult>>? _scanSub;

  // ── Frame reassembly ─────────────────────────────────────────────────────

  final List<int> _frameBuffer = [];

  // ── Streams ───────────────────────────────────────────────────────────────

  final _stateCtrl = StreamController<MeshCoreConnectionState>.broadcast();
  final _scanCtrl = StreamController<List<MeshCoreScanResult>>.broadcast();
  final _deviceInfoCtrl = StreamController<MeshCoreDeviceInfo?>.broadcast();
  final _contactsCtrl = StreamController<List<MeshCoreContact>>.broadcast();
  final _messagesCtrl =
      StreamController<Map<String, List<MeshCoreMessage>>>.broadcast();

  Stream<MeshCoreConnectionState> get connectionStateStream =>
      _stateCtrl.stream;
  Stream<List<MeshCoreScanResult>> get scanResultsStream => _scanCtrl.stream;
  Stream<MeshCoreDeviceInfo?> get deviceInfoStream => _deviceInfoCtrl.stream;
  Stream<List<MeshCoreContact>> get contactsStream => _contactsCtrl.stream;
  Stream<Map<String, List<MeshCoreMessage>>> get conversationsStream =>
      _messagesCtrl.stream;

  // ── Getters ───────────────────────────────────────────────────────────────

  MeshCoreConnectionState get connectionState => _state;
  bool get isConnected => _state == MeshCoreConnectionState.connected;
  bool get isScanning => _state == MeshCoreConnectionState.scanning;
  MeshCoreDeviceInfo? get deviceInfo => _deviceInfo;
  List<MeshCoreScanResult> get scanResults => List.unmodifiable(_scanResults);
  List<MeshCoreContact> get contacts => List.unmodifiable(_contacts);

  List<MeshCoreMessage> messagesFor(String peerKeyHex) =>
      List.unmodifiable(_conversations[peerKeyHex] ?? []);

  /// Returns the contact matching [keyHex], or null if not found.
  MeshCoreContact? contactByKeyHex(String keyHex) {
    try {
      return _contacts.firstWhere((c) => c.publicKeyHex == keyHex);
    } catch (_) {
      return null;
    }
  }

  /// Convenience alias for [deviceInfo] used by the node graph screen.
  MeshCoreDeviceInfo? get currentDeviceInfo => _deviceInfo;

  // ── Scan ──────────────────────────────────────────────────────────────────

  /// Start BLE scanning. Results are filtered by MeshCore device name prefixes.
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_state == MeshCoreConnectionState.scanning) return;
    if (_state == MeshCoreConnectionState.connected) return;

    if (!await _requestPermissions()) return;

    _scanResults.clear();
    _scanCtrl.add([]);
    _setState(MeshCoreConnectionState.scanning);

    await FlutterBluePlus.stopScan();

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      bool changed = false;
      for (final r in results) {
        // Use platformName first, fall back to advName (same as reference).
        // Many devices only include their name in the scan-response packet,
        // so platformName may be empty until the OS resolves it.
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;
        if (!_isMeshCoreName(name)) continue;
        final existing = _scanResults.indexWhere(
          (s) => s.device.remoteId == r.device.remoteId,
        );
        if (existing >= 0) {
          _scanResults[existing] = MeshCoreScanResult(
            device: r.device,
            name: name,
            rssi: r.rssi,
          );
        } else {
          _scanResults.add(
            MeshCoreScanResult(device: r.device, name: name, rssi: r.rssi),
          );
        }
        changed = true;
      }
      if (changed) _scanCtrl.add(List.unmodifiable(_scanResults));
    });

    await FlutterBluePlus.startScan(
      // withKeywords does partial name matching (OS-level HCI filter).
      // This matches e.g. "MeshCore-1234" against keyword "MeshCore-".
      // withNames requires an exact match and would never match.
      withKeywords: MeshCoreUuids.deviceNamePrefixes,
      timeout: timeout,
      androidScanMode: AndroidScanMode.lowLatency,
    );

    // Reset scanning state when scan finishes
    await Future.delayed(timeout + const Duration(milliseconds: 500));
    if (_state == MeshCoreConnectionState.scanning) {
      _setState(MeshCoreConnectionState.disconnected);
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = null;
    if (_state == MeshCoreConnectionState.scanning) {
      _setState(MeshCoreConnectionState.disconnected);
    }
  }

  // ── Connect ───────────────────────────────────────────────────────────────

  /// Connect to a MeshCore device and start frame exchange.
  Future<void> connect(BluetoothDevice device) async {
    if (_state == MeshCoreConnectionState.connected ||
        _state == MeshCoreConnectionState.connecting) {
      return;
    }

    await stopScan();
    _setState(MeshCoreConnectionState.connecting);

    try {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // Negotiate MTU for larger frames (best-effort)
      try {
        await device.requestMtu(512);
      } catch (_) {
        // MTU negotiation may not be supported on all platforms
      }

      final services = await device.discoverServices();
      final nusService = services.cast<BluetoothService?>().firstWhere(
        (s) =>
            s!.serviceUuid.str.toLowerCase() ==
            MeshCoreUuids.service.toLowerCase(),
        orElse: () => null,
      );

      if (nusService == null) {
        await device.disconnect();
        _setState(MeshCoreConnectionState.disconnected);
        return;
      }

      for (final c in nusService.characteristics) {
        final uuid = c.characteristicUuid.str.toLowerCase();
        if (uuid == MeshCoreUuids.rxCharacteristic.toLowerCase()) {
          _rxChar = c;
        }
        if (uuid == MeshCoreUuids.txCharacteristic.toLowerCase()) {
          _txChar = c;
        }
      }

      if (_rxChar == null || _txChar == null) {
        await device.disconnect();
        _setState(MeshCoreConnectionState.disconnected);
        return;
      }

      // Subscribe to TX notifications
      await _txChar!.setNotifyValue(true);
      _frameBuffer.clear();
      _txSub = _txChar!.onValueReceived.listen(_onBytesReceived);

      _connectedDevice = device;

      // Monitor connection state
      _connStateSub = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      _setState(MeshCoreConnectionState.connected);

      // ── Handshake: identify ourselves then request contacts ──────────
      await _sendFrame(buildAppStartFrame());
      await Future.delayed(const Duration(milliseconds: 200));
      await _sendFrame(buildDeviceQueryFrame());
      await Future.delayed(const Duration(milliseconds: 200));
      // Sync device clock
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _sendFrame(buildSetDeviceTimeFrame(now));
      await Future.delayed(const Duration(milliseconds: 200));
      // Request contacts
      await _sendFrame(buildGetContactsFrame());
      await Future.delayed(const Duration(milliseconds: 300));
      // Request battery
      await _sendFrame(buildGetBattAndStorageFrame());
      // Deliver any queued store-and-forward messages
      await _sendFrame(buildSyncNextMessageFrame());

      _deviceInfo = MeshCoreDeviceInfo(
        deviceName: device.platformName,
        bleRemoteId: device.remoteId.str,
      );
      _deviceInfoCtrl.add(_deviceInfo);
    } catch (_) {
      _setState(MeshCoreConnectionState.disconnected);
      rethrow;
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _setState(MeshCoreConnectionState.disconnecting);
    await _txSub?.cancel();
    _txSub = null;
    await _connStateSub?.cancel();
    _connStateSub = null;
    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _rxChar = null;
    _txChar = null;
    _setState(MeshCoreConnectionState.disconnected);
  }

  void _handleDisconnect() {
    _txSub?.cancel();
    _txSub = null;
    _connStateSub?.cancel();
    _connStateSub = null;
    _connectedDevice = null;
    _rxChar = null;
    _txChar = null;
    _setState(MeshCoreConnectionState.disconnected);
  }

  // ── Send message ──────────────────────────────────────────────────────────

  /// Send a direct text message to [contact].
  Future<void> sendMessage(MeshCoreContact contact, String text) async {
    final id = const Uuid().v4();
    final msg = MeshCoreMessage(
      id: id,
      peerPublicKeyHex: contact.publicKeyHex,
      text: text,
      timestamp: DateTime.now(),
      isOutgoing: true,
      status: MeshCoreMessageStatus.pending,
    );
    _addMessage(msg);

    if (!isConnected) return;

    try {
      final frame = buildSendTextMsgFrame(contact.publicKey, text);
      await _sendFrame(frame);
      _updateMessageStatus(
        id,
        contact.publicKeyHex,
        MeshCoreMessageStatus.sent,
      );
    } catch (_) {
      _updateMessageStatus(
        id,
        contact.publicKeyHex,
        MeshCoreMessageStatus.failed,
      );
    }
  }

  /// Refresh contacts from device.
  Future<void> refreshContacts() async {
    if (!isConnected) return;
    await _sendFrame(buildGetContactsFrame());
  }

  /// Broadcast our own advertisement into the mesh.
  Future<void> sendSelfAdvert({bool flood = false}) async {
    if (!isConnected) return;
    await _sendFrame(buildSendSelfAdvertFrame(flood: flood));
  }

  // ── Frame TX ──────────────────────────────────────────────────────────────

  Future<void> _sendFrame(Uint8List data) async {
    if (_rxChar == null) return;
    final props = _rxChar!.properties;
    final canWrite = props.write || props.writeWithoutResponse;
    if (!canWrite) return;
    // Split into MTU-safe chunks if required (BLE max = negotiated MTU - 3)
    const mtu = 509; // 512 - 3 ATT overhead; safe upper bound post-negotiation
    if (data.length > mtu) {
      for (int i = 0; i < data.length; i += mtu) {
        final end = (i + mtu).clamp(0, data.length);
        await _rxChar!.write(
          data.sublist(i, end).toList(),
          withoutResponse: props.writeWithoutResponse && !props.write,
        );
        await Future.delayed(const Duration(milliseconds: 20));
      }
    } else {
      await _rxChar!.write(
        data.toList(),
        withoutResponse: props.writeWithoutResponse && !props.write,
      );
    }
  }

  // ── Frame RX & parsing ────────────────────────────────────────────────────

  void _onBytesReceived(List<int> bytes) {
    _frameBuffer.addAll(bytes);
    // Frames are delimited by the BLE notification boundary in the NUS spec.
    // Each notification is one logical frame — process immediately.
    _processFrame(Uint8List.fromList(_frameBuffer));
    _frameBuffer.clear();
  }

  void _processFrame(Uint8List frame) {
    if (frame.isEmpty) return;
    final code = frame[0];

    switch (code) {
      case respCodeSelfInfo:
        _handleSelfInfo(frame);
      case respCodeContact:
        _handleContact(frame);
      case respCodeContactsStart:
        _contacts.clear(); // prepare for fresh list
      case respCodeEndOfContacts:
        _contactsCtrl.add(List.unmodifiable(_contacts));
      case respCodeContactMsgRecv:
      case respCodeContactMsgRecvV3:
        _handleIncomingMessage(frame);
      case respCodeBattAndStorage:
        _handleBattery(frame);
      case respCodeDeviceInfo:
        _handleDeviceInfo(frame);
      case pushCodeAdvert:
      case pushCodeNewAdvert:
        _handleAdvert(frame);
      case pushCodeSendConfirmed:
        _handleSendConfirmed(frame);
      case pushCodeMsgWaiting:
        // Device has a queued message for us — pull it
        if (isConnected) {
          unawaited(_sendFrame(buildSyncNextMessageFrame()));
        }
      default:
        break;
    }
  }

  void _handleSelfInfo(Uint8List frame) {
    final result = parseSelfInfoFrame(frame);
    if (result == null) return;
    _deviceInfo = MeshCoreDeviceInfo(
      deviceName: _connectedDevice?.platformName ?? 'MeshCore',
      bleRemoteId: _connectedDevice?.remoteId.str ?? '',
      selfPublicKey: result.pubKey,
      selfName: result.name,
      batteryMv: _deviceInfo?.batteryMv,
      latitude: result.lat,
      longitude: result.lon,
    );
    _deviceInfoCtrl.add(_deviceInfo);
  }

  void _handleContact(Uint8List frame) {
    final result = parseContactFrame(frame);
    if (result == null) return;
    final contact = MeshCoreContact(
      publicKey: result.pubKey,
      name: result.name.isNotEmpty ? result.name : _shortHex(result.pubKey),
      type: result.type,
      flags: result.flags,
      pathLength: result.pathLen == 0xFF ? -1 : result.pathLen,
      path: result.path,
      lastSeen: result.lastSeen,
      latitude: result.lat,
      longitude: result.lon,
    );
    final idx = _contacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    if (idx >= 0) {
      _contacts[idx] = contact;
    } else {
      _contacts.add(contact);
    }
    // Don't push update yet — wait for endOfContacts
  }

  void _handleIncomingMessage(Uint8List frame) {
    final result = parseContactMessageFrame(frame);
    if (result == null) return;
    // Find the matching contact
    final contact = _contacts.cast<MeshCoreContact?>().firstWhere(
      (c) => matchesKeyPrefix(c!.publicKey, result.senderPrefix),
      orElse: () => null,
    );
    final peerKeyHex = contact != null
        ? contact.publicKeyHex
        : pubKeyToHex(result.senderPrefix).padRight(64, '0');

    final msg = MeshCoreMessage(
      id: const Uuid().v4(),
      peerPublicKeyHex: peerKeyHex,
      text: result.text,
      timestamp: result.timestamp,
      isOutgoing: false,
      isCli: result.isCli,
      status: MeshCoreMessageStatus.delivered,
    );
    _addMessage(msg);
  }

  void _handleBattery(Uint8List frame) {
    final mv = parseBatteryFrame(frame);
    if (mv == null || _deviceInfo == null) return;
    _deviceInfo = MeshCoreDeviceInfo(
      deviceName: _deviceInfo!.deviceName,
      bleRemoteId: _deviceInfo!.bleRemoteId,
      selfPublicKey: _deviceInfo!.selfPublicKey,
      selfName: _deviceInfo!.selfName,
      batteryMv: mv,
      latitude: _deviceInfo!.latitude,
      longitude: _deviceInfo!.longitude,
    );
    _deviceInfoCtrl.add(_deviceInfo);
  }

  void _handleDeviceInfo(Uint8List frame) {
    // respCodeDeviceInfo frame: [code][pub_key:32][name:32][...]
    try {
      if (frame.length < 65) return;
      final pubKey = frame.sublist(1, 33);
      final nameBytes = frame.sublist(33, 65);
      final nullIdx = nameBytes.indexWhere((b) => b == 0);
      final name = String.fromCharCodes(
        nullIdx >= 0 ? nameBytes.sublist(0, nullIdx) : nameBytes,
      );
      _deviceInfo = MeshCoreDeviceInfo(
        deviceName: _connectedDevice?.platformName ?? name,
        bleRemoteId: _connectedDevice?.remoteId.str ?? '',
        selfPublicKey: pubKey,
        selfName: name,
        batteryMv: _deviceInfo?.batteryMv,
      );
      _deviceInfoCtrl.add(_deviceInfo);
    } catch (_) {}
  }

  void _handleAdvert(Uint8List frame) {
    final result = parseAdvertFrame(frame);
    if (result == null) return;
    final contact = MeshCoreContact(
      publicKey: result.pubKey,
      name: result.name.isNotEmpty ? result.name : _shortHex(result.pubKey),
      type: result.type,
      flags: 0,
      pathLength: result.pathLen == 0xFF ? -1 : result.pathLen,
      path: result.path,
      lastSeen: DateTime.now(),
      latitude: result.lat,
      longitude: result.lon,
    );
    final idx = _contacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    if (idx >= 0) {
      _contacts[idx] = contact;
    } else {
      _contacts.add(contact);
    }
    _contactsCtrl.add(List.unmodifiable(_contacts));
  }

  void _handleSendConfirmed(Uint8List frame) {
    // pushCodeSendConfirmed: [0x82][ack_hash:4][trip_ms:4]
    // We mark the most recent pending/sent outgoing message as delivered.
    for (final messages in _conversations.values) {
      for (int i = messages.length - 1; i >= 0; i--) {
        if (messages[i].isOutgoing &&
            messages[i].status == MeshCoreMessageStatus.sent) {
          messages[i] = messages[i].copyWith(
            status: MeshCoreMessageStatus.delivered,
          );
          _messagesCtrl.add(Map.unmodifiable(_conversations));
          return;
        }
      }
    }
  }

  // ── Message store helpers ─────────────────────────────────────────────────

  void _addMessage(MeshCoreMessage msg) {
    _conversations.putIfAbsent(msg.peerPublicKeyHex, () => []);
    _conversations[msg.peerPublicKeyHex]!.add(msg);
    _messagesCtrl.add(Map.unmodifiable(_conversations));
  }

  void _updateMessageStatus(
    String id,
    String peerKeyHex,
    MeshCoreMessageStatus status,
  ) {
    final list = _conversations[peerKeyHex];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == id);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(status: status);
    _messagesCtrl.add(Map.unmodifiable(_conversations));
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    final locationStatus = await Permission.locationWhenInUse.request();
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    return locationStatus.isGranted &&
        bluetoothScanStatus.isGranted &&
        bluetoothConnectStatus.isGranted;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isMeshCoreName(String name) {
    if (name.isEmpty) return false;
    for (final prefix in MeshCoreUuids.deviceNamePrefixes) {
      if (name.startsWith(prefix)) return true;
    }
    return false;
  }

  String _shortHex(Uint8List key) => key
      .sublist(0, 3)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();

  void _setState(MeshCoreConnectionState state) {
    _state = state;
    _stateCtrl.add(state);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void dispose() {
    _stateCtrl.close();
    _scanCtrl.close();
    _deviceInfoCtrl.close();
    _contactsCtrl.close();
    _messagesCtrl.close();
    _scanSub?.cancel();
    _txSub?.cancel();
    _connStateSub?.cancel();
  }
}

// ignore: unused_element
void unawaited(Future<void> future) {}
