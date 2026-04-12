// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Failure {
  String get message => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int statusCode, dynamic data)
    serverException,
    required TResult Function(String message) connectionException,
    required TResult Function(String message) unauthorizedException,
    required TResult Function(String message, Map<String, List<String>>? errors)
    validationException,
    required TResult Function(String message) unknownException,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult? Function(String message)? connectionException,
    TResult? Function(String message)? unauthorizedException,
    TResult? Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult? Function(String message)? unknownException,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult Function(String message)? connectionException,
    TResult Function(String message)? unauthorizedException,
    TResult Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult Function(String message)? unknownException,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) serverException,
    required TResult Function(ConnectionException value) connectionException,
    required TResult Function(UnauthorizedException value)
    unauthorizedException,
    required TResult Function(ValidationException value) validationException,
    required TResult Function(UnknownException value) unknownException,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? serverException,
    TResult? Function(ConnectionException value)? connectionException,
    TResult? Function(UnauthorizedException value)? unauthorizedException,
    TResult? Function(ValidationException value)? validationException,
    TResult? Function(UnknownException value)? unknownException,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? serverException,
    TResult Function(ConnectionException value)? connectionException,
    TResult Function(UnauthorizedException value)? unauthorizedException,
    TResult Function(ValidationException value)? validationException,
    TResult Function(UnknownException value)? unknownException,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FailureCopyWith<Failure> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FailureCopyWith<$Res> {
  factory $FailureCopyWith(Failure value, $Res Function(Failure) then) =
      _$FailureCopyWithImpl<$Res, Failure>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$FailureCopyWithImpl<$Res, $Val extends Failure>
    implements $FailureCopyWith<$Res> {
  _$FailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServerExceptionImplCopyWith<$Res>
    implements $FailureCopyWith<$Res> {
  factory _$$ServerExceptionImplCopyWith(
    _$ServerExceptionImpl value,
    $Res Function(_$ServerExceptionImpl) then,
  ) = __$$ServerExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, int statusCode, dynamic data});
}

/// @nodoc
class __$$ServerExceptionImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ServerExceptionImpl>
    implements _$$ServerExceptionImplCopyWith<$Res> {
  __$$ServerExceptionImplCopyWithImpl(
    _$ServerExceptionImpl _value,
    $Res Function(_$ServerExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? statusCode = null,
    Object? data = freezed,
  }) {
    return _then(
      _$ServerExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        statusCode: null == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int,
        data: freezed == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as dynamic,
      ),
    );
  }
}

/// @nodoc

class _$ServerExceptionImpl implements ServerException {
  const _$ServerExceptionImpl({
    required this.message,
    required this.statusCode,
    this.data,
  });

  @override
  final String message;
  @override
  final int statusCode;
  @override
  final dynamic data;

  @override
  String toString() {
    return 'Failure.serverException(message: $message, statusCode: $statusCode, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServerExceptionImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    message,
    statusCode,
    const DeepCollectionEquality().hash(data),
  );

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServerExceptionImplCopyWith<_$ServerExceptionImpl> get copyWith =>
      __$$ServerExceptionImplCopyWithImpl<_$ServerExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int statusCode, dynamic data)
    serverException,
    required TResult Function(String message) connectionException,
    required TResult Function(String message) unauthorizedException,
    required TResult Function(String message, Map<String, List<String>>? errors)
    validationException,
    required TResult Function(String message) unknownException,
  }) {
    return serverException(message, statusCode, data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult? Function(String message)? connectionException,
    TResult? Function(String message)? unauthorizedException,
    TResult? Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult? Function(String message)? unknownException,
  }) {
    return serverException?.call(message, statusCode, data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult Function(String message)? connectionException,
    TResult Function(String message)? unauthorizedException,
    TResult Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult Function(String message)? unknownException,
    required TResult orElse(),
  }) {
    if (serverException != null) {
      return serverException(message, statusCode, data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) serverException,
    required TResult Function(ConnectionException value) connectionException,
    required TResult Function(UnauthorizedException value)
    unauthorizedException,
    required TResult Function(ValidationException value) validationException,
    required TResult Function(UnknownException value) unknownException,
  }) {
    return serverException(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? serverException,
    TResult? Function(ConnectionException value)? connectionException,
    TResult? Function(UnauthorizedException value)? unauthorizedException,
    TResult? Function(ValidationException value)? validationException,
    TResult? Function(UnknownException value)? unknownException,
  }) {
    return serverException?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? serverException,
    TResult Function(ConnectionException value)? connectionException,
    TResult Function(UnauthorizedException value)? unauthorizedException,
    TResult Function(ValidationException value)? validationException,
    TResult Function(UnknownException value)? unknownException,
    required TResult orElse(),
  }) {
    if (serverException != null) {
      return serverException(this);
    }
    return orElse();
  }
}

abstract class ServerException implements Failure {
  const factory ServerException({
    required final String message,
    required final int statusCode,
    final dynamic data,
  }) = _$ServerExceptionImpl;

  @override
  String get message;
  int get statusCode;
  dynamic get data;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServerExceptionImplCopyWith<_$ServerExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ConnectionExceptionImplCopyWith<$Res>
    implements $FailureCopyWith<$Res> {
  factory _$$ConnectionExceptionImplCopyWith(
    _$ConnectionExceptionImpl value,
    $Res Function(_$ConnectionExceptionImpl) then,
  ) = __$$ConnectionExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ConnectionExceptionImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ConnectionExceptionImpl>
    implements _$$ConnectionExceptionImplCopyWith<$Res> {
  __$$ConnectionExceptionImplCopyWithImpl(
    _$ConnectionExceptionImpl _value,
    $Res Function(_$ConnectionExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$ConnectionExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ConnectionExceptionImpl implements ConnectionException {
  const _$ConnectionExceptionImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.connectionException(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionExceptionImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionExceptionImplCopyWith<_$ConnectionExceptionImpl> get copyWith =>
      __$$ConnectionExceptionImplCopyWithImpl<_$ConnectionExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int statusCode, dynamic data)
    serverException,
    required TResult Function(String message) connectionException,
    required TResult Function(String message) unauthorizedException,
    required TResult Function(String message, Map<String, List<String>>? errors)
    validationException,
    required TResult Function(String message) unknownException,
  }) {
    return connectionException(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult? Function(String message)? connectionException,
    TResult? Function(String message)? unauthorizedException,
    TResult? Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult? Function(String message)? unknownException,
  }) {
    return connectionException?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult Function(String message)? connectionException,
    TResult Function(String message)? unauthorizedException,
    TResult Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult Function(String message)? unknownException,
    required TResult orElse(),
  }) {
    if (connectionException != null) {
      return connectionException(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) serverException,
    required TResult Function(ConnectionException value) connectionException,
    required TResult Function(UnauthorizedException value)
    unauthorizedException,
    required TResult Function(ValidationException value) validationException,
    required TResult Function(UnknownException value) unknownException,
  }) {
    return connectionException(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? serverException,
    TResult? Function(ConnectionException value)? connectionException,
    TResult? Function(UnauthorizedException value)? unauthorizedException,
    TResult? Function(ValidationException value)? validationException,
    TResult? Function(UnknownException value)? unknownException,
  }) {
    return connectionException?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? serverException,
    TResult Function(ConnectionException value)? connectionException,
    TResult Function(UnauthorizedException value)? unauthorizedException,
    TResult Function(ValidationException value)? validationException,
    TResult Function(UnknownException value)? unknownException,
    required TResult orElse(),
  }) {
    if (connectionException != null) {
      return connectionException(this);
    }
    return orElse();
  }
}

abstract class ConnectionException implements Failure {
  const factory ConnectionException({required final String message}) =
      _$ConnectionExceptionImpl;

  @override
  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionExceptionImplCopyWith<_$ConnectionExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnauthorizedExceptionImplCopyWith<$Res>
    implements $FailureCopyWith<$Res> {
  factory _$$UnauthorizedExceptionImplCopyWith(
    _$UnauthorizedExceptionImpl value,
    $Res Function(_$UnauthorizedExceptionImpl) then,
  ) = __$$UnauthorizedExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$UnauthorizedExceptionImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$UnauthorizedExceptionImpl>
    implements _$$UnauthorizedExceptionImplCopyWith<$Res> {
  __$$UnauthorizedExceptionImplCopyWithImpl(
    _$UnauthorizedExceptionImpl _value,
    $Res Function(_$UnauthorizedExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$UnauthorizedExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$UnauthorizedExceptionImpl implements UnauthorizedException {
  const _$UnauthorizedExceptionImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.unauthorizedException(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnauthorizedExceptionImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnauthorizedExceptionImplCopyWith<_$UnauthorizedExceptionImpl>
  get copyWith =>
      __$$UnauthorizedExceptionImplCopyWithImpl<_$UnauthorizedExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int statusCode, dynamic data)
    serverException,
    required TResult Function(String message) connectionException,
    required TResult Function(String message) unauthorizedException,
    required TResult Function(String message, Map<String, List<String>>? errors)
    validationException,
    required TResult Function(String message) unknownException,
  }) {
    return unauthorizedException(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult? Function(String message)? connectionException,
    TResult? Function(String message)? unauthorizedException,
    TResult? Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult? Function(String message)? unknownException,
  }) {
    return unauthorizedException?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult Function(String message)? connectionException,
    TResult Function(String message)? unauthorizedException,
    TResult Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult Function(String message)? unknownException,
    required TResult orElse(),
  }) {
    if (unauthorizedException != null) {
      return unauthorizedException(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) serverException,
    required TResult Function(ConnectionException value) connectionException,
    required TResult Function(UnauthorizedException value)
    unauthorizedException,
    required TResult Function(ValidationException value) validationException,
    required TResult Function(UnknownException value) unknownException,
  }) {
    return unauthorizedException(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? serverException,
    TResult? Function(ConnectionException value)? connectionException,
    TResult? Function(UnauthorizedException value)? unauthorizedException,
    TResult? Function(ValidationException value)? validationException,
    TResult? Function(UnknownException value)? unknownException,
  }) {
    return unauthorizedException?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? serverException,
    TResult Function(ConnectionException value)? connectionException,
    TResult Function(UnauthorizedException value)? unauthorizedException,
    TResult Function(ValidationException value)? validationException,
    TResult Function(UnknownException value)? unknownException,
    required TResult orElse(),
  }) {
    if (unauthorizedException != null) {
      return unauthorizedException(this);
    }
    return orElse();
  }
}

abstract class UnauthorizedException implements Failure {
  const factory UnauthorizedException({required final String message}) =
      _$UnauthorizedExceptionImpl;

  @override
  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnauthorizedExceptionImplCopyWith<_$UnauthorizedExceptionImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ValidationExceptionImplCopyWith<$Res>
    implements $FailureCopyWith<$Res> {
  factory _$$ValidationExceptionImplCopyWith(
    _$ValidationExceptionImpl value,
    $Res Function(_$ValidationExceptionImpl) then,
  ) = __$$ValidationExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, Map<String, List<String>>? errors});
}

/// @nodoc
class __$$ValidationExceptionImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ValidationExceptionImpl>
    implements _$$ValidationExceptionImplCopyWith<$Res> {
  __$$ValidationExceptionImplCopyWithImpl(
    _$ValidationExceptionImpl _value,
    $Res Function(_$ValidationExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? errors = freezed}) {
    return _then(
      _$ValidationExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        errors: freezed == errors
            ? _value._errors
            : errors // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<String>>?,
      ),
    );
  }
}

/// @nodoc

class _$ValidationExceptionImpl implements ValidationException {
  const _$ValidationExceptionImpl({
    required this.message,
    final Map<String, List<String>>? errors,
  }) : _errors = errors;

  @override
  final String message;
  final Map<String, List<String>>? _errors;
  @override
  Map<String, List<String>>? get errors {
    final value = _errors;
    if (value == null) return null;
    if (_errors is EqualUnmodifiableMapView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Failure.validationException(message: $message, errors: $errors)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ValidationExceptionImpl &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._errors, _errors));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    message,
    const DeepCollectionEquality().hash(_errors),
  );

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ValidationExceptionImplCopyWith<_$ValidationExceptionImpl> get copyWith =>
      __$$ValidationExceptionImplCopyWithImpl<_$ValidationExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int statusCode, dynamic data)
    serverException,
    required TResult Function(String message) connectionException,
    required TResult Function(String message) unauthorizedException,
    required TResult Function(String message, Map<String, List<String>>? errors)
    validationException,
    required TResult Function(String message) unknownException,
  }) {
    return validationException(message, errors);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult? Function(String message)? connectionException,
    TResult? Function(String message)? unauthorizedException,
    TResult? Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult? Function(String message)? unknownException,
  }) {
    return validationException?.call(message, errors);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult Function(String message)? connectionException,
    TResult Function(String message)? unauthorizedException,
    TResult Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult Function(String message)? unknownException,
    required TResult orElse(),
  }) {
    if (validationException != null) {
      return validationException(message, errors);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) serverException,
    required TResult Function(ConnectionException value) connectionException,
    required TResult Function(UnauthorizedException value)
    unauthorizedException,
    required TResult Function(ValidationException value) validationException,
    required TResult Function(UnknownException value) unknownException,
  }) {
    return validationException(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? serverException,
    TResult? Function(ConnectionException value)? connectionException,
    TResult? Function(UnauthorizedException value)? unauthorizedException,
    TResult? Function(ValidationException value)? validationException,
    TResult? Function(UnknownException value)? unknownException,
  }) {
    return validationException?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? serverException,
    TResult Function(ConnectionException value)? connectionException,
    TResult Function(UnauthorizedException value)? unauthorizedException,
    TResult Function(ValidationException value)? validationException,
    TResult Function(UnknownException value)? unknownException,
    required TResult orElse(),
  }) {
    if (validationException != null) {
      return validationException(this);
    }
    return orElse();
  }
}

abstract class ValidationException implements Failure {
  const factory ValidationException({
    required final String message,
    final Map<String, List<String>>? errors,
  }) = _$ValidationExceptionImpl;

  @override
  String get message;
  Map<String, List<String>>? get errors;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ValidationExceptionImplCopyWith<_$ValidationExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnknownExceptionImplCopyWith<$Res>
    implements $FailureCopyWith<$Res> {
  factory _$$UnknownExceptionImplCopyWith(
    _$UnknownExceptionImpl value,
    $Res Function(_$UnknownExceptionImpl) then,
  ) = __$$UnknownExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$UnknownExceptionImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$UnknownExceptionImpl>
    implements _$$UnknownExceptionImplCopyWith<$Res> {
  __$$UnknownExceptionImplCopyWithImpl(
    _$UnknownExceptionImpl _value,
    $Res Function(_$UnknownExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$UnknownExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$UnknownExceptionImpl implements UnknownException {
  const _$UnknownExceptionImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.unknownException(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnknownExceptionImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnknownExceptionImplCopyWith<_$UnknownExceptionImpl> get copyWith =>
      __$$UnknownExceptionImplCopyWithImpl<_$UnknownExceptionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message, int statusCode, dynamic data)
    serverException,
    required TResult Function(String message) connectionException,
    required TResult Function(String message) unauthorizedException,
    required TResult Function(String message, Map<String, List<String>>? errors)
    validationException,
    required TResult Function(String message) unknownException,
  }) {
    return unknownException(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult? Function(String message)? connectionException,
    TResult? Function(String message)? unauthorizedException,
    TResult? Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult? Function(String message)? unknownException,
  }) {
    return unknownException?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, int statusCode, dynamic data)?
    serverException,
    TResult Function(String message)? connectionException,
    TResult Function(String message)? unauthorizedException,
    TResult Function(String message, Map<String, List<String>>? errors)?
    validationException,
    TResult Function(String message)? unknownException,
    required TResult orElse(),
  }) {
    if (unknownException != null) {
      return unknownException(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ServerException value) serverException,
    required TResult Function(ConnectionException value) connectionException,
    required TResult Function(UnauthorizedException value)
    unauthorizedException,
    required TResult Function(ValidationException value) validationException,
    required TResult Function(UnknownException value) unknownException,
  }) {
    return unknownException(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ServerException value)? serverException,
    TResult? Function(ConnectionException value)? connectionException,
    TResult? Function(UnauthorizedException value)? unauthorizedException,
    TResult? Function(ValidationException value)? validationException,
    TResult? Function(UnknownException value)? unknownException,
  }) {
    return unknownException?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ServerException value)? serverException,
    TResult Function(ConnectionException value)? connectionException,
    TResult Function(UnauthorizedException value)? unauthorizedException,
    TResult Function(ValidationException value)? validationException,
    TResult Function(UnknownException value)? unknownException,
    required TResult orElse(),
  }) {
    if (unknownException != null) {
      return unknownException(this);
    }
    return orElse();
  }
}

abstract class UnknownException implements Failure {
  const factory UnknownException({required final String message}) =
      _$UnknownExceptionImpl;

  @override
  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnknownExceptionImplCopyWith<_$UnknownExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
