import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasource/local/source/connectivity_data_source.dart';
import '../../../di/cache_module.dart';
import '../../../domain/model/connectivity/connectivity_status_model.dart';
import '../state/connectivity_ui_state.dart';

class ConnectivityNotifier extends StateNotifier<ConnectivityUiState> {
  ConnectivityNotifier() : super(const ConnectivityUiState.initial()) {
    _initialize();
  }

  StreamSubscription<ConnectivityStatusModel>? _subscription;

  Future<void> _initialize() async {
    final dataSource = getIt<ConnectivityDataSource>();

    // Determine current status immediately on startup
    final current = await dataSource.currentStatus;
    _applyStatus(current);

    // Stream all future changes
    _subscription = dataSource.onStatusChanged.listen(_applyStatus);
  }

  void _applyStatus(ConnectivityStatusModel status) {
    state = status.when(
      online: (type) => ConnectivityUiState.online(type: type),
      offline: () => const ConnectivityUiState.offline(),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
