// Domain models for the MeshCore Module 2/3 BLE integration.

import 'dart:typed_data';

import 'meshcore_protocol.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enumerations
// ─────────────────────────────────────────────────────────────────────────────

enum MeshCoreConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
}

enum MeshCoreMessageStatus { pending, sent, delivered, failed }

// ─────────────────────────────────────────────────────────────────────────────
// MeshCoreContact
// ─────────────────────────────────────────────────────────────────────────────

/// A node on the MeshCore LoRa mesh, discovered via advertisements or contact list.
class MeshCoreContact {
  final Uint8List publicKey;
  final String name;
  final int type; // advTypeChat / advTypeRepeater / advTypeRoom / advTypeSensor
  final int flags;
  final int pathLength; // number of hops (-1 = flood)
  final Uint8List path;
  final DateTime lastSeen;
  final double? latitude;
  final double? longitude;

  const MeshCoreContact({
    required this.publicKey,
    required this.name,
    required this.type,
    required this.flags,
    required this.pathLength,
    required this.path,
    required this.lastSeen,
    this.latitude,
    this.longitude,
  });

  String get publicKeyHex => pubKeyToHex(publicKey);

  /// Short (6 byte) hex prefix for display / matching.
  String get publicKeyShort =>
      publicKeyHex.isNotEmpty ? publicKeyHex.substring(0, 12) : '';

  bool get isFavorite => (flags & contactFlagFavorite) != 0;

  bool get isRepeater => type == advTypeRepeater;
  bool get isRoomServer => type == advTypeRoom;
  bool get isSensor => type == advTypeSensor;
  bool get isChatNode => type == advTypeChat;

  String get typeLabel {
    switch (type) {
      case advTypeRepeater:
        return 'Repeater';
      case advTypeRoom:
        return 'Room Server';
      case advTypeSensor:
        return 'Sensor';
      default:
        return 'Chat';
    }
  }

  String get hopLabel {
    if (pathLength < 0) return 'Flood';
    if (pathLength == 0) return 'Direct';
    return '$pathLength hop${pathLength == 1 ? '' : 's'}';
  }

  MeshCoreContact copyWith({
    String? name,
    int? type,
    int? flags,
    int? pathLength,
    Uint8List? path,
    DateTime? lastSeen,
    double? latitude,
    double? longitude,
  }) {
    return MeshCoreContact(
      publicKey: publicKey,
      name: name ?? this.name,
      type: type ?? this.type,
      flags: flags ?? this.flags,
      pathLength: pathLength ?? this.pathLength,
      path: path ?? this.path,
      lastSeen: lastSeen ?? this.lastSeen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MeshCoreContact && other.publicKeyHex == publicKeyHex;

  @override
  int get hashCode => publicKeyHex.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// MeshCoreMessage
// ─────────────────────────────────────────────────────────────────────────────

/// A direct message exchanged with a [MeshCoreContact].
class MeshCoreMessage {
  final String id; // client-side uuid
  final String peerPublicKeyHex;
  final String text;
  final DateTime timestamp;
  final bool isOutgoing;
  final bool isCli;
  final MeshCoreMessageStatus status;

  const MeshCoreMessage({
    required this.id,
    required this.peerPublicKeyHex,
    required this.text,
    required this.timestamp,
    required this.isOutgoing,
    this.isCli = false,
    required this.status,
  });

  MeshCoreMessage copyWith({MeshCoreMessageStatus? status}) {
    return MeshCoreMessage(
      id: id,
      peerPublicKeyHex: peerPublicKeyHex,
      text: text,
      timestamp: timestamp,
      isOutgoing: isOutgoing,
      isCli: isCli,
      status: status ?? this.status,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MeshCoreDeviceInfo
// ─────────────────────────────────────────────────────────────────────────────

/// Info about the locally connected MeshCore companion radio.
class MeshCoreDeviceInfo {
  final String deviceName; // BLE advertising name
  final String bleRemoteId; // e.g. "AA:BB:CC:DD:EE:FF"
  final Uint8List? selfPublicKey; // from respCodeSelfInfo
  final String selfName;
  final int? batteryMv;
  final double? latitude;
  final double? longitude;

  const MeshCoreDeviceInfo({
    required this.deviceName,
    required this.bleRemoteId,
    this.selfPublicKey,
    this.selfName = '',
    this.batteryMv,
    this.latitude,
    this.longitude,
  });

  String get selfPublicKeyHex =>
      selfPublicKey != null ? pubKeyToHex(selfPublicKey!) : '';

  int get batteryPercent =>
      batteryMv != null ? batteryMvToPercent(batteryMv!) : 0;
}
