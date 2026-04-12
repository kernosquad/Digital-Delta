import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/connectivity_notifier.dart';
import '../state/connectivity_ui_state.dart';

final connectivityNotifierProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityUiState>(
      (ref) => ConnectivityNotifier(),
    );
