import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_response.freezed.dart';
part 'user_response.g.dart';

String _stringFromJson(Object? value) => value?.toString() ?? '';

@freezed
class UserResponse with _$UserResponse {
  const factory UserResponse({
    // ignore: invalid_annotation_target
    @JsonKey(fromJson: _stringFromJson) required String id,
    required String email,
    required String name,
    String? avatar,
    String? phone,
    String? role,
    @Default('active') String status,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'last_seen_at') DateTime? lastSeenAt,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'created_at') DateTime? createdAt,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserResponse;

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);
}
