import 'dart:async';

import '../../domain/repository/auth_repository.dart';
import '../datasource/local/source/connectivity_data_source.dart';

class AuthSyncManager {
  final AuthRepository _authRepository;
  final ConnectivityDataSource _connectivityDataSource;

  StreamSubscription<dynamic>? _subscription;
  bool _isSyncing = false;

  AuthSyncManager({
    required AuthRepository authRepository,
    required ConnectivityDataSource connectivityDataSource,
  }) : _authRepository = authRepository,
       _connectivityDataSource = connectivityDataSource;

  Future<void> start() async {
    if (_subscription != null) {
      return;
    }

    await syncPendingActions();
    _subscription = _connectivityDataSource.onStatusChanged.listen((status) {
      status.whenOrNull(
        online: (_) {
          unawaited(syncPendingActions());
        },
      );
    });
  }

  Future<void> syncPendingActions() async {
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;
    try {
      await _authRepository.syncPendingActions();
    } finally {
      _isSyncing = false;
    }
  }
}
