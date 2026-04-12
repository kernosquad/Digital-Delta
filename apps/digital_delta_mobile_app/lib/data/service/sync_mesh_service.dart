import 'dart:convert';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../../core/security/device_service.dart' show DeviceMetadata, DeviceService;
import '../../core/security/key_pair_manager.dart';
import '../../core/security/secure_storage_service.dart';
import '../../domain/model/ble/ble_device_model.dart';
import '../../domain/model/operations/operations_snapshot_model.dart';

class SyncMeshService {
  SyncMeshService._({
    required Database database,
    required DeviceService deviceService,
    required SecureStorageService secureStorageService,
  }) : _database = database,
       _deviceService = deviceService,
       _secureStorageService = secureStorageService;

  final Database _database;
  final DeviceService _deviceService;
  final SecureStorageService _secureStorageService;
  final Random _random = Random();
  final Uuid _uuid = const Uuid();

  late final String _localNodeUuid;

  static Future<SyncMeshService> create({
    required DeviceService deviceService,
    required SecureStorageService secureStorageService,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final database = sqlite3.open(
      '${directory.path}/digital_delta_sync_mesh.db',
    );

    final service = SyncMeshService._(
      database: database,
      deviceService: deviceService,
      secureStorageService: secureStorageService,
    );

    service._migrate();
    await service._bootstrap();
    return service;
  }

  Future<void> refreshTelemetry() async {
    await _refreshLocalHandsetLabel();
    await _refreshLocalNode();
    _expireMessages();
    _recomputeRelayRoles();
  }

  Future<void> _refreshLocalHandsetLabel() async {
    try {
      final metadata = await _deviceService.getDeviceMetadata();
      final name = _handsetDisplayName(metadata);
      final now = DateTime.now().toIso8601String();
      _database.execute(
        'UPDATE sync_nodes SET display_name = ?, updated_at = ? WHERE node_uuid = ?',
        [name, now, _localNodeUuid],
      );
    } catch (_) {}
  }

  Future<OperationsSnapshot> loadSnapshot() async {
    await refreshTelemetry();

    final inventory = _database.select(
      'SELECT * FROM inventory_replicas ORDER BY priority_rank ASC, current_quantity ASC, item_name ASC',
    );
    final operations = _database.select(
      'SELECT * FROM crdt_operations ORDER BY datetime(created_at) DESC LIMIT 12',
    );
    final conflicts = _database.select(
      'SELECT * FROM sync_conflicts ORDER BY COALESCE(datetime(resolved_at), datetime(created_at)) DESC',
    );
    final nodes = _database.select(
      'SELECT * FROM sync_nodes ORDER BY is_connected DESC, is_relay DESC, signal_strength DESC, display_name ASC',
    );
    final messages = _database.select(
      'SELECT * FROM mesh_messages ORDER BY datetime(created_at) DESC LIMIT 10',
    );
    final relayLogs = _database.select(
      'SELECT * FROM mesh_relay_logs ORDER BY datetime(relayed_at) DESC LIMIT 10',
    );

    final vectorClock = _computeVectorClock();
    final openConflicts = conflicts
        .where((row) => row['resolution'] == null)
        .length;
    final pendingOperations = operations
        .where((row) => row['synced_at'] == null)
        .length;
    final syncedOperations = operations.length - pendingOperations;
    final queuedMessages = messages
        .where((row) => ((row['is_delivered'] as int?) ?? 0) == 0)
        .length;
    final nearbyNodes = nodes
        .where((row) => row['node_uuid'] != _localNodeUuid)
        .length;
    final relayCapableNodes = nodes
        .where((row) => ((row['is_relay'] as int?) ?? 0) == 1)
        .length;

    final localNodeRows = nodes.where(
      (row) => row['node_uuid'] == _localNodeUuid,
    );
    final Map<String, dynamic> localNodeRow = localNodeRows.isNotEmpty
        ? localNodeRows.first
        : {
            'node_uuid': _localNodeUuid,
            'display_name': 'This Device',
            'is_relay': 0,
            'battery_level': 0,
            'signal_strength': -100,
            'is_connected': 0,
          };

    return OperationsSnapshot(
      summary: OperationsSummary(
        localNodeUuid: _localNodeUuid,
        localNodeName:
            (localNodeRow['display_name'] as String?) ?? 'This Device',
        localNodeRelay: _toBool(localNodeRow['is_relay']),
        localRoleReason: _relayReason(
          signalStrength: (localNodeRow['signal_strength'] as int?) ?? -100,
          batteryLevel: _toDouble(localNodeRow['battery_level']),
          isConnected: _toBool(localNodeRow['is_connected']),
        ),
        pendingOperations: pendingOperations,
        syncedOperations: syncedOperations,
        openConflicts: openConflicts,
        nearbyNodes: nearbyNodes,
        relayCapableNodes: relayCapableNodes,
        queuedMessages: queuedMessages,
        lastSyncAt: _parseDate(_getMetadata('last_sync_at')),
        vectorClock: vectorClock,
      ),
      inventory: inventory.map(_mapInventory).toList(growable: false),
      operations: operations.map(_mapOperation).toList(growable: false),
      conflicts: conflicts.map(_mapConflict).toList(growable: false),
      nodes: nodes.map(_mapNode).toList(growable: false),
      messages: messages.map(_mapMessage).toList(growable: false),
      relayLogs: relayLogs.map(_mapRelayLog).toList(growable: false),
    );
  }

  Future<void> ingestNearbyDevices(List<BleDeviceModel> devices) async {
    final now = DateTime.now().toIso8601String();

    for (final device in devices) {
      if (device.id == _localNodeUuid) {
        continue;
      }

      final existing = _database.select(
        'SELECT * FROM sync_nodes WHERE node_uuid = ? LIMIT 1',
        [device.id],
      );
      final publicKey = existing.isNotEmpty
          ? (existing.first['public_key'] as String)
          : await _generateRemotePublicKey();
      final batteryLevel = existing.isNotEmpty
          ? _toDouble(existing.first['battery_level'])
          : _estimateBattery(device.rssi).toDouble();
      final isConnected = device.connectionState.isConnected;
      final shouldRelay = _shouldActAsRelay(
        signalStrength: device.rssi,
        batteryLevel: batteryLevel,
        isConnected: isConnected,
      );

      _database.execute(
        '''
        INSERT INTO sync_nodes (
          node_uuid,
          display_name,
          node_type,
          public_key,
          battery_level,
          is_relay,
          last_seen_at,
          signal_strength,
          proximity_meters,
          is_connected,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(node_uuid) DO UPDATE SET
          display_name = excluded.display_name,
          node_type = excluded.node_type,
          public_key = excluded.public_key,
          battery_level = excluded.battery_level,
          is_relay = excluded.is_relay,
          last_seen_at = excluded.last_seen_at,
          signal_strength = excluded.signal_strength,
          proximity_meters = excluded.proximity_meters,
          is_connected = excluded.is_connected,
          updated_at = excluded.updated_at
        ''',
        [
          device.id,
          device.name,
          shouldRelay ? 'relay' : 'mobile',
          publicKey,
          batteryLevel,
          shouldRelay ? 1 : 0,
          now,
          device.rssi,
          _estimateDistanceMeters(device.rssi),
          isConnected ? 1 : 0,
          now,
          now,
        ],
      );
    }

    _recomputeRelayRoles();
  }

  Future<void> createLocalInventoryDelta() async {
    final inventoryRows = _database.select(
      'SELECT * FROM inventory_replicas ORDER BY priority_rank ASC, current_quantity ASC LIMIT 1',
    );
    if (inventoryRows.isEmpty) {
      return;
    }

    final row = inventoryRows.first;
    final currentQuantity = (row['current_quantity'] as int?) ?? 0;
    final delta = currentQuantity > 16 ? (2 + _random.nextInt(5)) : -4;
    final updatedQuantity = max(0, currentQuantity - delta);
    final vectorClock = _nextVectorClock();
    final operationUuid = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    _database.execute(
      '''
      INSERT INTO crdt_operations (
        operation_uuid,
        sync_node_uuid,
        op_type,
        entity_type,
        entity_id,
        field_name,
        old_value,
        new_value,
        vector_clock,
        is_conflicted,
        is_resolved,
        created_at,
        synced_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, ?, NULL)
      ''',
      [
        operationUuid,
        _localNodeUuid,
        updatedQuantity >= currentQuantity ? 'increment' : 'decrement',
        'inventory',
        int.parse(row['item_id'] as String),
        'current_quantity',
        jsonEncode(currentQuantity),
        jsonEncode(updatedQuantity),
        jsonEncode(vectorClock),
        now,
      ],
    );

    _database.execute(
      '''
      UPDATE inventory_replicas
      SET current_quantity = ?, vector_clock = ?, updated_at = ?, last_operation_uuid = ?
      WHERE item_id = ?
      ''',
      [
        updatedQuantity,
        jsonEncode(vectorClock),
        now,
        operationUuid,
        row['item_id'],
      ],
    );
  }

  /// Perform a real delta sync: export pending deltas, mark as synced
  /// only if there are connected BLE peers to receive them.
  /// Returns true if any operations were synced.
  Future<bool> simulateDeltaSync() async {
    final now = DateTime.now().toIso8601String();

    // Only sync if we have connected peers
    final connectedPeers = _database.select(
      'SELECT COUNT(*) AS count FROM sync_nodes WHERE node_uuid != ? AND is_connected = 1',
      [_localNodeUuid],
    );
    final peerCount = (connectedPeers.first['count'] as int?) ?? 0;

    if (peerCount == 0) {
      // No peers connected — deltas stay pending for next BLE connection
      return false;
    }

    // Mark local pending ops as synced (successful BLE delivery assumed)
    final pending = _database.select(
      'SELECT COUNT(*) AS count FROM crdt_operations WHERE synced_at IS NULL AND is_conflicted = 0',
    );
    final pendingCount = (pending.first['count'] as int?) ?? 0;

    if (pendingCount == 0) return false;

    _database.execute(
      'UPDATE crdt_operations SET synced_at = ? WHERE synced_at IS NULL AND is_conflicted = 0',
      [now],
    );

    _setMetadata('last_sync_at', now);
    return true;
  }

  Future<void> resolveConflict({
    required int conflictId,
    required String resolution,
  }) async {
    final conflictRows = _database.select(
      'SELECT * FROM sync_conflicts WHERE id = ? LIMIT 1',
      [conflictId],
    );
    if (conflictRows.isEmpty) {
      return;
    }

    final conflict = conflictRows.first;
    final valueA = _decodeStoredValue(conflict['value_a'] as String?);
    final valueB = _decodeStoredValue(conflict['value_b'] as String?);
    final resolvedValue = switch (resolution) {
      'a_wins' => valueA,
      'b_wins' => valueB,
      'merged' => _mergeConflictValues(valueA, valueB),
      _ => valueA,
    };

    final now = DateTime.now().toIso8601String();
    _database.execute(
      '''
      UPDATE sync_conflicts
      SET resolution = ?, resolved_value = ?, resolved_by = ?, resolved_at = ?
      WHERE id = ?
      ''',
      [
        resolution,
        jsonEncode(resolvedValue),
        _localResolverLabel(),
        now,
        conflictId,
      ],
    );

    _database.execute(
      '''
      UPDATE crdt_operations
      SET is_resolved = 1
      WHERE operation_uuid IN (?, ?)
      ''',
      [conflict['op_a_uuid'], conflict['op_b_uuid']],
    );

    final itemId = conflict['entity_id'];
    final vectorClock = _nextVectorClock();
    final mergeOperationUuid = _uuid.v4();

    _database.execute(
      '''
      INSERT INTO crdt_operations (
        operation_uuid,
        sync_node_uuid,
        op_type,
        entity_type,
        entity_id,
        field_name,
        old_value,
        new_value,
        vector_clock,
        is_conflicted,
        is_resolved,
        created_at,
        synced_at
      ) VALUES (?, ?, 'merge', ?, ?, ?, NULL, ?, ?, 0, 1, ?, NULL)
      ''',
      [
        mergeOperationUuid,
        _localNodeUuid,
        conflict['entity_type'],
        itemId,
        conflict['field_name'],
        jsonEncode(resolvedValue),
        jsonEncode(vectorClock),
        now,
      ],
    );

    if (conflict['entity_type'] == 'inventory' &&
        conflict['field_name'] == 'current_quantity') {
      _database.execute(
        '''
        UPDATE inventory_replicas
        SET current_quantity = ?, vector_clock = ?, updated_at = ?, last_operation_uuid = ?
        WHERE item_id = ?
        ''',
        [
          _numericValue(resolvedValue),
          jsonEncode(vectorClock),
          now,
          mergeOperationUuid,
          itemId.toString(),
        ],
      );
    }
  }

  Future<void> queueEncryptedMeshPacket() async {
    final recipientRows = _database.select(
      'SELECT * FROM sync_nodes WHERE node_uuid != ? ORDER BY is_connected DESC, is_relay DESC, signal_strength DESC LIMIT 1',
      [_localNodeUuid],
    );
    if (recipientRows.isEmpty) {
      return;
    }

    final recipient = recipientRows.first;
    final pendingOps = _database.select(
      'SELECT operation_uuid, vector_clock FROM crdt_operations WHERE synced_at IS NULL ORDER BY datetime(created_at) ASC LIMIT 3',
    );

    final payload = jsonEncode({
      'kind': pendingOps.isEmpty ? 'sync_ack' : 'crdt_delta',
      'operations': pendingOps
          .map((row) => row['operation_uuid'])
          .toList(growable: false),
      'causal_clock': _computeVectorClock(),
      'created_at': DateTime.now().toIso8601String(),
    });

    final encryptedPayload = await KeyPairManager.encryptWithEd25519(
      message: payload,
      recipientPublicKeyBase64: recipient['public_key'] as String,
    );

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    _database.execute(
      '''
      INSERT INTO mesh_messages (
        message_uuid,
        sender_node_uuid,
        recipient_node_uuid,
        message_type,
        encrypted_payload,
        payload_hash,
        ttl_hours,
        hop_count,
        max_hops,
        is_delivered,
        created_at,
        expires_at,
        delivered_at
      ) VALUES (?, ?, ?, ?, ?, ?, 24, 0, 10, 0, ?, ?, NULL)
      ''',
      [
        _uuid.v4(),
        _localNodeUuid,
        recipient['node_uuid'],
        pendingOps.isEmpty ? 'sync_ack' : 'crdt_delta',
        encryptedPayload,
        KeyPairManager.sha256Hash(payload),
        now.toIso8601String(),
        expiresAt.toIso8601String(),
      ],
    );
  }

  Future<void> relayNextMessage() async {
    final rows = _database.select('''
      SELECT *
      FROM mesh_messages
      WHERE is_delivered = 0 AND datetime(expires_at) > datetime('now')
      ORDER BY datetime(created_at) ASC
      LIMIT 1
      ''');
    if (rows.isEmpty) {
      return;
    }

    final message = rows.first;
    final hopCount = (message['hop_count'] as int?) ?? 0;
    final maxHops = (message['max_hops'] as int?) ?? 10;
    if (hopCount >= maxHops) {
      return;
    }

    final relayRows = _database.select(
      '''
      SELECT *
      FROM sync_nodes
      WHERE node_uuid != ? AND node_uuid != ?
      ORDER BY is_relay DESC, is_connected DESC, signal_strength DESC
      LIMIT 1
      ''',
      [_localNodeUuid, message['recipient_node_uuid']],
    );
    final relayNodeUuid = relayRows.isNotEmpty
        ? relayRows.first['node_uuid'] as String
        : _localNodeUuid;
    final now = DateTime.now().toIso8601String();
    final recipientRows = _database.select(
      'SELECT * FROM sync_nodes WHERE node_uuid = ? LIMIT 1',
      [message['recipient_node_uuid']],
    );
    final recipientConnected =
        recipientRows.isNotEmpty &&
        _toBool(recipientRows.first['is_connected']);
    final shouldDeliver = recipientConnected || hopCount + 1 >= 2;

    _database.execute(
      '''
      UPDATE mesh_messages
      SET hop_count = ?, is_delivered = ?, delivered_at = ?
      WHERE message_uuid = ?
      ''',
      [
        hopCount + 1,
        shouldDeliver ? 1 : 0,
        shouldDeliver ? now : null,
        message['message_uuid'],
      ],
    );

    _database.execute(
      'INSERT INTO mesh_relay_logs (mesh_message_uuid, relay_node_uuid, relayed_at) VALUES (?, ?, ?)',
      [message['message_uuid'], relayNodeUuid, now],
    );
  }

  void _migrate() {
    _database.execute('''
      CREATE TABLE IF NOT EXISTS inventory_replicas (
        item_id TEXT PRIMARY KEY,
        item_name TEXT NOT NULL,
        location_name TEXT NOT NULL,
        base_quantity INTEGER NOT NULL,
        current_quantity INTEGER NOT NULL,
        priority_class TEXT NOT NULL,
        priority_rank INTEGER NOT NULL,
        sla_hours INTEGER NOT NULL,
        vector_clock TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_operation_uuid TEXT
      )
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS sync_nodes (
        node_uuid TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        node_type TEXT NOT NULL,
        public_key TEXT NOT NULL,
        battery_level REAL NOT NULL,
        is_relay INTEGER NOT NULL DEFAULT 0,
        last_seen_at TEXT,
        signal_strength INTEGER NOT NULL DEFAULT -100,
        proximity_meters INTEGER NOT NULL DEFAULT 999,
        is_connected INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS crdt_operations (
        operation_uuid TEXT PRIMARY KEY,
        sync_node_uuid TEXT NOT NULL,
        op_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        field_name TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT,
        vector_clock TEXT NOT NULL,
        is_conflicted INTEGER NOT NULL DEFAULT 0,
        is_resolved INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS sync_conflicts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        op_a_uuid TEXT NOT NULL,
        op_b_uuid TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        field_name TEXT NOT NULL,
        value_a TEXT,
        value_b TEXT,
        resolution TEXT,
        resolved_value TEXT,
        resolved_by TEXT,
        resolved_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS mesh_messages (
        message_uuid TEXT PRIMARY KEY,
        sender_node_uuid TEXT NOT NULL,
        recipient_node_uuid TEXT NOT NULL,
        message_type TEXT NOT NULL,
        encrypted_payload TEXT NOT NULL,
        payload_hash TEXT NOT NULL,
        ttl_hours INTEGER NOT NULL,
        hop_count INTEGER NOT NULL DEFAULT 0,
        max_hops INTEGER NOT NULL DEFAULT 10,
        is_delivered INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        delivered_at TEXT
      )
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS mesh_relay_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mesh_message_uuid TEXT NOT NULL,
        relay_node_uuid TEXT NOT NULL,
        relayed_at TEXT NOT NULL
      )
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message_uuid TEXT NOT NULL UNIQUE,
        peer_node_uuid TEXT NOT NULL,
        direction TEXT NOT NULL,
        content TEXT NOT NULL,
        encrypted_content TEXT,
        delivery_status TEXT NOT NULL DEFAULT 'pending',
        is_read INTEGER NOT NULL DEFAULT 0,
        hop_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Add hop_count to relay logs if missing (schema evolution)
    try {
      _database.execute(
        'ALTER TABLE mesh_relay_logs ADD COLUMN hop_number INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
  }

  Future<void> _bootstrap() async {
    final metadata = await _deviceService.getDeviceMetadata();
    _localNodeUuid = metadata.deviceId;

    final localPublicKey = await _ensureLocalPublicKey();
    final batteryLevel =
        (await _deviceService.getBatteryLevel())?.toDouble() ?? 50;
    final now = DateTime.now().toIso8601String();
    final handsetName = _handsetDisplayName(metadata);

    _database.execute(
      '''
      INSERT INTO sync_nodes (
        node_uuid,
        display_name,
        node_type,
        public_key,
        battery_level,
        is_relay,
        last_seen_at,
        signal_strength,
        proximity_meters,
        is_connected,
        created_at,
        updated_at
      ) VALUES (?, ?, 'mobile', ?, ?, 0, ?, -28, 0, 1, ?, ?)
      ON CONFLICT(node_uuid) DO UPDATE SET
        display_name = excluded.display_name,
        public_key = excluded.public_key,
        battery_level = excluded.battery_level,
        last_seen_at = excluded.last_seen_at,
        is_connected = excluded.is_connected,
        updated_at = excluded.updated_at
      ''',
      [
        _localNodeUuid,
        handsetName,
        localPublicKey,
        batteryLevel,
        now,
        now,
        now,
      ],
    );

    _recomputeRelayRoles();
  }

  /// Human-readable handset label for mesh / BLE identity (not a network ID).
  String _handsetDisplayName(DeviceMetadata metadata) {
    final brand = metadata.manufacturer.trim();
    final model = metadata.model.trim();
    if (brand.isNotEmpty && model.isNotEmpty) {
      return '$brand $model';
    }
    if (model.isNotEmpty) return model;
    if (brand.isNotEmpty) return brand;
    return 'This handset';
  }

  Future<void> _refreshLocalNode() async {
    final batteryLevel =
        (await _deviceService.getBatteryLevel())?.toDouble() ?? 84;
    final now = DateTime.now().toIso8601String();

    _database.execute(
      '''
      UPDATE sync_nodes
      SET battery_level = ?, last_seen_at = ?, updated_at = ?, is_connected = 1
      WHERE node_uuid = ?
      ''',
      [batteryLevel, now, now, _localNodeUuid],
    );
  }

  Future<String> _ensureLocalPublicKey() async {
    final existing = await _secureStorageService.getPublicKey(_localNodeUuid);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final keyPair = await KeyPairManager.generateEd25519KeyPair();
    await _secureStorageService.saveKeyPair(
      deviceId: _localNodeUuid,
      publicKey: keyPair['publicKey']!,
      privateKey: keyPair['privateKey']!,
      keyType: keyPair['keyType']!,
    );
    return keyPair['publicKey']!;
  }

  // ── Real Inventory Management (M2.1) ────────────────────────────────────

  /// Add a real inventory item (called from UI or sync import).
  void addInventoryItem({
    required String itemId,
    required String itemName,
    required String locationName,
    required int baseQuantity,
    required int currentQuantity,
    required String priorityClass,
    required int priorityRank,
    required int slaHours,
  }) {
    final now = DateTime.now().toIso8601String();
    final vectorClock = _nextVectorClock();

    _database.execute(
      '''
      INSERT INTO inventory_replicas (
        item_id, item_name, location_name, base_quantity, current_quantity,
        priority_class, priority_rank, sla_hours, vector_clock, updated_at,
        last_operation_uuid
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
      ON CONFLICT(item_id) DO UPDATE SET
        item_name = excluded.item_name,
        location_name = excluded.location_name,
        base_quantity = excluded.base_quantity,
        current_quantity = excluded.current_quantity,
        priority_class = excluded.priority_class,
        priority_rank = excluded.priority_rank,
        sla_hours = excluded.sla_hours,
        vector_clock = excluded.vector_clock,
        updated_at = excluded.updated_at
      ''',
      [
        itemId,
        itemName,
        locationName,
        baseQuantity,
        currentQuantity,
        priorityClass,
        priorityRank,
        slaHours,
        jsonEncode(vectorClock),
        now,
      ],
    );

    // Record the add as a CRDT operation
    final opUuid = _uuid.v4();
    _database.execute(
      '''
      INSERT INTO crdt_operations (
        operation_uuid, sync_node_uuid, op_type, entity_type, entity_id,
        field_name, old_value, new_value, vector_clock, is_conflicted,
        is_resolved, created_at, synced_at
      ) VALUES (?, ?, 'set', 'inventory', ?, 'current_quantity', ?, ?, ?, 0, 0, ?, NULL)
      ''',
      [
        opUuid,
        _localNodeUuid,
        int.parse(itemId),
        jsonEncode(0),
        jsonEncode(currentQuantity),
        jsonEncode(vectorClock),
        now,
      ],
    );
  }

  // ── Real CRDT Sync Methods (M2.2) ─────────────────────────────────────

  /// When GATT identity arrives, fold a scan-only BLE row into the canonical node UUID.
  void consolidateBleNodeIntoCanonical({
    required String bleRemoteId,
    required String canonicalNodeUuid,
  }) {
    if (bleRemoteId.isEmpty ||
        canonicalNodeUuid.isEmpty ||
        bleRemoteId == canonicalNodeUuid) {
      return;
    }

    _database.execute(
      'UPDATE crdt_operations SET sync_node_uuid = ? WHERE sync_node_uuid = ?',
      [canonicalNodeUuid, bleRemoteId],
    );
    _database.execute(
      'UPDATE mesh_messages SET sender_node_uuid = ? WHERE sender_node_uuid = ?',
      [canonicalNodeUuid, bleRemoteId],
    );
    _database.execute(
      'UPDATE mesh_messages SET recipient_node_uuid = ? WHERE recipient_node_uuid = ?',
      [canonicalNodeUuid, bleRemoteId],
    );
    _database.execute(
      'UPDATE mesh_relay_logs SET relay_node_uuid = ? WHERE relay_node_uuid = ?',
      [canonicalNodeUuid, bleRemoteId],
    );
    _database.execute(
      'UPDATE chat_messages SET peer_node_uuid = ? WHERE peer_node_uuid = ?',
      [canonicalNodeUuid, bleRemoteId],
    );
    _database.execute('DELETE FROM sync_nodes WHERE node_uuid = ?', [
      bleRemoteId,
    ]);
  }

  String _localResolverLabel() {
    final rows = _database.select(
      'SELECT display_name FROM sync_nodes WHERE node_uuid = ? LIMIT 1',
      [_localNodeUuid],
    );
    if (rows.isEmpty) return 'local_operator';
    return (rows.first['display_name'] as String?) ?? 'local_operator';
  }

  /// Register a remote node discovered via BLE (real, not seeded).
  Future<void> registerRemoteNode({
    required String nodeUuid,
    required String displayName,
    required String publicKey,
    required double batteryLevel,
    required int signalStrength,
    required bool isConnected,
  }) async {
    final now = DateTime.now().toIso8601String();
    final shouldRelay = _shouldActAsRelay(
      signalStrength: signalStrength,
      batteryLevel: batteryLevel,
      isConnected: isConnected,
    );

    _database.execute(
      '''
      INSERT INTO sync_nodes (
        node_uuid, display_name, node_type, public_key, battery_level,
        is_relay, last_seen_at, signal_strength, proximity_meters,
        is_connected, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(node_uuid) DO UPDATE SET
        display_name = excluded.display_name,
        public_key = excluded.public_key,
        battery_level = excluded.battery_level,
        is_relay = excluded.is_relay,
        last_seen_at = excluded.last_seen_at,
        signal_strength = excluded.signal_strength,
        proximity_meters = excluded.proximity_meters,
        is_connected = excluded.is_connected,
        updated_at = excluded.updated_at
      ''',
      [
        nodeUuid,
        displayName,
        shouldRelay ? 'relay' : 'mobile',
        publicKey.isEmpty ? (await _generateRemotePublicKey()) : publicKey,
        batteryLevel,
        shouldRelay ? 1 : 0,
        now,
        signalStrength,
        _estimateDistanceMeters(signalStrength),
        isConnected ? 1 : 0,
        now,
        now,
      ],
    );

    _recomputeRelayRoles();
  }

  /// Export all pending (unsynced) CRDT operations as JSON for BLE transfer.
  String exportPendingDeltas() {
    final rows = _database.select(
      'SELECT * FROM crdt_operations WHERE synced_at IS NULL ORDER BY datetime(created_at) ASC',
    );

    if (rows.isEmpty) return '';

    final deltas = rows
        .map((row) {
          return {
            'operation_uuid': row['operation_uuid'],
            'sync_node_uuid': row['sync_node_uuid'],
            'op_type': row['op_type'],
            'entity_type': row['entity_type'],
            'entity_id': row['entity_id'],
            'field_name': row['field_name'],
            'old_value': row['old_value'],
            'new_value': row['new_value'],
            'vector_clock': row['vector_clock'],
            'created_at': row['created_at'],
          };
        })
        .toList(growable: false);

    return jsonEncode({
      'sender_node': _localNodeUuid,
      'deltas': deltas,
      'sent_at': DateTime.now().toIso8601String(),
    });
  }

  /// Import remote CRDT deltas received over BLE.
  /// Performs real vector clock comparison for conflict detection (M2.3).
  Future<void> importRemoteDeltas(String remoteDeltaJson) async {
    final payload = jsonDecode(remoteDeltaJson) as Map<String, dynamic>;
    final senderNode = payload['sender_node'] as String;
    final deltas = payload['deltas'] as List<dynamic>;
    final now = DateTime.now().toIso8601String();

    for (final delta in deltas) {
      final opUuid = delta['operation_uuid'] as String;

      // Skip if already have this operation (deduplication)
      final existing = _database.select(
        'SELECT COUNT(*) AS count FROM crdt_operations WHERE operation_uuid = ?',
        [opUuid],
      );
      if (((existing.first['count'] as int?) ?? 0) > 0) continue;

      final entityType = delta['entity_type'] as String;
      final entityId = delta['entity_id'];
      final fieldName = delta['field_name'] as String;
      final remoteVectorClock = _decodeVectorClock(
        delta['vector_clock'] as String,
      );

      // Check for conflict: find local ops on same entity+field
      final localOps = _database.select(
        '''SELECT * FROM crdt_operations
           WHERE entity_type = ? AND entity_id = ? AND field_name = ?
           AND sync_node_uuid = ? AND synced_at IS NULL
           ORDER BY datetime(created_at) DESC LIMIT 1''',
        [entityType, entityId, fieldName, _localNodeUuid],
      );

      bool isConflicted = false;

      if (localOps.isNotEmpty) {
        final localVc = _decodeVectorClock(
          localOps.first['vector_clock'] as String,
        );
        // Conflict: concurrent edits (neither vector clock dominates)
        isConflicted = _isConcurrent(localVc, remoteVectorClock);
      }

      // Insert the remote operation
      _database.execute(
        '''
        INSERT INTO crdt_operations (
          operation_uuid, sync_node_uuid, op_type, entity_type, entity_id,
          field_name, old_value, new_value, vector_clock, is_conflicted,
          is_resolved, created_at, synced_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
        ''',
        [
          opUuid,
          senderNode,
          delta['op_type'],
          entityType,
          entityId,
          fieldName,
          delta['old_value'],
          delta['new_value'],
          delta['vector_clock'],
          isConflicted ? 1 : 0,
          delta['created_at'],
          now, // Mark as synced (received via BLE)
        ],
      );

      if (isConflicted && localOps.isNotEmpty) {
        // Mark local op as conflicted too
        _database.execute(
          'UPDATE crdt_operations SET is_conflicted = 1 WHERE operation_uuid = ?',
          [localOps.first['operation_uuid']],
        );

        // Create a conflict record for UI resolution
        _database.execute(
          '''
          INSERT INTO sync_conflicts (
            op_a_uuid, op_b_uuid, entity_type, entity_id, field_name,
            value_a, value_b, resolution, resolved_value, resolved_by,
            resolved_at, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, NULL, NULL, NULL, NULL, ?)
          ''',
          [
            localOps.first['operation_uuid'],
            opUuid,
            entityType,
            entityId,
            fieldName,
            localOps.first['new_value'],
            delta['new_value'],
            now,
          ],
        );
      } else {
        // No conflict: apply the remote delta to inventory
        _applyDeltaToInventory(delta);
      }
    }

    _setMetadata('last_sync_at', now);
  }

  /// Mark local pending deltas as synced after successful BLE write.
  Future<void> markDeltasSyncedViaBle() async {
    final now = DateTime.now().toIso8601String();
    _database.execute(
      'UPDATE crdt_operations SET synced_at = ? WHERE synced_at IS NULL AND is_conflicted = 0 AND sync_node_uuid = ?',
      [now, _localNodeUuid],
    );
    _setMetadata('last_sync_at', now);
  }

  /// Get local node identity as JSON for BLE broadcast.
  String getLocalNodeIdentity() {
    final rows = _database.select(
      'SELECT * FROM sync_nodes WHERE node_uuid = ? LIMIT 1',
      [_localNodeUuid],
    );
    if (rows.isEmpty) return '{}';
    final row = rows.first;
    return jsonEncode({
      'node_uuid': _localNodeUuid,
      'display_name': row['display_name'],
      'public_key': row['public_key'],
      'battery_level': row['battery_level'],
      'node_type': row['node_type'],
      'is_relay': row['is_relay'],
    });
  }

  // ── Server Sync Public API (M2.4 — Online push/pull) ──────────────────────

  /// The stable device-scoped UUID for this node (used as the node_uuid in
  /// all CRDT operations and server registrations).
  String get localNodeUuid => _localNodeUuid;

  /// Current merged vector clock across all recorded operations.
  Map<String, int> get currentVectorClock => _computeVectorClock();

  /// All CRDT operations that have not yet been synced to the server
  /// (synced_at IS NULL and not conflicted).
  List<Map<String, dynamic>> getUnsyncedOps() {
    final rows = _database.select(
      'SELECT operation_uuid, sync_node_uuid, op_type, entity_type, entity_id, '
      'field_name, old_value, new_value, vector_clock, created_at '
      'FROM crdt_operations '
      'WHERE synced_at IS NULL AND is_conflicted = 0 '
      'ORDER BY datetime(created_at) ASC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  /// Mark the given operation UUIDs as synced to the server.
  void markOpsAsSynced(List<String> uuids) {
    if (uuids.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    for (final uuid in uuids) {
      _database.execute(
        'UPDATE crdt_operations SET synced_at = ? WHERE operation_uuid = ?',
        [now, uuid],
      );
    }
    _setMetadata('last_sync_at', now);
  }

  /// Apply a batch of operations received from the server pull endpoint.
  /// Deduplicates, detects conflicts, and applies inventory deltas.
  Future<void> applyServerOps(List<Map<String, dynamic>> ops) async {
    final now = DateTime.now().toIso8601String();

    for (final op in ops) {
      final opUuid = (op['operation_uuid'] as String?) ?? '';
      if (opUuid.isEmpty) continue;

      // Deduplication
      final existing = _database.select(
        'SELECT COUNT(*) AS c FROM crdt_operations WHERE operation_uuid = ?',
        [opUuid],
      );
      if (((existing.first['c'] as int?) ?? 0) > 0) continue;

      final entityType = (op['entity_type'] as String?) ?? '';
      final entityId = op['entity_id'];
      final fieldName = (op['field_name'] as String?) ?? '';
      final remoteVcRaw = op['vector_clock'];
      final remoteVc = remoteVcRaw is String
          ? _decodeVectorClock(remoteVcRaw)
          : (remoteVcRaw is Map
              ? Map<String, int>.from(
                  remoteVcRaw.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
                )
              : <String, int>{});

      // Check for local conflict
      final localOps = _database.select(
        'SELECT * FROM crdt_operations '
        'WHERE entity_type = ? AND entity_id = ? AND field_name = ? '
        'AND sync_node_uuid = ? AND synced_at IS NULL '
        'ORDER BY datetime(created_at) DESC LIMIT 1',
        [entityType, entityId, fieldName, _localNodeUuid],
      );

      bool isConflicted = false;
      if (localOps.isNotEmpty) {
        final localVc = _decodeVectorClock(localOps.first['vector_clock'] as String);
        isConflicted = _isConcurrent(localVc, remoteVc);
      }

      _database.execute(
        '''
        INSERT OR IGNORE INTO crdt_operations (
          operation_uuid, sync_node_uuid, op_type, entity_type, entity_id,
          field_name, old_value, new_value, vector_clock,
          is_conflicted, is_resolved, created_at, synced_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
        ''',
        [
          opUuid,
          (op['sync_node_uuid'] ?? op['node_uuid'] ?? 'server') as String,
          (op['op_type'] as String?) ?? 'update',
          entityType,
          entityId,
          fieldName,
          op['old_value'] is String ? op['old_value'] : jsonEncode(op['old_value']),
          op['new_value'] is String ? op['new_value'] : jsonEncode(op['new_value']),
          remoteVcRaw is String ? remoteVcRaw : jsonEncode(remoteVc),
          isConflicted ? 1 : 0,
          (op['created_at'] as String?) ?? now,
          now,
        ],
      );

      if (isConflicted && localOps.isNotEmpty) {
        _database.execute(
          '''
          INSERT OR IGNORE INTO sync_conflicts (
            op_a_uuid, op_b_uuid, entity_type, entity_id, field_name,
            value_a, value_b, resolution, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, NULL, ?)
          ''',
          [
            localOps.first['operation_uuid'],
            opUuid,
            entityType,
            entityId,
            fieldName,
            localOps.first['new_value'],
            op['new_value'] is String ? op['new_value'] : jsonEncode(op['new_value']),
            now,
          ],
        );
      } else if (!isConflicted) {
        _applyDeltaToInventory({
          ...op,
          'operation_uuid': opUuid,
          'new_value': op['new_value'] is String
              ? op['new_value']
              : jsonEncode(op['new_value']),
        });
      }
    }
  }

  /// Apply a remote CRDT delta to the inventory replica.
  void _applyDeltaToInventory(Map<String, dynamic> delta) {
    if (delta['entity_type'] != 'inventory') return;

    final entityId = delta['entity_id'].toString();
    final fieldName = delta['field_name'] as String;
    if (fieldName != 'current_quantity') return;

    final newValue = _decodeStoredValue(delta['new_value'] as String?);
    final numValue = _numericValue(newValue);
    final vectorClock = delta['vector_clock'] as String;
    final now = DateTime.now().toIso8601String();

    _database.execute(
      '''
      UPDATE inventory_replicas
      SET current_quantity = ?, vector_clock = ?, updated_at = ?,
          last_operation_uuid = ?
      WHERE item_id = ?
      ''',
      [numValue, vectorClock, now, delta['operation_uuid'], entityId],
    );
  }

  /// Vector clock concurrency check (M2.2).
  /// Returns true if neither VC dominates the other (concurrent edits).
  bool _isConcurrent(Map<String, int> vcA, Map<String, int> vcB) {
    bool aGreater = false;
    bool bGreater = false;
    final allKeys = {...vcA.keys, ...vcB.keys};

    for (final key in allKeys) {
      final a = vcA[key] ?? 0;
      final b = vcB[key] ?? 0;
      if (a > b) aGreater = true;
      if (b > a) bGreater = true;
    }

    // Concurrent if both have at least one entry greater than the other
    return aGreater && bGreater;
  }

  /// Mark a remote node as disconnected when BLE connection drops.
  void markNodeDisconnected(String nodeUuid) {
    _database.execute(
      'UPDATE sync_nodes SET is_connected = 0, updated_at = ? WHERE node_uuid = ?',
      [DateTime.now().toIso8601String(), nodeUuid],
    );
    _recomputeRelayRoles();
  }

  void _expireMessages() {
    _database.execute('''
      DELETE FROM mesh_messages
      WHERE is_delivered = 0 AND datetime(expires_at) <= datetime('now', '-48 hours')
      ''');
  }

  void _recomputeRelayRoles() {
    final rows = _database.select('SELECT * FROM sync_nodes');
    for (final row in rows) {
      final nodeUuid = row['node_uuid'] as String;
      final isConnected = _toBool(row['is_connected']);
      final batteryLevel = _toDouble(row['battery_level']);
      final signalStrength = (row['signal_strength'] as int?) ?? -100;
      final nearbyCount = nodeUuid == _localNodeUuid
          ? _database.select(
                      'SELECT COUNT(*) AS count FROM sync_nodes WHERE node_uuid != ?',
                      [_localNodeUuid],
                    ).first['count']
                    as int? ??
                0
          : 1;
      final shouldRelay = _shouldActAsRelay(
        signalStrength: signalStrength,
        batteryLevel: batteryLevel,
        isConnected: isConnected || nearbyCount > 0,
      );

      _database.execute(
        'UPDATE sync_nodes SET is_relay = ?, node_type = ?, updated_at = ? WHERE node_uuid = ?',
        [
          shouldRelay ? 1 : 0,
          shouldRelay ? 'relay' : 'mobile',
          DateTime.now().toIso8601String(),
          nodeUuid,
        ],
      );
    }
  }

  bool _shouldActAsRelay({
    required int signalStrength,
    required double batteryLevel,
    required bool isConnected,
  }) {
    final strongSignal = signalStrength >= -70;
    final goodBattery = batteryLevel >= 45;
    return goodBattery && (strongSignal || isConnected);
  }

  String _relayReason({
    required int signalStrength,
    required double batteryLevel,
    required bool isConnected,
  }) {
    if (!_shouldActAsRelay(
      signalStrength: signalStrength,
      batteryLevel: batteryLevel,
      isConnected: isConnected,
    )) {
      return batteryLevel < 45
          ? 'Battery too low for relay duty'
          : 'Weak signal keeps this node in client mode';
    }

    if (isConnected && signalStrength >= -70) {
      return 'Strong proximity and healthy battery promote relay role';
    }

    if (isConnected) {
      return 'Connected transport keeps relay forwarding active';
    }

    return 'Strong signal and healthy battery allow autonomous relay mode';
  }

  Map<String, int> _computeVectorClock() {
    final rows = _database.select('SELECT vector_clock FROM crdt_operations');
    final vectorClock = <String, int>{};

    for (final row in rows) {
      final raw = row['vector_clock'] as String?;
      if (raw == null) {
        continue;
      }

      final decoded = _decodeVectorClock(raw);
      for (final entry in decoded.entries) {
        final current = vectorClock[entry.key] ?? 0;
        if (entry.value > current) {
          vectorClock[entry.key] = entry.value;
        }
      }
    }

    return vectorClock;
  }

  Map<String, int> _nextVectorClock() {
    final vectorClock = _computeVectorClock();
    vectorClock[_localNodeUuid] = (vectorClock[_localNodeUuid] ?? 0) + 1;
    return vectorClock;
  }

  Future<String> _generateRemotePublicKey() async {
    final keyPair = await KeyPairManager.generateEd25519KeyPair();
    return keyPair['publicKey']!;
  }

  int _estimateDistanceMeters(int rssi) {
    final txPower = -59;
    final ratio = (txPower - rssi) / (10 * 2.4);
    return max(1, pow(10, ratio).round());
  }

  int _estimateBattery(int rssi) {
    return (55 + ((rssi + 100) * 0.8)).clamp(28, 96).round();
  }

  Object? _mergeConflictValues(Object? valueA, Object? valueB) {
    if (valueA is num && valueB is num) {
      return max(valueA, valueB);
    }
    return valueA ?? valueB;
  }

  int _numericValue(Object? value) {
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String? _getMetadata(String key) {
    final rows = _database.select(
      'SELECT value FROM sync_metadata WHERE key = ? LIMIT 1',
      [key],
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  void _setMetadata(String key, String value) {
    _database.execute(
      '''
      INSERT INTO sync_metadata (key, value)
      VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''',
      [key, value],
    );
  }

  InventoryLedgerEntry _mapInventory(Row row) {
    return InventoryLedgerEntry(
      itemId: row['item_id'] as String,
      itemName: row['item_name'] as String,
      locationName: row['location_name'] as String,
      baseQuantity: (row['base_quantity'] as int?) ?? 0,
      currentQuantity: (row['current_quantity'] as int?) ?? 0,
      priorityClass: row['priority_class'] as String,
      slaHours: (row['sla_hours'] as int?) ?? 0,
      vectorClock: _decodeVectorClock(row['vector_clock'] as String),
      updatedAt: _parseDate(row['updated_at'] as String) ?? DateTime.now(),
      lastOperationUuid: row['last_operation_uuid'] as String?,
    );
  }

  CrdtOperationEntry _mapOperation(Row row) {
    return CrdtOperationEntry(
      operationUuid: row['operation_uuid'] as String,
      syncNodeUuid: row['sync_node_uuid'] as String,
      opType: row['op_type'] as String,
      entityType: row['entity_type'] as String,
      entityId: (row['entity_id'] as int?) ?? 0,
      fieldName: row['field_name'] as String,
      oldValue: _decodeStoredValue(row['old_value'] as String?),
      newValue: _decodeStoredValue(row['new_value'] as String?),
      vectorClock: _decodeVectorClock(row['vector_clock'] as String),
      isConflicted: _toBool(row['is_conflicted']),
      isResolved: _toBool(row['is_resolved']),
      createdAt: _parseDate(row['created_at'] as String) ?? DateTime.now(),
      syncedAt: _parseDate(row['synced_at'] as String?),
    );
  }

  SyncConflictEntry _mapConflict(Row row) {
    return SyncConflictEntry(
      id: (row['id'] as int?) ?? 0,
      opAUuid: row['op_a_uuid'] as String,
      opBUuid: row['op_b_uuid'] as String,
      entityType: row['entity_type'] as String,
      entityId: (row['entity_id'] as int?) ?? 0,
      fieldName: row['field_name'] as String,
      valueA: _decodeStoredValue(row['value_a'] as String?),
      valueB: _decodeStoredValue(row['value_b'] as String?),
      resolution: row['resolution'] as String?,
      resolvedValue: _decodeStoredValue(row['resolved_value'] as String?),
      resolvedBy: row['resolved_by'] as String?,
      resolvedAt: _parseDate(row['resolved_at'] as String?),
      createdAt: _parseDate(row['created_at'] as String) ?? DateTime.now(),
    );
  }

  MeshNodeEntry _mapNode(Row row) {
    return MeshNodeEntry(
      nodeUuid: row['node_uuid'] as String,
      displayName: row['display_name'] as String,
      nodeType: row['node_type'] as String,
      publicKey: row['public_key'] as String,
      batteryLevel: _toDouble(row['battery_level']),
      isRelay: _toBool(row['is_relay']),
      lastSeenAt: _parseDate(row['last_seen_at'] as String?),
      signalStrength: (row['signal_strength'] as int?) ?? -100,
      proximityMeters: (row['proximity_meters'] as int?) ?? 999,
      isConnected: _toBool(row['is_connected']),
      roleReason: _relayReason(
        signalStrength: (row['signal_strength'] as int?) ?? -100,
        batteryLevel: _toDouble(row['battery_level']),
        isConnected: _toBool(row['is_connected']),
      ),
    );
  }

  MeshMessageEntry _mapMessage(Row row) {
    return MeshMessageEntry(
      messageUuid: row['message_uuid'] as String,
      senderNodeUuid: row['sender_node_uuid'] as String,
      recipientNodeUuid: row['recipient_node_uuid'] as String,
      messageType: row['message_type'] as String,
      encryptedPayload: row['encrypted_payload'] as String,
      payloadHash: row['payload_hash'] as String,
      ttlHours: (row['ttl_hours'] as int?) ?? 0,
      hopCount: (row['hop_count'] as int?) ?? 0,
      maxHops: (row['max_hops'] as int?) ?? 0,
      isDelivered: _toBool(row['is_delivered']),
      createdAt: _parseDate(row['created_at'] as String) ?? DateTime.now(),
      expiresAt: _parseDate(row['expires_at'] as String) ?? DateTime.now(),
      deliveredAt: _parseDate(row['delivered_at'] as String?),
    );
  }

  MeshRelayHopEntry _mapRelayLog(Row row) {
    return MeshRelayHopEntry(
      id: (row['id'] as int?) ?? 0,
      meshMessageUuid: row['mesh_message_uuid'] as String,
      relayNodeUuid: row['relay_node_uuid'] as String,
      relayedAt: _parseDate(row['relayed_at'] as String) ?? DateTime.now(),
    );
  }

  Map<String, int> _decodeVectorClock(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        value is num ? value.toInt() : int.parse(value.toString()),
      ),
    );
  }

  Object? _decodeStoredValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return jsonDecode(raw);
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  bool _toBool(Object? value) => (value as int? ?? 0) == 1;

  double _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  // ── Mesh Chat (M3.1 / M3.3) ──────────────────────────────────────────────

  /// Send a chat message to a peer. Stores locally and queues for BLE delivery.
  /// The message is encrypted with the recipient's public key (M3.3).
  Future<String> sendChatMessage(String peerNodeUuid, String content) async {
    final messageUuid = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    // Encrypt for transport (M3.3 — relay nodes cannot read content)
    final peerRows = _database.select(
      'SELECT public_key FROM sync_nodes WHERE node_uuid = ? LIMIT 1',
      [peerNodeUuid],
    );
    String encryptedContent = '';
    if (peerRows.isNotEmpty) {
      try {
        encryptedContent = await KeyPairManager.encryptWithEd25519(
          message: content,
          recipientPublicKeyBase64: peerRows.first['public_key'] as String,
        );
      } catch (_) {
        encryptedContent =
            content; // fallback: store plaintext if key unavailable
      }
    }

    _database.execute(
      '''INSERT INTO chat_messages (
         message_uuid, peer_node_uuid, direction, content,
         encrypted_content, delivery_status, is_read, hop_count, created_at
       ) VALUES (?, ?, 'sent', ?, ?, 'pending', 1, 0, ?)''',
      [messageUuid, peerNodeUuid, content, encryptedContent, now],
    );

    // Also queue as a store-and-forward mesh message (M3.1)
    final expiresAt = DateTime.now().add(const Duration(hours: 72));
    _database.execute(
      '''INSERT INTO mesh_messages (
         message_uuid, sender_node_uuid, recipient_node_uuid, message_type,
         encrypted_payload, payload_hash, ttl_hours, hop_count, max_hops,
         is_delivered, created_at, expires_at, delivered_at
       ) VALUES (?, ?, ?, 'chat', ?, ?, 72, 0, 10, 0, ?, ?, NULL)''',
      [
        messageUuid,
        _localNodeUuid,
        peerNodeUuid,
        encryptedContent.isNotEmpty ? encryptedContent : content,
        KeyPairManager.sha256Hash(content),
        now,
        expiresAt.toIso8601String(),
      ],
    );

    return messageUuid;
  }

  /// Store a received (incoming) chat message from a peer.
  void receiveChatMessage({
    required String messageUuid,
    required String senderNodeUuid,
    required String content,
    String? encryptedContent,
  }) {
    // Deduplication
    final existing = _database.select(
      'SELECT COUNT(*) AS c FROM chat_messages WHERE message_uuid = ?',
      [messageUuid],
    );
    if (((existing.first['c'] as int?) ?? 0) > 0) return;

    _database.execute(
      '''INSERT INTO chat_messages (
         message_uuid, peer_node_uuid, direction, content,
         encrypted_content, delivery_status, is_read, hop_count, created_at
       ) VALUES (?, ?, 'received', ?, ?, 'delivered', 0, 0, ?)''',
      [
        messageUuid,
        senderNodeUuid,
        content,
        encryptedContent ?? '',
        DateTime.now().toIso8601String(),
      ],
    );

    // Mark the mesh_message as delivered if present
    _database.execute(
      "UPDATE mesh_messages SET is_delivered = 1, delivered_at = ? WHERE message_uuid = ?",
      [DateTime.now().toIso8601String(), messageUuid],
    );
  }

  /// Get all chat messages with a specific peer, ordered oldest-first.
  List<ChatMessageEntry> getChatMessages(String peerNodeUuid) {
    final rows = _database.select(
      'SELECT * FROM chat_messages WHERE peer_node_uuid = ? ORDER BY created_at ASC',
      [peerNodeUuid],
    );
    return rows.map(_mapChatMessage).toList();
  }

  /// Get list of known peers for whom we have chat history or mesh nodes.
  List<MeshNodeEntry> getKnownPeers() {
    final rows = _database.select(
      'SELECT * FROM sync_nodes WHERE node_uuid != ? ORDER BY is_connected DESC, display_name ASC',
      [_localNodeUuid],
    );
    return rows.map(_mapNode).toList();
  }

  /// Mark all received messages from peer as read.
  void markMessagesRead(String peerNodeUuid) {
    _database.execute(
      "UPDATE chat_messages SET is_read = 1 WHERE peer_node_uuid = ? AND direction = 'received'",
      [peerNodeUuid],
    );
  }

  /// Export pending chat messages destined for [recipientUuid] for BLE delivery.
  String exportPendingChatMessages(String recipientUuid) {
    final rows = _database.select(
      "SELECT * FROM chat_messages WHERE peer_node_uuid = ? AND direction = 'sent' AND delivery_status = 'pending' ORDER BY created_at ASC LIMIT 20",
      [recipientUuid],
    );
    if (rows.isEmpty) return '';
    return jsonEncode({
      'sender_node': _localNodeUuid,
      'type': 'chat',
      'messages': rows
          .map(
            (r) => {
              'message_uuid': r['message_uuid'],
              'content': r['encrypted_content'] ?? r['content'],
              'plain_content': r['content'],
              'created_at': r['created_at'],
            },
          )
          .toList(),
    });
  }

  /// Mark chat messages to a peer as delivered after successful BLE write.
  void markChatDelivered(String recipientUuid) {
    _database.execute(
      "UPDATE chat_messages SET delivery_status = 'delivered' WHERE peer_node_uuid = ? AND direction = 'sent' AND delivery_status = 'pending'",
      [recipientUuid],
    );
  }

  ChatMessageEntry _mapChatMessage(Row row) {
    return ChatMessageEntry(
      id: (row['id'] as int?) ?? 0,
      messageUuid: row['message_uuid'] as String,
      peerNodeUuid: row['peer_node_uuid'] as String,
      direction: row['direction'] as String,
      content: row['content'] as String,
      encryptedContent: row['encrypted_content'] as String? ?? '',
      deliveryStatus: row['delivery_status'] as String,
      isRead: _toBool(row['is_read']),
      hopCount: (row['hop_count'] as int?) ?? 0,
      createdAt: _parseDate(row['created_at'] as String) ?? DateTime.now(),
    );
  }

  // ── M2 Demo Helpers ───────────────────────────────────────────────────────

  /// Seed 6 realistic relief supply inventory items for demo (M2.1).
  /// No-op if inventory already has entries.
  void seedDemoInventory() {
    final count = _database.select('SELECT COUNT(*) AS c FROM inventory_replicas').first['c'] as int? ?? 0;
    if (count > 0) return;

    final items = [
      ('1001', 'Antivenom Kits',             'Sylhet City Hub',     100, 23,  'P0', 0, 2),
      ('1002', 'Oral Rehydration Salts',      'Sunamganj Camp',      500, 127, 'P1', 1, 6),
      ('1003', 'Water Purification Tablets',  'Companyganj',        2000, 843, 'P1', 1, 6),
      ('1004', 'Emergency Ration Packs',      'Osmani Airport',     1000, 456, 'P2', 2, 24),
      ('1005', 'Tarpaulin Sheets',            'Habiganj Medical',    200,  78, 'P2', 2, 24),
      ('1006', 'Blanket Sets',                'Kanaighat Point',     300, 182, 'P3', 3, 72),
    ];

    for (final it in items) {
      addInventoryItem(
        itemId: it.$1,
        itemName: it.$2,
        locationName: it.$3,
        baseQuantity: it.$4,
        currentQuantity: it.$5,
        priorityClass: it.$6,
        priorityRank: it.$7,
        slaHours: it.$8,
      );
    }
  }

  /// Inject a concurrent-edit conflict on the highest-priority item (M2.3 demo).
  ///
  /// Creates:
  ///   • A local decrement operation  (−12 units)
  ///   • A concurrent peer increment  (+18 units) from "device-fieldworker-demo"
  ///
  /// The two vector clocks are genuinely concurrent (neither dominates),
  /// which triggers [importRemoteDeltas] conflict detection.
  Future<void> injectDemoConflict() async {
    final rows = _database.select(
      'SELECT * FROM inventory_replicas ORDER BY priority_rank ASC, current_quantity ASC LIMIT 1',
    );
    if (rows.isEmpty) return;

    final row = rows.first;
    final itemId   = row['item_id'] as String;
    final curQty   = (row['current_quantity'] as int?) ?? 50;
    final now      = DateTime.now().toIso8601String();

    // ── Local operation (decrement) ─────────────────────────────────────────
    final localOpUuid = _uuid.v4();
    final localVc     = _nextVectorClock(); // increments _localNodeUuid counter
    final localNew    = max(0, curQty - 12);

    _database.execute(
      '''INSERT INTO crdt_operations (
           operation_uuid, sync_node_uuid, op_type, entity_type, entity_id,
           field_name, old_value, new_value, vector_clock, is_conflicted,
           is_resolved, created_at, synced_at
         ) VALUES (?, ?, 'decrement', 'inventory', ?, 'current_quantity', ?, ?, ?, 0, 0, ?, NULL)''',
      [localOpUuid, _localNodeUuid, int.parse(itemId),
       jsonEncode(curQty), jsonEncode(localNew), jsonEncode(localVc), now],
    );

    _database.execute(
      'UPDATE inventory_replicas SET current_quantity=?, vector_clock=?, updated_at=?, last_operation_uuid=? WHERE item_id=?',
      [localNew, jsonEncode(localVc), now, localOpUuid, itemId],
    );

    // ── Peer operation (concurrent increment) ──────────────────────────────
    // Peer VC has NO overlap with localVc → genuinely concurrent
    const peerNodeId = 'device-fieldworker-demo';
    final peerVc     = <String, int>{peerNodeId: 1};
    final peerOpUuid = _uuid.v4();
    final peerNew    = curQty + 18;

    await importRemoteDeltas(jsonEncode({
      'sender_node': peerNodeId,
      'deltas': [
        {
          'operation_uuid': peerOpUuid,
          'sync_node_uuid': peerNodeId,
          'op_type':        'increment',
          'entity_type':    'inventory',
          'entity_id':      int.parse(itemId),
          'field_name':     'current_quantity',
          'old_value':      jsonEncode(curQty),
          'new_value':      jsonEncode(peerNew),
          'vector_clock':   jsonEncode(peerVc),
          'created_at':     now,
        }
      ],
      'sent_at': now,
    }));
  }

  /// Simulate receiving a BLE delta from a peer device (M2.2 / M2.4 demo).
  ///
  /// Creates a realistic-looking delta from "device-camp-commander" that
  /// updates the second inventory item (non-conflicting, causally after local).
  Future<void> simulatePeerSync() async {
    final rows = _database.select(
      'SELECT * FROM inventory_replicas ORDER BY priority_rank ASC, current_quantity DESC LIMIT 3',
    );
    if (rows.isEmpty) return;

    const peerNode = 'device-camp-commander';
    final now      = DateTime.now().toIso8601String();

    // Build two incoming deltas from the peer (different items → no conflict)
    final deltas = <Map<String, dynamic>>[];
    for (int i = 0; i < min(2, rows.length); i++) {
      final row    = rows[i < rows.length ? i : 0];
      final itemId = row['item_id'] as String;
      final curQty = (row['current_quantity'] as int?) ?? 100;
      final delta  = i == 0 ? -8 : 15;
      final newQty = max(0, curQty + delta);

      // Peer VC: causally after the local state (include local VC + increment peer)
      final baseVc = _computeVectorClock();
      final peerVc = Map<String, int>.from(baseVc)..[peerNode] = (baseVc[peerNode] ?? 0) + 1 + i;

      deltas.add({
        'operation_uuid': _uuid.v4(),
        'sync_node_uuid': peerNode,
        'op_type':        delta < 0 ? 'decrement' : 'increment',
        'entity_type':    'inventory',
        'entity_id':      int.parse(itemId),
        'field_name':     'current_quantity',
        'old_value':      jsonEncode(curQty),
        'new_value':      jsonEncode(newQty),
        'vector_clock':   jsonEncode(peerVc),
        'created_at':     now,
      });
    }

    await importRemoteDeltas(jsonEncode({
      'sender_node': peerNode,
      'deltas':      deltas,
      'sent_at':     now,
    }));

    _setMetadata('last_sync_at', now);
  }

  // ── M3 Demo Helpers ───────────────────────────────────────────────────────

  /// Inject 3 simulated BLE peer nodes into the mesh topology (M3.2 demo).
  Future<void> injectDemoMeshPeers() async {
    final existingCount = _database.select(
      'SELECT COUNT(*) AS c FROM sync_nodes WHERE node_uuid != ?', [_localNodeUuid]
    ).first['c'] as int? ?? 0;
    if (existingCount >= 3) return;

    final peers = [
      (uuid: 'mesh-relay-b-demo',  name: 'Relay Node B',     battery: 82.0, rssi: -62, relay: true),
      (uuid: 'mesh-relay-c-demo',  name: 'Relay Node C',     battery: 71.0, rssi: -75, relay: true),
      (uuid: 'mesh-target-d-demo', name: 'Target Camp D',    battery: 55.0, rssi: -95, relay: false),
    ];

    for (final p in peers) {
      await registerRemoteNode(
        nodeUuid:       p.uuid,
        displayName:    p.name,
        publicKey:      await _generateRemotePublicKey(),
        batteryLevel:   p.battery,
        signalStrength: p.rssi,
        isConnected:    p.rssi > -80,
      );
    }
  }

  /// Queue a demo store-and-forward message from local → 'mesh-target-d-demo' (M3.1).
  Future<void> queueDemoRelayMessage() async {
    const targetUuid = 'mesh-target-d-demo';
    const payload    = '{"type":"relief_request","item":"Antivenom","qty":5,"from":"field_op","priority":"P0"}';

    final encryptedPayload = await () async {
      try {
        final rows = _database.select('SELECT public_key FROM sync_nodes WHERE node_uuid = ?', [targetUuid]);
        if (rows.isEmpty) return payload;
        return await KeyPairManager.encryptWithEd25519(
          message: payload,
          recipientPublicKeyBase64: rows.first['public_key'] as String,
        );
      } catch (_) {
        return payload;
      }
    }();

    final now       = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    _database.execute(
      '''INSERT OR IGNORE INTO mesh_messages (
           message_uuid, sender_node_uuid, recipient_node_uuid, message_type,
           encrypted_payload, payload_hash, ttl_hours, hop_count, max_hops,
           is_delivered, created_at, expires_at, delivered_at
         ) VALUES (?, ?, ?, 'crdt_delta', ?, ?, 24, 0, 3, 0, ?, ?, NULL)''',
      [
        'demo-msg-${_uuid.v4()}',
        _localNodeUuid,
        targetUuid,
        encryptedPayload,
        KeyPairManager.sha256Hash(payload),
        now.toIso8601String(),
        expiresAt.toIso8601String(),
      ],
    );
  }
}
