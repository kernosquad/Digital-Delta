import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_ui_state.freezed.dart';

@freezed
class AuthUiState with _$AuthUiState {
  const factory AuthUiState.initial() = AuthInitialState;
  const factory AuthUiState.loading() = AuthLoadingState;
  const factory AuthUiState.success() = AuthSuccessState;
  const factory AuthUiState.error(String message) = AuthErrorState;
}
