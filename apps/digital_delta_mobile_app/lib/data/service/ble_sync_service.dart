import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'sync_mesh_service.dart';

/// Custom GATT service UUID for Digital Delta CRDT sync.
/// Devices advertising this UUID are recognized as mesh peers.
const String kSyncServiceUuid = '0000dd01-0000-1000-8000-00805f9b34fb';

/// Characteristic for exchanging CRDT delta payloads (read/write).
const String kCrdtDeltaCharUuid = '0000dd02-0000-1000-8000-00805f9b34fb';

/// Characteristic for exchanging node identity JSON (read-only).
const String kNodeIdentityCharUuid = '0000dd03-0000-1000-8000-00805f9b34fb';

/// Characteristic for exchanging E2E-encrypted chat messages (read/write, M3.3).
const String kChatCharUuid = '0000dd04-0000-1000-8000-00805f9b34fb';

/// BLE-based CRDT sync service.
///
/// When two Digital Delta devices connect via BLE, this service:
/// 1. Discovers the sync GATT service on the remote device
/// 2. Reads remote node identity (uuid, public key, battery, name)
/// 3. Reads remote pending CRDT deltas from the characteristic
/// 4. Writes our pending CRDT deltas to the remote device
/// 5. Feeds imported deltas into SyncMeshService for conflict detection
///
/// If the remote device doesn't expose the sync service (non-DD device),
/// it's still registered as a BLE node for mesh topology.
class BleSyncService {
  BleSyncService({required SyncMeshService syncMeshService})
    : _syncMeshService = syncMeshService;

  final SyncMeshService _syncMeshService;
  final Set<String> _syncingDevices = {};

  /// Attempt a CRDT delta sync with a connected BLE device.
  ///
  /// Returns true if sync completed successfully, false if the device
  /// does not expose the DD sync service or sync failed.
  Future<bool> syncWithDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;

    // Prevent concurrent syncs with the same device
    if (_syncingDevices.contains(deviceId)) return false;
    _syncingDevices.add(deviceId);

    try {
      // Discover GATT services
      final services = await device.discoverServices();
      final syncService = services
          .where((s) => s.serviceUuid.str.toLowerCase() == kSyncServiceUuid)
          .toList();

      if (syncService.isEmpty) {
        // Not a Digital Delta device — skip CRDT sync but still useful for mesh topology
        return false;
      }

      final service = syncService.first;
      BluetoothCharacteristic? deltaChar;
      BluetoothCharacteristic? identityChar;
      BluetoothCharacteristic? chatChar;

      for (final c in service.characteristics) {
        final uuid = c.characteristicUuid.str.toLowerCase();
        if (uuid == kCrdtDeltaCharUuid) deltaChar = c;
        if (uuid == kNodeIdentityCharUuid) identityChar = c;
        if (uuid == kChatCharUuid) chatChar = c;
      }

      // 1. Read remote node identity
      if (identityChar != null && identityChar.properties.read) {
        try {
          final identityBytes = await identityChar.read();
          if (identityBytes.isNotEmpty) {
            final identity =
                jsonDecode(utf8.decode(identityBytes)) as Map<String, dynamic>;
            final canonical =
                identity['node_uuid'] as String? ?? deviceId;
            if (canonical.isNotEmpty && canonical != deviceId) {
              _syncMeshService.consolidateBleNodeIntoCanonical(
                bleRemoteId: deviceId,
                canonicalNodeUuid: canonical,
              );
            }
            final remoteName = (identity['display_name'] as String?)?.trim();
            final displayName = remoteName != null && remoteName.isNotEmpty
                ? remoteName
                : (device.platformName.trim().isNotEmpty
                      ? device.platformName
                      : 'Mesh peer');
            await _syncMeshService.registerRemoteNode(
              nodeUuid: canonical,
              displayName: displayName,
              publicKey: identity['public_key'] as String? ?? '',
              batteryLevel:
                  (identity['battery_level'] as num?)?.toDouble() ?? 50,
              signalStrength: device.remoteId.str.isNotEmpty ? -60 : -100,
              isConnected: true,
            );
          }
        } catch (_) {
          // Identity read failed — not critical
        }
      }

      // 2. Read remote CRDT deltas
      if (deltaChar != null && deltaChar.properties.read) {
        try {
          final deltaBytes = await deltaChar.read();
          if (deltaBytes.isNotEmpty) {
            final remoteDeltaJson = utf8.decode(deltaBytes);
            await _syncMeshService.importRemoteDeltas(remoteDeltaJson);
          }
        } catch (_) {
          // Delta read failed
        }
      }

      // 3. Write our pending deltas to remote device
      if (deltaChar != null && deltaChar.properties.write) {
        try {
          final localDeltas = _syncMeshService.exportPendingDeltas();
          if (localDeltas.isNotEmpty) {
            final deltaBytes = utf8.encode(localDeltas);
            // BLE characteristics have a max MTU; chunk if needed
            await _writeChunked(deltaChar, deltaBytes);
            // Mark as synced once successfully written
            await _syncMeshService.markDeltasSyncedViaBle();
          }
        } catch (_) {
          // Write failed — deltas stay pending for next sync attempt
        }
      }

      // 4. Exchange chat messages (M3.1 / M3.3)
      // Read remote pending chat messages directed at us
      if (chatChar != null && chatChar.properties.read) {
        try {
          final chatBytes = await chatChar.read();
          if (chatBytes.isNotEmpty) {
            final chatJson = utf8.decode(chatBytes);
            _importRemoteChatMessages(chatJson);
          }
        } catch (_) {}
      }
      // Write our pending chat messages to remote
      if (chatChar != null && chatChar.properties.write) {
        try {
          final chatJson = _syncMeshService.exportPendingChatMessages(deviceId);
          if (chatJson.isNotEmpty) {
            await _writeChunked(chatChar, utf8.encode(chatJson));
            _syncMeshService.markChatDelivered(deviceId);
          }
        } catch (_) {}
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      _syncingDevices.remove(deviceId);
    }
  }

  /// Write data in chunks respecting BLE MTU limits (~512 bytes typical).
  Future<void> _writeChunked(
    BluetoothCharacteristic characteristic,
    List<int> data,
  ) async {
    const chunkSize = 512;
    for (var offset = 0; offset < data.length; offset += chunkSize) {
      final end = (offset + chunkSize > data.length)
          ? data.length
          : offset + chunkSize;
      await characteristic.write(
        data.sublist(offset, end),
        withoutResponse: characteristic.properties.writeWithoutResponse,
      );
    }
  }

  /// Parse and store incoming chat messages received from a BLE peer.
  void _importRemoteChatMessages(String chatJson) {
    try {
      final payload = jsonDecode(chatJson) as Map<String, dynamic>;
      if (payload['type'] != 'chat') return;
      final senderNode = payload['sender_node'] as String;
      final messages = payload['messages'] as List<dynamic>;
      for (final msg in messages) {
        _syncMeshService.receiveChatMessage(
          messageUuid: msg['message_uuid'] as String,
          senderNodeUuid: senderNode,
          content: msg['plain_content'] as String? ?? msg['content'] as String,
          encryptedContent: msg['content'] as String?,
        );
      }
    } catch (_) {}
  }
}
