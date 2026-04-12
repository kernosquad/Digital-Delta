class OperationsSnapshot {
  final OperationsSummary summary;
  final List<InventoryLedgerEntry> inventory;
  final List<CrdtOperationEntry> operations;
  final List<SyncConflictEntry> conflicts;
  final List<MeshNodeEntry> nodes;
  final List<MeshMessageEntry> messages;
  final List<MeshRelayHopEntry> relayLogs;

  const OperationsSnapshot({
    required this.summary,
    required this.inventory,
    required this.operations,
    required this.conflicts,
    required this.nodes,
    required this.messages,
    required this.relayLogs,
  });
}

class OperationsSummary {
  final String localNodeUuid;
  final String localNodeName;
  final bool localNodeRelay;
  final String localRoleReason;
  final int pendingOperations;
  final int syncedOperations;
  final int openConflicts;
  final int nearbyNodes;
  final int relayCapableNodes;
  final int queuedMessages;
  final DateTime? lastSyncAt;
  final Map<String, int> vectorClock;

  const OperationsSummary({
    required this.localNodeUuid,
    required this.localNodeName,
    required this.localNodeRelay,
    required this.localRoleReason,
    required this.pendingOperations,
    required this.syncedOperations,
    required this.openConflicts,
    required this.nearbyNodes,
    required this.relayCapableNodes,
    required this.queuedMessages,
    required this.lastSyncAt,
    required this.vectorClock,
  });
}

class InventoryLedgerEntry {
  final String itemId;
  final String itemName;
  final String locationName;
  final int baseQuantity;
  final int currentQuantity;
  final String priorityClass;
  final int slaHours;
  final Map<String, int> vectorClock;
  final DateTime updatedAt;
  final String? lastOperationUuid;

  const InventoryLedgerEntry({
    required this.itemId,
    required this.itemName,
    required this.locationName,
    required this.baseQuantity,
    required this.currentQuantity,
    required this.priorityClass,
    required this.slaHours,
    required this.vectorClock,
    required this.updatedAt,
    required this.lastOperationUuid,
  });

  int get deltaFromBase => currentQuantity - baseQuantity;

  double get fillRatio {
    if (baseQuantity <= 0) {
      return 0;
    }

    return (currentQuantity / baseQuantity).clamp(0, 1).toDouble();
  }

  bool get isCritical => fillRatio <= 0.35 || priorityClass == 'P0';
}

class CrdtOperationEntry {
  final String operationUuid;
  final String syncNodeUuid;
  final String opType;
  final String entityType;
  final int entityId;
  final String fieldName;
  final Object? oldValue;
  final Object? newValue;
  final Map<String, int> vectorClock;
  final bool isConflicted;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime? syncedAt;

  const CrdtOperationEntry({
    required this.operationUuid,
    required this.syncNodeUuid,
    required this.opType,
    required this.entityType,
    required this.entityId,
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    required this.vectorClock,
    required this.isConflicted,
    required this.isResolved,
    required this.createdAt,
    required this.syncedAt,
  });
}

class SyncConflictEntry {
  final int id;
  final String opAUuid;
  final String opBUuid;
  final String entityType;
  final int entityId;
  final String fieldName;
  final Object? valueA;
  final Object? valueB;
  final String? resolution;
  final Object? resolvedValue;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const SyncConflictEntry({
    required this.id,
    required this.opAUuid,
    required this.opBUuid,
    required this.entityType,
    required this.entityId,
    required this.fieldName,
    required this.valueA,
    required this.valueB,
    required this.resolution,
    required this.resolvedValue,
    required this.resolvedBy,
    required this.resolvedAt,
    required this.createdAt,
  });

  bool get isResolved => resolution != null;
}

class MeshNodeEntry {
  final String nodeUuid;
  final String displayName;
  final String nodeType;
  final String publicKey;
  final double batteryLevel;
  final bool isRelay;
  final DateTime? lastSeenAt;
  final int signalStrength;
  final int proximityMeters;
  final bool isConnected;
  final String roleReason;

  const MeshNodeEntry({
    required this.nodeUuid,
    required this.displayName,
    required this.nodeType,
    required this.publicKey,
    required this.batteryLevel,
    required this.isRelay,
    required this.lastSeenAt,
    required this.signalStrength,
    required this.proximityMeters,
    required this.isConnected,
    required this.roleReason,
  });
}

class MeshMessageEntry {
  final String messageUuid;
  final String senderNodeUuid;
  final String recipientNodeUuid;
  final String messageType;
  final String encryptedPayload;
  final String payloadHash;
  final int ttlHours;
  final int hopCount;
  final int maxHops;
  final bool isDelivered;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? deliveredAt;

  const MeshMessageEntry({
    required this.messageUuid,
    required this.senderNodeUuid,
    required this.recipientNodeUuid,
    required this.messageType,
    required this.encryptedPayload,
    required this.payloadHash,
    required this.ttlHours,
    required this.hopCount,
    required this.maxHops,
    required this.isDelivered,
    required this.createdAt,
    required this.expiresAt,
    required this.deliveredAt,
  });

  Duration get ttlRemaining => expiresAt.difference(DateTime.now());

  String get payloadPreview {
    if (encryptedPayload.length <= 18) {
      return encryptedPayload;
    }

    return '${encryptedPayload.substring(0, 10)}...${encryptedPayload.substring(encryptedPayload.length - 6)}';
  }
}

class MeshRelayHopEntry {
  final int id;
  final String meshMessageUuid;
  final String relayNodeUuid;
  final DateTime relayedAt;

  const MeshRelayHopEntry({
    required this.id,
    required this.meshMessageUuid,
    required this.relayNodeUuid,
    required this.relayedAt,
  });
}

class ChatMessageEntry {
  final int id;
  final String messageUuid;
  final String peerNodeUuid;

  /// 'sent' | 'received'
  final String direction;
  final String content;
  final String encryptedContent;

  /// 'pending' | 'delivered' | 'read'
  final String deliveryStatus;
  final bool isRead;
  final int hopCount;
  final DateTime createdAt;

  const ChatMessageEntry({
    required this.id,
    required this.messageUuid,
    required this.peerNodeUuid,
    required this.direction,
    required this.content,
    required this.encryptedContent,
    required this.deliveryStatus,
    required this.isRead,
    required this.hopCount,
    required this.createdAt,
  });

  bool get isSent => direction == 'sent';
  bool get isDelivered =>
      deliveryStatus == 'delivered' || deliveryStatus == 'read';
  bool get isEncrypted => encryptedContent.isNotEmpty;
}

/// Module 6-style priority copy for inventory rows (SLA windows from problem statement).
String inventoryPriorityDescription(String priorityClass, int slaHours) {
  final tier = switch (priorityClass) {
    'P0' => 'Critical medical',
    'P1' => 'High priority',
    'P2' => 'Standard',
    'P3' => 'Low priority',
    _ => 'Supply',
  };
  return '$tier · SLA ${slaHours}h';
}

extension OperationsSnapshotUi on OperationsSnapshot {
  String labelForNode(String nodeUuid) {
    if (nodeUuid == summary.localNodeUuid) return summary.localNodeName;
    for (final n in nodes) {
      if (n.nodeUuid == nodeUuid) return n.displayName;
    }
    return 'Mesh peer';
  }

  String? inventoryItemNameForEntity(int entityId) {
    for (final inv in inventory) {
      final parsed = int.tryParse(inv.itemId);
      if (parsed == entityId) return inv.itemName;
    }
    return null;
  }

  /// Vector clock with stable node labels (BLE / handset names), not raw UUIDs.
  String get vectorClockHumanReadable {
    final vc = summary.vectorClock;
    if (vc.isEmpty) return 'No causal history yet';

    final entries = vc.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries
        .map((e) => '${labelForNode(e.key)}:${e.value}')
        .join('  ·  ');
  }
}
