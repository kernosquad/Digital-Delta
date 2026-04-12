import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/auth_notifier.dart';
import '../state/auth_ui_state.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthUiState>(
  (ref) => AuthNotifier(),
);
