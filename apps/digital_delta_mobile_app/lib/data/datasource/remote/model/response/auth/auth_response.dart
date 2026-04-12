import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_response.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'token') required String accessToken,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'token_type') @Default('Bearer') String tokenType,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'expires_in') @Default(0) int expiresIn,
    required UserResponse user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
