import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/service/sync_mesh_service.dart';
import '../../../../di/cache_module.dart';
import '../state/operations_ui_state.dart';

class OperationsNotifier extends StateNotifier<OperationsUiState> {
  OperationsNotifier() : super(const OperationsUiState.loading()) {
    _load();
  }

  SyncMeshService get _service => getIt<SyncMeshService>();

  Future<void> _load() async {
    try {
      final snapshot = await _service.loadSnapshot();
      state = OperationsUiState.loaded(snapshot: snapshot);
    } catch (e) {
      state = OperationsUiState.error(e.toString());
    }
  }

  Future<void> refresh() async {
    try {
      final snapshot = await _service.loadSnapshot();
      state = OperationsUiState.loaded(snapshot: snapshot);
    } catch (e) {
      state = OperationsUiState.error(e.toString());
    }
  }

  /// Add a real inventory item via CRDT (M2.1).
  Future<void> addInventoryItem({
    required String itemId,
    required String itemName,
    required String locationName,
    required int baseQuantity,
    required int currentQuantity,
    required String priorityClass,
    required int priorityRank,
    required int slaHours,
  }) async {
    _service.addInventoryItem(
      itemId: itemId,
      itemName: itemName,
      locationName: locationName,
      baseQuantity: baseQuantity,
      currentQuantity: currentQuantity,
      priorityClass: priorityClass,
      priorityRank: priorityRank,
      slaHours: slaHours,
    );
    await refresh();
  }

  /// Create a local CRDT delta mutation on existing inventory (M2.2).
  Future<void> createLocalDelta() async {
    await _service.createLocalInventoryDelta();
    await refresh();
  }

  /// Trigger real delta sync — only marks synced if BLE peers are connected.
  Future<void> triggerSync() async {
    await _service.simulateDeltaSync();
    await refresh();
  }

  /// Resolve a CRDT conflict using the specified strategy (M2.3).
  Future<void> resolveConflict({
    required int conflictId,
    required String resolution,
  }) async {
    await _service.resolveConflict(
      conflictId: conflictId,
      resolution: resolution,
    );
    await refresh();
  }

  /// Queue an encrypted mesh packet for store-and-forward (M3.1).
  Future<void> queueMeshPacket() async {
    await _service.queueEncryptedMeshPacket();
    await refresh();
  }

  /// Relay the next pending mesh message one hop forward (M3.1).
  Future<void> relayNextMessage() async {
    await _service.relayNextMessage();
    await refresh();
  }
}
