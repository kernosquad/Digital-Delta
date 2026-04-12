import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/ble_notifier.dart';
import '../state/ble_ui_state.dart';

final bleNotifierProvider =
    StateNotifierProvider.autoDispose<BleNotifier, BleUiState>(
      (ref) => BleNotifier(),
    );
