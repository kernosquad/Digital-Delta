import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/service/app_data_service.dart';
import '../../../../data/service/sync_remote_api_service.dart';
import '../../../../di/cache_module.dart';
import 'operations_notifier.dart';

final syncHubProvider =
    StateNotifierProvider<SyncHubNotifier, AsyncValue<SyncServerSnapshot>>(
  (ref) => SyncHubNotifier(),
);

/// Coordinates REST `/api/sync/*` metadata with local CRDT via [AppDataService.syncAll].
class SyncHubNotifier extends StateNotifier<AsyncValue<SyncServerSnapshot>> {
  SyncHubNotifier() : super(const AsyncValue.loading()) {
    _loadMeta();
  }

  AppDataService get _appData => getIt<AppDataService>();
  SyncRemoteApiService get _remote => getIt<SyncRemoteApiService>();

  Future<void> _loadMeta() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_remote.fetchServerSnapshot);
  }

  /// CRDT push/pull + refresh local SQLite ops, then re-fetch optional server lists.
  Future<void> syncAllWithBackend(OperationsNotifier operations) async {
    state = const AsyncValue.loading();
    try {
      await _appData.syncAll();
      await operations.refresh();
      final snap = await _remote.fetchServerSnapshot();
      state = AsyncValue.data(snap);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Only reload mesh node / conflict lists from API (no CRDT round-trip).
  Future<void> refreshMetadataOnly() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_remote.fetchServerSnapshot);
  }
}
