import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/operations_notifier.dart';
import '../state/operations_ui_state.dart';

final operationsNotifierProvider =
    StateNotifierProvider<OperationsNotifier, OperationsUiState>(
      (ref) => OperationsNotifier(),
    );
