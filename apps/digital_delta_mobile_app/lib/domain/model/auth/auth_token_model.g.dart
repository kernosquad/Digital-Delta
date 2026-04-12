// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_token_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthTokenModelImpl _$$AuthTokenModelImplFromJson(Map<String, dynamic> json) =>
    _$AuthTokenModelImpl(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      isOffline: json['isOffline'] as bool? ?? false,
      needsServerSync: json['needsServerSync'] as bool? ?? false,
    );

Map<String, dynamic> _$$AuthTokenModelImplToJson(
  _$AuthTokenModelImpl instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
  'tokenType': instance.tokenType,
  'expiresIn': instance.expiresIn,
  'user': instance.user,
  'isOffline': instance.isOffline,
  'needsServerSync': instance.needsServerSync,
};
