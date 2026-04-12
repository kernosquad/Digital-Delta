import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'sync_mesh_service.dart';

const _kServiceId = 'com.digital.delta.mesh';

/// A peer discovered or connected on the ad-hoc mesh.
class MeshPeer {
  final String endpointId;
  String nodeUuid;
  String displayName;
  bool isConnected;

  MeshPeer({
    required this.endpointId,
    required this.nodeUuid,
    required this.displayName,
    this.isConnected = false,
  });
}

/// Emitted whenever an incoming chat message arrives from a peer.
class IncomingChatMessage {
  final String senderNodeUuid;
  final String content;
  final String messageUuid;

  const IncomingChatMessage({
    required this.senderNodeUuid,
    required this.content,
    required this.messageUuid,
  });
}

/// Handles real-time peer discovery and direct messaging using
/// Google Nearby Connections (Android) / Multipeer Connectivity (iOS).
///
/// Usage:
///   1. Call [start] when the mesh screen opens.
///   2. Listen to [peersStream] to update the UI.
///   3. Call [sendChatTo] to send messages.
///   4. Listen to [incomingMessageStream] to receive messages.
///   5. Call [stop] when leaving the screen.
class NearbyMeshService {
  NearbyMeshService({required SyncMeshService syncMeshService})
      : _syncMeshService = syncMeshService;

  final SyncMeshService _syncMeshService;
  final Uuid _uuid = const Uuid();

  // endpointId → MeshPeer
  final Map<String, MeshPeer> _peers = {};

  final _peersController =
      StreamController<List<MeshPeer>>.broadcast();
  final _incomingController =
      StreamController<IncomingChatMessage>.broadcast();

  /// All currently visible peers (discovered + connected).
  Stream<List<MeshPeer>> get peersStream => _peersController.stream;

  /// Fires whenever a chat message arrives from a connected peer.
  Stream<IncomingChatMessage> get incomingMessageStream =>
      _incomingController.stream;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// All currently visible peers as a snapshot list.
  List<MeshPeer> get currentPeers =>
      List.unmodifiable(_peers.values.toList());

  String _localNodeUuid = '';
  String _localDisplayName = 'Digital Delta';

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Start advertising + discovery. Safe to call multiple times.
  Future<void> start({
    required String localNodeUuid,
    required String localDisplayName,
  }) async {
    if (!Platform.isAndroid) return; // iOS: graceful no-op
    if (_isRunning) return;

    _localNodeUuid = localNodeUuid;
    _localDisplayName = localDisplayName;

    if (!await _requestPermissions()) return;

    _isRunning = true;

    // Encode our identity into the advertised name so discoverers can parse
    // our canonical node UUID without a separate handshake round-trip.
    final advertiseName = '$localNodeUuid|$localDisplayName';

    try {
      await Nearby().startAdvertising(
        advertiseName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _kServiceId,
      );
    } catch (_) {
      // Already advertising or unsupported — continue to discovery.
    }

    try {
      await Nearby().startDiscovery(
        advertiseName,
        Strategy.P2P_CLUSTER,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _kServiceId,
      );
    } catch (_) {
      // Already discovering or unsupported.
    }
  }

  /// Stop everything and clean up.
  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
    } catch (_) {}

    for (final peer in _peers.values) {
      if (peer.isConnected) {
        _syncMeshService.markNodeDisconnected(peer.nodeUuid);
      }
    }
    _peers.clear();
    _emitPeers();
  }

  // ── Discovery ────────────────────────────────────────────────────────────

  void _onEndpointFound(
      String endpointId, String endpointName, String serviceId) {
    final peer = _parsePeer(endpointId, endpointName);
    _peers[endpointId] = peer;
    _emitPeers();

    // Auto-connect: request connection to every found peer.
    Nearby()
        .requestConnection(
          '$_localNodeUuid|$_localDisplayName',
          endpointId,
          onConnectionInitiated: _onConnectionInitiated,
          onConnectionResult: _onConnectionResult,
          onDisconnected: _onDisconnected,
        )
        .catchError((_) => false);
  }

  void _onEndpointLost(String? endpointId) {
    if (endpointId == null) return;
    final peer = _peers.remove(endpointId);
    if (peer != null && peer.isConnected) {
      _syncMeshService.markNodeDisconnected(peer.nodeUuid);
    }
    _emitPeers();
  }

  // ── Connection ───────────────────────────────────────────────────────────

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    // A peer is trying to connect to us (advertiser-side). Ensure we have
    // a record for them before accepting.
    _peers.putIfAbsent(
        endpointId, () => _parsePeer(endpointId, info.endpointName));

    Nearby()
        .acceptConnection(
          endpointId,
          onPayLoadRecieved: (id, payload) =>
              _onPayloadReceived(id, payload),
          onPayloadTransferUpdate: (_, __) {},
        )
        .catchError((_) => false);
  }

  void _onConnectionResult(String endpointId, Status status) {
    final peer = _peers[endpointId];
    if (peer == null) return;

    if (status == Status.CONNECTED) {
      peer.isConnected = true;

      // Register in local SQLite so the mesh topology UI shows them.
      _syncMeshService.registerRemoteNode(
        nodeUuid: peer.nodeUuid,
        displayName: peer.displayName,
        publicKey: '',
        batteryLevel: 80,
        signalStrength: -65,
        isConnected: true,
      );

      // Exchange full identity + public key.
      _sendHandshake(endpointId);
      _emitPeers();
    } else {
      _peers.remove(endpointId);
      _emitPeers();
    }
  }

  void _onDisconnected(String endpointId) {
    final peer = _peers.remove(endpointId);
    if (peer != null && peer.isConnected) {
      _syncMeshService.markNodeDisconnected(peer.nodeUuid);
    }
    _emitPeers();
  }

  // ── Payload handling ─────────────────────────────────────────────────────

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;
    try {
      final raw = utf8.decode(payload.bytes!);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      switch (data['type'] as String?) {
        case 'handshake':
          _handleHandshake(endpointId, data);
        case 'chat':
          _handleChat(endpointId, data);
        case 'sync':
          _handleSync(data);
      }
    } catch (_) {}
  }

  void _handleHandshake(String endpointId, Map<String, dynamic> data) {
    final nodeUuid = data['node_uuid'] as String? ?? endpointId;
    final displayName = data['node_name'] as String? ?? 'Unknown';
    final publicKey = data['public_key'] as String? ?? '';
    final battery = (data['battery'] as num?)?.toDouble() ?? 80.0;

    // Update our peer record with the confirmed canonical UUID.
    final peer = _peers[endpointId];
    if (peer != null) {
      peer.nodeUuid = nodeUuid;
      peer.displayName = displayName;
    }

    _syncMeshService.registerRemoteNode(
      nodeUuid: nodeUuid,
      displayName: displayName,
      publicKey: publicKey,
      batteryLevel: battery,
      signalStrength: -65,
      isConnected: true,
    );
    _emitPeers();
  }

  void _handleChat(String endpointId, Map<String, dynamic> data) {
    final messageUuid = data['message_uuid'] as String? ?? _uuid.v4();
    final senderNodeUuid =
        data['sender_id'] as String? ??
        _peers[endpointId]?.nodeUuid ??
        endpointId;
    final content = data['content'] as String? ?? '';
    if (content.isEmpty) return;

    // Persist in SQLite (deduplication handled inside).
    _syncMeshService.receiveChatMessage(
      messageUuid: messageUuid,
      senderNodeUuid: senderNodeUuid,
      content: content,
    );

    // Notify the chat screen directly.
    _incomingController.add(IncomingChatMessage(
      senderNodeUuid: senderNodeUuid,
      content: content,
      messageUuid: messageUuid,
    ));
  }

  void _handleSync(Map<String, dynamic> data) {
    try {
      _syncMeshService.importRemoteDeltas(jsonEncode(data));
    } catch (_) {}
  }

  // ── Sending ──────────────────────────────────────────────────────────────

  /// Send a chat message to [peerNodeUuid].
  /// Returns true if peer was connected and bytes were sent.
  Future<bool> sendChatTo(String peerNodeUuid, String content) async {
    final endpointId = _endpointForNode(peerNodeUuid);
    if (endpointId == null) return false;

    final payload = jsonEncode({
      'type': 'chat',
      'message_uuid': _uuid.v4(),
      'sender_id': _localNodeUuid,
      'sender_name': _localDisplayName,
      'content': content,
    });

    try {
      await Nearby().sendBytesPayload(
        endpointId,
        Uint8List.fromList(utf8.encode(payload)),
      );
      _syncMeshService.markChatDelivered(peerNodeUuid);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether [nodeUuid] currently has an active connection.
  bool isNodeConnected(String nodeUuid) =>
      _peers.values.any((p) => p.nodeUuid == nodeUuid && p.isConnected);

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _sendHandshake(String endpointId) async {
    try {
      final snapshot = await _syncMeshService.loadSnapshot();
      final localNode = snapshot.nodes.firstWhere(
        (n) => n.nodeUuid == snapshot.summary.localNodeUuid,
        orElse: () => snapshot.nodes.first,
      );
      final payload = jsonEncode({
        'type': 'handshake',
        'node_uuid': _localNodeUuid,
        'node_name': _localDisplayName,
        'public_key': localNode.publicKey,
        'battery': localNode.batteryLevel,
      });
      await Nearby().sendBytesPayload(
        endpointId,
        Uint8List.fromList(utf8.encode(payload)),
      );
    } catch (_) {}
  }

  MeshPeer _parsePeer(String endpointId, String endpointName) {
    final idx = endpointName.indexOf('|');
    final nodeUuid =
        idx > 0 ? endpointName.substring(0, idx) : endpointId;
    final displayName =
        idx > 0 ? endpointName.substring(idx + 1) : endpointName;
    return MeshPeer(
      endpointId: endpointId,
      nodeUuid: nodeUuid,
      displayName: displayName,
    );
  }

  String? _endpointForNode(String nodeUuid) {
    for (final entry in _peers.entries) {
      if (entry.value.nodeUuid == nodeUuid && entry.value.isConnected) {
        return entry.key;
      }
    }
    return null;
  }

  Future<bool> _requestPermissions() async {
    final perms = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ];
    final results = await perms.request();
    return results.values.every(
      (s) =>
          s == PermissionStatus.granted || s == PermissionStatus.limited,
    );
  }

  void _emitPeers() =>
      _peersController.add(List.from(_peers.values.toList()));

  void dispose() {
    stop();
    _peersController.close();
    _incomingController.close();
  }
}
