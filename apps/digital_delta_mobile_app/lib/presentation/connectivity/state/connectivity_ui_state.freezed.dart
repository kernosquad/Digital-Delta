// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connectivity_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ConnectivityUiState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(ConnectionType type) online,
    required TResult Function() offline,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(ConnectionType type)? online,
    TResult? Function()? offline,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(ConnectionType type)? online,
    TResult Function()? offline,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ConnectivityInitialState value) initial,
    required TResult Function(ConnectivityOnlineState value) online,
    required TResult Function(ConnectivityOfflineState value) offline,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ConnectivityInitialState value)? initial,
    TResult? Function(ConnectivityOnlineState value)? online,
    TResult? Function(ConnectivityOfflineState value)? offline,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ConnectivityInitialState value)? initial,
    TResult Function(ConnectivityOnlineState value)? online,
    TResult Function(ConnectivityOfflineState value)? offline,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectivityUiStateCopyWith<$Res> {
  factory $ConnectivityUiStateCopyWith(
    ConnectivityUiState value,
    $Res Function(ConnectivityUiState) then,
  ) = _$ConnectivityUiStateCopyWithImpl<$Res, ConnectivityUiState>;
}

/// @nodoc
class _$ConnectivityUiStateCopyWithImpl<$Res, $Val extends ConnectivityUiState>
    implements $ConnectivityUiStateCopyWith<$Res> {
  _$ConnectivityUiStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectivityUiState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ConnectivityInitialStateImplCopyWith<$Res> {
  factory _$$ConnectivityInitialStateImplCopyWith(
    _$ConnectivityInitialStateImpl value,
    $Res Function(_$ConnectivityInitialStateImpl) then,
  ) = __$$ConnectivityInitialStateImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ConnectivityInitialStateImplCopyWithImpl<$Res>
    extends
        _$ConnectivityUiStateCopyWithImpl<$Res, _$ConnectivityInitialStateImpl>
    implements _$$ConnectivityInitialStateImplCopyWith<$Res> {
  __$$ConnectivityInitialStateImplCopyWithImpl(
    _$ConnectivityInitialStateImpl _value,
    $Res Function(_$ConnectivityInitialStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConnectivityUiState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ConnectivityInitialStateImpl implements ConnectivityInitialState {
  const _$ConnectivityInitialStateImpl();

  @override
  String toString() {
    return 'ConnectivityUiState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectivityInitialStateImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(ConnectionType type) online,
    required TResult Function() offline,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(ConnectionType type)? online,
    TResult? Function()? offline,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(ConnectionType type)? online,
    TResult Function()? offline,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ConnectivityInitialState value) initial,
    required TResult Function(ConnectivityOnlineState value) online,
    required TResult Function(ConnectivityOfflineState value) offline,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ConnectivityInitialState value)? initial,
    TResult? Function(ConnectivityOnlineState value)? online,
    TResult? Function(ConnectivityOfflineState value)? offline,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ConnectivityInitialState value)? initial,
    TResult Function(ConnectivityOnlineState value)? online,
    TResult Function(ConnectivityOfflineState value)? offline,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class ConnectivityInitialState implements ConnectivityUiState {
  const factory ConnectivityInitialState() = _$ConnectivityInitialStateImpl;
}

/// @nodoc
abstract class _$$ConnectivityOnlineStateImplCopyWith<$Res> {
  factory _$$ConnectivityOnlineStateImplCopyWith(
    _$ConnectivityOnlineStateImpl value,
    $Res Function(_$ConnectivityOnlineStateImpl) then,
  ) = __$$ConnectivityOnlineStateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ConnectionType type});
}

/// @nodoc
class __$$ConnectivityOnlineStateImplCopyWithImpl<$Res>
    extends
        _$ConnectivityUiStateCopyWithImpl<$Res, _$ConnectivityOnlineStateImpl>
    implements _$$ConnectivityOnlineStateImplCopyWith<$Res> {
  __$$ConnectivityOnlineStateImplCopyWithImpl(
    _$ConnectivityOnlineStateImpl _value,
    $Res Function(_$ConnectivityOnlineStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConnectivityUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? type = null}) {
    return _then(
      _$ConnectivityOnlineStateImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ConnectionType,
      ),
    );
  }
}

/// @nodoc

class _$ConnectivityOnlineStateImpl implements ConnectivityOnlineState {
  const _$ConnectivityOnlineStateImpl({required this.type});

  @override
  final ConnectionType type;

  @override
  String toString() {
    return 'ConnectivityUiState.online(type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectivityOnlineStateImpl &&
            (identical(other.type, type) || other.type == type));
  }

  @override
  int get hashCode => Object.hash(runtimeType, type);

  /// Create a copy of ConnectivityUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectivityOnlineStateImplCopyWith<_$ConnectivityOnlineStateImpl>
  get copyWith =>
      __$$ConnectivityOnlineStateImplCopyWithImpl<
        _$ConnectivityOnlineStateImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(ConnectionType type) online,
    required TResult Function() offline,
  }) {
    return online(type);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(ConnectionType type)? online,
    TResult? Function()? offline,
  }) {
    return online?.call(type);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(ConnectionType type)? online,
    TResult Function()? offline,
    required TResult orElse(),
  }) {
    if (online != null) {
      return online(type);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ConnectivityInitialState value) initial,
    required TResult Function(ConnectivityOnlineState value) online,
    required TResult Function(ConnectivityOfflineState value) offline,
  }) {
    return online(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ConnectivityInitialState value)? initial,
    TResult? Function(ConnectivityOnlineState value)? online,
    TResult? Function(ConnectivityOfflineState value)? offline,
  }) {
    return online?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ConnectivityInitialState value)? initial,
    TResult Function(ConnectivityOnlineState value)? online,
    TResult Function(ConnectivityOfflineState value)? offline,
    required TResult orElse(),
  }) {
    if (online != null) {
      return online(this);
    }
    return orElse();
  }
}

abstract class ConnectivityOnlineState implements ConnectivityUiState {
  const factory ConnectivityOnlineState({required final ConnectionType type}) =
      _$ConnectivityOnlineStateImpl;

  ConnectionType get type;

  /// Create a copy of ConnectivityUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectivityOnlineStateImplCopyWith<_$ConnectivityOnlineStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ConnectivityOfflineStateImplCopyWith<$Res> {
  factory _$$ConnectivityOfflineStateImplCopyWith(
    _$ConnectivityOfflineStateImpl value,
    $Res Function(_$ConnectivityOfflineStateImpl) then,
  ) = __$$ConnectivityOfflineStateImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ConnectivityOfflineStateImplCopyWithImpl<$Res>
    extends
        _$ConnectivityUiStateCopyWithImpl<$Res, _$ConnectivityOfflineStateImpl>
    implements _$$ConnectivityOfflineStateImplCopyWith<$Res> {
  __$$ConnectivityOfflineStateImplCopyWithImpl(
    _$ConnectivityOfflineStateImpl _value,
    $Res Function(_$ConnectivityOfflineStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConnectivityUiState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ConnectivityOfflineStateImpl implements ConnectivityOfflineState {
  const _$ConnectivityOfflineStateImpl();

  @override
  String toString() {
    return 'ConnectivityUiState.offline()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectivityOfflineStateImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(ConnectionType type) online,
    required TResult Function() offline,
  }) {
    return offline();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(ConnectionType type)? online,
    TResult? Function()? offline,
  }) {
    return offline?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(ConnectionType type)? online,
    TResult Function()? offline,
    required TResult orElse(),
  }) {
    if (offline != null) {
      return offline();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ConnectivityInitialState value) initial,
    required TResult Function(ConnectivityOnlineState value) online,
    required TResult Function(ConnectivityOfflineState value) offline,
  }) {
    return offline(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ConnectivityInitialState value)? initial,
    TResult? Function(ConnectivityOnlineState value)? online,
    TResult? Function(ConnectivityOfflineState value)? offline,
  }) {
    return offline?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ConnectivityInitialState value)? initial,
    TResult Function(ConnectivityOnlineState value)? online,
    TResult Function(ConnectivityOfflineState value)? offline,
    required TResult orElse(),
  }) {
    if (offline != null) {
      return offline(this);
    }
    return orElse();
  }
}

abstract class ConnectivityOfflineState implements ConnectivityUiState {
  const factory ConnectivityOfflineState() = _$ConnectivityOfflineStateImpl;
}
