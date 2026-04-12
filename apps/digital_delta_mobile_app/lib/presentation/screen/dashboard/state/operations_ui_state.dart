import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/model/operations/operations_snapshot_model.dart';

part 'operations_ui_state.freezed.dart';

@freezed
class OperationsUiState with _$OperationsUiState {
  const factory OperationsUiState.loading() = OperationsLoadingState;
  const factory OperationsUiState.loaded({
    required OperationsSnapshot snapshot,
  }) = OperationsLoadedState;
  const factory OperationsUiState.error(String message) = OperationsErrorState;
}
