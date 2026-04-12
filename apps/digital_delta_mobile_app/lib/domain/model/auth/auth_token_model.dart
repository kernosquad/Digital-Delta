import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_model.dart';

part 'auth_token_model.freezed.dart';
part 'auth_token_model.g.dart';

@freezed
class AuthTokenModel with _$AuthTokenModel {
  const factory AuthTokenModel({
    required String accessToken,
    @Default('') String refreshToken,
    @Default('Bearer') String tokenType,
    @Default(0) int expiresIn,
    required UserModel user,
    @Default(false) bool isOffline,
    @Default(false) bool needsServerSync,
  }) = _AuthTokenModel;

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenModelFromJson(json);
}
