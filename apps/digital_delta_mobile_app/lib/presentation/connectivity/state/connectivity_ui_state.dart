import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/enum/connection_type.dart';

part 'connectivity_ui_state.freezed.dart';

@freezed
class ConnectivityUiState with _$ConnectivityUiState {
  /// App just launched, status not yet determined.
  const factory ConnectivityUiState.initial() = ConnectivityInitialState;

  /// Device has verified internet access.
  const factory ConnectivityUiState.online({required ConnectionType type}) =
      ConnectivityOnlineState;

  /// No internet access — covers no Wi-Fi, no cellular, no Bluetooth, etc.
  const factory ConnectivityUiState.offline() = ConnectivityOfflineState;
}
