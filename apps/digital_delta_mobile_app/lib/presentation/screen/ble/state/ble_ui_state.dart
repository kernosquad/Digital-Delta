import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/model/ble/ble_device_model.dart';

part 'ble_ui_state.freezed.dart';

@freezed
class BleUiState with _$BleUiState {
  /// Initial state before any scan is started.
  const factory BleUiState.initial() = BleInitialState;

  /// A scan is actively running; [devices] accumulates discovered devices.
  const factory BleUiState.scanning({
    @Default([]) List<BleDeviceModel> devices,
  }) = BleScanningState;

  /// Scan stopped; [devices] holds the last discovered list.
  const factory BleUiState.idle({@Default([]) List<BleDeviceModel> devices}) =
      BleIdleState;

  /// An unrecoverable error occurred.
  const factory BleUiState.error(String message) = BleErrorState;
}
