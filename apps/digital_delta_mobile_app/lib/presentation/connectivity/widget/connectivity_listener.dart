import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enum/connection_type.dart';
import '../notifier/provider.dart';
import '../state/connectivity_ui_state.dart';
import '../../util/toaster.dart';

/// Wraps the widget tree and reacts to connectivity changes by showing
/// toastification banners. Place this just inside [MaterialApp]'s builder
/// or as the topmost child after navigation setup.
class ConnectivityListener extends ConsumerWidget {
  final Widget child;

  const ConnectivityListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<ConnectivityUiState>(
      connectivityNotifierProvider,
      (previous, current) => _onStateChanged(context, previous, current),
    );

    return child;
  }

  void _onStateChanged(
    BuildContext context,
    ConnectivityUiState? previous,
    ConnectivityUiState current,
  ) {
    // Ignore the very first emission while previous is null (cold start)
    if (previous == null) return;

    // Also skip if previous was initial — do not spam on first real resolution
    final wasInitial = previous.maybeWhen(
      initial: () => true,
      orElse: () => false,
    );

    current.when(
      initial: () {}, // nothing to show
      online: (ConnectionType type) {
        // Only show "back online" if we were previously offline (not initial)
        if (!wasInitial) {
          Toaster.showConnected(context, type);
        }
      },
      offline: () {
        if (!wasInitial) {
          Toaster.showDisconnected(context);
        }
      },
    );
  }
}
