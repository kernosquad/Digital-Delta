// Riverpod providers for MeshCore BLE screens.
// Imported by all meshcore screens.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/meshcore/meshcore_models.dart';
import '../../../data/service/meshcore_ble_service.dart';
import '../../../di/cache_module.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Service accessor
// ─────────────────────────────────────────────────────────────────────────────

/// Stable reference to the singleton [MeshCoreBleService] from GetIt.
final meshCoreBleServiceProvider = Provider<MeshCoreBleService>(
  (ref) => getIt<MeshCoreBleService>(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Connection state
// ─────────────────────────────────────────────────────────────────────────────

final meshCoreConnectionStateProvider = StreamProvider<MeshCoreConnectionState>(
  (ref) {
    return ref.watch(meshCoreBleServiceProvider).connectionStateStream;
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Scan results
// ─────────────────────────────────────────────────────────────────────────────

final meshCoreScanResultsProvider = StreamProvider<List<MeshCoreScanResult>>((
  ref,
) {
  return ref.watch(meshCoreBleServiceProvider).scanResultsStream;
});

// ─────────────────────────────────────────────────────────────────────────────
// Device info (connected radio's metadata)
// ─────────────────────────────────────────────────────────────────────────────

final meshCoreDeviceInfoProvider = StreamProvider<MeshCoreDeviceInfo?>((ref) {
  return ref.watch(meshCoreBleServiceProvider).deviceInfoStream;
});

// ─────────────────────────────────────────────────────────────────────────────
// Contacts / nodes discovered on the mesh
// ─────────────────────────────────────────────────────────────────────────────

final meshCoreContactsProvider = StreamProvider<List<MeshCoreContact>>((ref) {
  return ref.watch(meshCoreBleServiceProvider).contactsStream;
});

// ─────────────────────────────────────────────────────────────────────────────
// Messages per peer
// ─────────────────────────────────────────────────────────────────────────────

final meshCoreConversationsProvider =
    StreamProvider<Map<String, List<MeshCoreMessage>>>((ref) {
      return ref.watch(meshCoreBleServiceProvider).conversationsStream;
    });

/// Messages for one specific peer (identified by full public key hex).
final meshCorePeerMessagesProvider =
    Provider.family<List<MeshCoreMessage>, String>((ref, peerKeyHex) {
      final svc = ref.watch(meshCoreBleServiceProvider);
      return svc.messagesFor(peerKeyHex);
    });
