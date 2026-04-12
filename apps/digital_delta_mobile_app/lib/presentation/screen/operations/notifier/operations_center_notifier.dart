import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/service/sync_mesh_service.dart';
import '../../../../di/cache_module.dart';
import '../../../../domain/model/ble/ble_device_model.dart';
import '../../../../domain/model/operations/operations_snapshot_model.dart';

final operationsCenterProvider =
    StateNotifierProvider<OperationsCenterNotifier, OperationsCenterState>(
      (ref) => OperationsCenterNotifier(service: getIt<SyncMeshService>()),
    );

class OperationsCenterNotifier extends StateNotifier<OperationsCenterState> {
  OperationsCenterNotifier({required SyncMeshService service})
    : _service = service,
      super(OperationsCenterState.initial()) {
    refresh();
  }

  final SyncMeshService _service;

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearFeedback: true,
    );

    try {
      final snapshot = await _service.loadSnapshot();
      state = state.copyWith(
        isLoading: false,
        isApplyingAction: false,
        snapshot: snapshot,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isApplyingAction: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> createLocalDelta() async {
    await _runAction(
      action: _service.createLocalInventoryDelta,
      successMessage: 'Local CRDT mutation queued with a new vector clock.',
    );
  }

  Future<void> runDeltaSync() async {
    await _runAction(
      action: _service.simulateDeltaSync,
      successMessage: 'Pending operations were marked as delta-synced.',
    );
  }

  Future<void> resolveConflict({
    required int conflictId,
    required String resolution,
  }) async {
    await _runAction(
      action: () => _service.resolveConflict(
        conflictId: conflictId,
        resolution: resolution,
      ),
      successMessage: 'Conflict resolved using $resolution semantics.',
    );
  }

  Future<void> queueEncryptedPacket() async {
    await _runAction(
      action: _service.queueEncryptedMeshPacket,
      successMessage:
          'Encrypted mesh packet queued for store-and-forward relay.',
    );
  }

  Future<void> relayNextMessage() async {
    await _runAction(
      action: _service.relayNextMessage,
      successMessage: 'Next pending packet advanced one relay hop.',
    );
  }

  Future<void> syncNearbyDevices(List<BleDeviceModel> devices) async {
    try {
      await _service.ingestNearbyDevices(devices);
      final snapshot = await _service.loadSnapshot();
      state = state.copyWith(snapshot: snapshot);
    } catch (_) {
      // Ignore passive BLE ingestion errors so scanning remains responsive.
    }
  }

  Future<void> _runAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    state = state.copyWith(
      isApplyingAction: true,
      clearError: true,
      clearFeedback: true,
    );

    try {
      await action();
      final snapshot = await _service.loadSnapshot();
      state = state.copyWith(
        isApplyingAction: false,
        snapshot: snapshot,
        feedbackMessage: successMessage,
      );
    } catch (error) {
      state = state.copyWith(
        isApplyingAction: false,
        errorMessage: error.toString(),
      );
    }
  }
}

class OperationsCenterState {
  final bool isLoading;
  final bool isApplyingAction;
  final OperationsSnapshot? snapshot;
  final String? feedbackMessage;
  final String? errorMessage;

  const OperationsCenterState({
    required this.isLoading,
    required this.isApplyingAction,
    required this.snapshot,
    required this.feedbackMessage,
    required this.errorMessage,
  });

  factory OperationsCenterState.initial() {
    return const OperationsCenterState(
      isLoading: true,
      isApplyingAction: false,
      snapshot: null,
      feedbackMessage: null,
      errorMessage: null,
    );
  }

  OperationsCenterState copyWith({
    bool? isLoading,
    bool? isApplyingAction,
    OperationsSnapshot? snapshot,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return OperationsCenterState(
      isLoading: isLoading ?? this.isLoading,
      isApplyingAction: isApplyingAction ?? this.isApplyingAction,
      snapshot: snapshot ?? this.snapshot,
      feedbackMessage: clearFeedback
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
