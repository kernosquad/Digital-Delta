// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_token_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AuthTokenModel _$AuthTokenModelFromJson(Map<String, dynamic> json) {
  return _AuthTokenModel.fromJson(json);
}

/// @nodoc
mixin _$AuthTokenModel {
  String get accessToken => throw _privateConstructorUsedError;
  String get refreshToken => throw _privateConstructorUsedError;
  String get tokenType => throw _privateConstructorUsedError;
  int get expiresIn => throw _privateConstructorUsedError;
  UserModel get user => throw _privateConstructorUsedError;
  bool get isOffline => throw _privateConstructorUsedError;
  bool get needsServerSync => throw _privateConstructorUsedError;

  /// Serializes this AuthTokenModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthTokenModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthTokenModelCopyWith<AuthTokenModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthTokenModelCopyWith<$Res> {
  factory $AuthTokenModelCopyWith(
    AuthTokenModel value,
    $Res Function(AuthTokenModel) then,
  ) = _$AuthTokenModelCopyWithImpl<$Res, AuthTokenModel>;
  @useResult
  $Res call({
    String accessToken,
    String refreshToken,
    String tokenType,
    int expiresIn,
    UserModel user,
    bool isOffline,
    bool needsServerSync,
  });

  $UserModelCopyWith<$Res> get user;
}

/// @nodoc
class _$AuthTokenModelCopyWithImpl<$Res, $Val extends AuthTokenModel>
    implements $AuthTokenModelCopyWith<$Res> {
  _$AuthTokenModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthTokenModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? tokenType = null,
    Object? expiresIn = null,
    Object? user = null,
    Object? isOffline = null,
    Object? needsServerSync = null,
  }) {
    return _then(
      _value.copyWith(
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            refreshToken: null == refreshToken
                ? _value.refreshToken
                : refreshToken // ignore: cast_nullable_to_non_nullable
                      as String,
            tokenType: null == tokenType
                ? _value.tokenType
                : tokenType // ignore: cast_nullable_to_non_nullable
                      as String,
            expiresIn: null == expiresIn
                ? _value.expiresIn
                : expiresIn // ignore: cast_nullable_to_non_nullable
                      as int,
            user: null == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                      as UserModel,
            isOffline: null == isOffline
                ? _value.isOffline
                : isOffline // ignore: cast_nullable_to_non_nullable
                      as bool,
            needsServerSync: null == needsServerSync
                ? _value.needsServerSync
                : needsServerSync // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of AuthTokenModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserModelCopyWith<$Res> get user {
    return $UserModelCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthTokenModelImplCopyWith<$Res>
    implements $AuthTokenModelCopyWith<$Res> {
  factory _$$AuthTokenModelImplCopyWith(
    _$AuthTokenModelImpl value,
    $Res Function(_$AuthTokenModelImpl) then,
  ) = __$$AuthTokenModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accessToken,
    String refreshToken,
    String tokenType,
    int expiresIn,
    UserModel user,
    bool isOffline,
    bool needsServerSync,
  });

  @override
  $UserModelCopyWith<$Res> get user;
}

/// @nodoc
class __$$AuthTokenModelImplCopyWithImpl<$Res>
    extends _$AuthTokenModelCopyWithImpl<$Res, _$AuthTokenModelImpl>
    implements _$$AuthTokenModelImplCopyWith<$Res> {
  __$$AuthTokenModelImplCopyWithImpl(
    _$AuthTokenModelImpl _value,
    $Res Function(_$AuthTokenModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthTokenModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? tokenType = null,
    Object? expiresIn = null,
    Object? user = null,
    Object? isOffline = null,
    Object? needsServerSync = null,
  }) {
    return _then(
      _$AuthTokenModelImpl(
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        refreshToken: null == refreshToken
            ? _value.refreshToken
            : refreshToken // ignore: cast_nullable_to_non_nullable
                  as String,
        tokenType: null == tokenType
            ? _value.tokenType
            : tokenType // ignore: cast_nullable_to_non_nullable
                  as String,
        expiresIn: null == expiresIn
            ? _value.expiresIn
            : expiresIn // ignore: cast_nullable_to_non_nullable
                  as int,
        user: null == user
            ? _value.user
            : user // ignore: cast_nullable_to_non_nullable
                  as UserModel,
        isOffline: null == isOffline
            ? _value.isOffline
            : isOffline // ignore: cast_nullable_to_non_nullable
                  as bool,
        needsServerSync: null == needsServerSync
            ? _value.needsServerSync
            : needsServerSync // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthTokenModelImpl implements _AuthTokenModel {
  const _$AuthTokenModelImpl({
    required this.accessToken,
    this.refreshToken = '',
    this.tokenType = 'Bearer',
    this.expiresIn = 0,
    required this.user,
    this.isOffline = false,
    this.needsServerSync = false,
  });

  factory _$AuthTokenModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthTokenModelImplFromJson(json);

  @override
  final String accessToken;
  @override
  @JsonKey()
  final String refreshToken;
  @override
  @JsonKey()
  final String tokenType;
  @override
  @JsonKey()
  final int expiresIn;
  @override
  final UserModel user;
  @override
  @JsonKey()
  final bool isOffline;
  @override
  @JsonKey()
  final bool needsServerSync;

  @override
  String toString() {
    return 'AuthTokenModel(accessToken: $accessToken, refreshToken: $refreshToken, tokenType: $tokenType, expiresIn: $expiresIn, user: $user, isOffline: $isOffline, needsServerSync: $needsServerSync)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthTokenModelImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(other.tokenType, tokenType) ||
                other.tokenType == tokenType) &&
            (identical(other.expiresIn, expiresIn) ||
                other.expiresIn == expiresIn) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.isOffline, isOffline) ||
                other.isOffline == isOffline) &&
            (identical(other.needsServerSync, needsServerSync) ||
                other.needsServerSync == needsServerSync));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    accessToken,
    refreshToken,
    tokenType,
    expiresIn,
    user,
    isOffline,
    needsServerSync,
  );

  /// Create a copy of AuthTokenModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthTokenModelImplCopyWith<_$AuthTokenModelImpl> get copyWith =>
      __$$AuthTokenModelImplCopyWithImpl<_$AuthTokenModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthTokenModelImplToJson(this);
  }
}

abstract class _AuthTokenModel implements AuthTokenModel {
  const factory _AuthTokenModel({
    required final String accessToken,
    final String refreshToken,
    final String tokenType,
    final int expiresIn,
    required final UserModel user,
    final bool isOffline,
    final bool needsServerSync,
  }) = _$AuthTokenModelImpl;

  factory _AuthTokenModel.fromJson(Map<String, dynamic> json) =
      _$AuthTokenModelImpl.fromJson;

  @override
  String get accessToken;
  @override
  String get refreshToken;
  @override
  String get tokenType;
  @override
  int get expiresIn;
  @override
  UserModel get user;
  @override
  bool get isOffline;
  @override
  bool get needsServerSync;

  /// Create a copy of AuthTokenModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthTokenModelImplCopyWith<_$AuthTokenModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
