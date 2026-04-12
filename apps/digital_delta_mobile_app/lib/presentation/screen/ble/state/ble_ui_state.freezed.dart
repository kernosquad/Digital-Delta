// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ble_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BleUiState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<BleDeviceModel> devices) scanning,
    required TResult Function(List<BleDeviceModel> devices) idle,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<BleDeviceModel> devices)? scanning,
    TResult? Function(List<BleDeviceModel> devices)? idle,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<BleDeviceModel> devices)? scanning,
    TResult Function(List<BleDeviceModel> devices)? idle,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BleInitialState value) initial,
    required TResult Function(BleScanningState value) scanning,
    required TResult Function(BleIdleState value) idle,
    required TResult Function(BleErrorState value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BleInitialState value)? initial,
    TResult? Function(BleScanningState value)? scanning,
    TResult? Function(BleIdleState value)? idle,
    TResult? Function(BleErrorState value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BleInitialState value)? initial,
    TResult Function(BleScanningState value)? scanning,
    TResult Function(BleIdleState value)? idle,
    TResult Function(BleErrorState value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BleUiStateCopyWith<$Res> {
  factory $BleUiStateCopyWith(
    BleUiState value,
    $Res Function(BleUiState) then,
  ) = _$BleUiStateCopyWithImpl<$Res, BleUiState>;
}

/// @nodoc
class _$BleUiStateCopyWithImpl<$Res, $Val extends BleUiState>
    implements $BleUiStateCopyWith<$Res> {
  _$BleUiStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$BleInitialStateImplCopyWith<$Res> {
  factory _$$BleInitialStateImplCopyWith(
    _$BleInitialStateImpl value,
    $Res Function(_$BleInitialStateImpl) then,
  ) = __$$BleInitialStateImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$BleInitialStateImplCopyWithImpl<$Res>
    extends _$BleUiStateCopyWithImpl<$Res, _$BleInitialStateImpl>
    implements _$$BleInitialStateImplCopyWith<$Res> {
  __$$BleInitialStateImplCopyWithImpl(
    _$BleInitialStateImpl _value,
    $Res Function(_$BleInitialStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$BleInitialStateImpl implements BleInitialState {
  const _$BleInitialStateImpl();

  @override
  String toString() {
    return 'BleUiState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$BleInitialStateImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<BleDeviceModel> devices) scanning,
    required TResult Function(List<BleDeviceModel> devices) idle,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<BleDeviceModel> devices)? scanning,
    TResult? Function(List<BleDeviceModel> devices)? idle,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<BleDeviceModel> devices)? scanning,
    TResult Function(List<BleDeviceModel> devices)? idle,
    TResult Function(String message)? error,
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
    required TResult Function(BleInitialState value) initial,
    required TResult Function(BleScanningState value) scanning,
    required TResult Function(BleIdleState value) idle,
    required TResult Function(BleErrorState value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BleInitialState value)? initial,
    TResult? Function(BleScanningState value)? scanning,
    TResult? Function(BleIdleState value)? idle,
    TResult? Function(BleErrorState value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BleInitialState value)? initial,
    TResult Function(BleScanningState value)? scanning,
    TResult Function(BleIdleState value)? idle,
    TResult Function(BleErrorState value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class BleInitialState implements BleUiState {
  const factory BleInitialState() = _$BleInitialStateImpl;
}

/// @nodoc
abstract class _$$BleScanningStateImplCopyWith<$Res> {
  factory _$$BleScanningStateImplCopyWith(
    _$BleScanningStateImpl value,
    $Res Function(_$BleScanningStateImpl) then,
  ) = __$$BleScanningStateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<BleDeviceModel> devices});
}

/// @nodoc
class __$$BleScanningStateImplCopyWithImpl<$Res>
    extends _$BleUiStateCopyWithImpl<$Res, _$BleScanningStateImpl>
    implements _$$BleScanningStateImplCopyWith<$Res> {
  __$$BleScanningStateImplCopyWithImpl(
    _$BleScanningStateImpl _value,
    $Res Function(_$BleScanningStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? devices = null}) {
    return _then(
      _$BleScanningStateImpl(
        devices: null == devices
            ? _value._devices
            : devices // ignore: cast_nullable_to_non_nullable
                  as List<BleDeviceModel>,
      ),
    );
  }
}

/// @nodoc

class _$BleScanningStateImpl implements BleScanningState {
  const _$BleScanningStateImpl({final List<BleDeviceModel> devices = const []})
    : _devices = devices;

  final List<BleDeviceModel> _devices;
  @override
  @JsonKey()
  List<BleDeviceModel> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  @override
  String toString() {
    return 'BleUiState.scanning(devices: $devices)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BleScanningStateImpl &&
            const DeepCollectionEquality().equals(other._devices, _devices));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_devices));

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BleScanningStateImplCopyWith<_$BleScanningStateImpl> get copyWith =>
      __$$BleScanningStateImplCopyWithImpl<_$BleScanningStateImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<BleDeviceModel> devices) scanning,
    required TResult Function(List<BleDeviceModel> devices) idle,
    required TResult Function(String message) error,
  }) {
    return scanning(devices);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<BleDeviceModel> devices)? scanning,
    TResult? Function(List<BleDeviceModel> devices)? idle,
    TResult? Function(String message)? error,
  }) {
    return scanning?.call(devices);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<BleDeviceModel> devices)? scanning,
    TResult Function(List<BleDeviceModel> devices)? idle,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (scanning != null) {
      return scanning(devices);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BleInitialState value) initial,
    required TResult Function(BleScanningState value) scanning,
    required TResult Function(BleIdleState value) idle,
    required TResult Function(BleErrorState value) error,
  }) {
    return scanning(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BleInitialState value)? initial,
    TResult? Function(BleScanningState value)? scanning,
    TResult? Function(BleIdleState value)? idle,
    TResult? Function(BleErrorState value)? error,
  }) {
    return scanning?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BleInitialState value)? initial,
    TResult Function(BleScanningState value)? scanning,
    TResult Function(BleIdleState value)? idle,
    TResult Function(BleErrorState value)? error,
    required TResult orElse(),
  }) {
    if (scanning != null) {
      return scanning(this);
    }
    return orElse();
  }
}

abstract class BleScanningState implements BleUiState {
  const factory BleScanningState({final List<BleDeviceModel> devices}) =
      _$BleScanningStateImpl;

  List<BleDeviceModel> get devices;

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BleScanningStateImplCopyWith<_$BleScanningStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BleIdleStateImplCopyWith<$Res> {
  factory _$$BleIdleStateImplCopyWith(
    _$BleIdleStateImpl value,
    $Res Function(_$BleIdleStateImpl) then,
  ) = __$$BleIdleStateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<BleDeviceModel> devices});
}

/// @nodoc
class __$$BleIdleStateImplCopyWithImpl<$Res>
    extends _$BleUiStateCopyWithImpl<$Res, _$BleIdleStateImpl>
    implements _$$BleIdleStateImplCopyWith<$Res> {
  __$$BleIdleStateImplCopyWithImpl(
    _$BleIdleStateImpl _value,
    $Res Function(_$BleIdleStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? devices = null}) {
    return _then(
      _$BleIdleStateImpl(
        devices: null == devices
            ? _value._devices
            : devices // ignore: cast_nullable_to_non_nullable
                  as List<BleDeviceModel>,
      ),
    );
  }
}

/// @nodoc

class _$BleIdleStateImpl implements BleIdleState {
  const _$BleIdleStateImpl({final List<BleDeviceModel> devices = const []})
    : _devices = devices;

  final List<BleDeviceModel> _devices;
  @override
  @JsonKey()
  List<BleDeviceModel> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  @override
  String toString() {
    return 'BleUiState.idle(devices: $devices)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BleIdleStateImpl &&
            const DeepCollectionEquality().equals(other._devices, _devices));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_devices));

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BleIdleStateImplCopyWith<_$BleIdleStateImpl> get copyWith =>
      __$$BleIdleStateImplCopyWithImpl<_$BleIdleStateImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<BleDeviceModel> devices) scanning,
    required TResult Function(List<BleDeviceModel> devices) idle,
    required TResult Function(String message) error,
  }) {
    return idle(devices);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<BleDeviceModel> devices)? scanning,
    TResult? Function(List<BleDeviceModel> devices)? idle,
    TResult? Function(String message)? error,
  }) {
    return idle?.call(devices);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<BleDeviceModel> devices)? scanning,
    TResult Function(List<BleDeviceModel> devices)? idle,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(devices);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BleInitialState value) initial,
    required TResult Function(BleScanningState value) scanning,
    required TResult Function(BleIdleState value) idle,
    required TResult Function(BleErrorState value) error,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BleInitialState value)? initial,
    TResult? Function(BleScanningState value)? scanning,
    TResult? Function(BleIdleState value)? idle,
    TResult? Function(BleErrorState value)? error,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BleInitialState value)? initial,
    TResult Function(BleScanningState value)? scanning,
    TResult Function(BleIdleState value)? idle,
    TResult Function(BleErrorState value)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class BleIdleState implements BleUiState {
  const factory BleIdleState({final List<BleDeviceModel> devices}) =
      _$BleIdleStateImpl;

  List<BleDeviceModel> get devices;

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BleIdleStateImplCopyWith<_$BleIdleStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BleErrorStateImplCopyWith<$Res> {
  factory _$$BleErrorStateImplCopyWith(
    _$BleErrorStateImpl value,
    $Res Function(_$BleErrorStateImpl) then,
  ) = __$$BleErrorStateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$BleErrorStateImplCopyWithImpl<$Res>
    extends _$BleUiStateCopyWithImpl<$Res, _$BleErrorStateImpl>
    implements _$$BleErrorStateImplCopyWith<$Res> {
  __$$BleErrorStateImplCopyWithImpl(
    _$BleErrorStateImpl _value,
    $Res Function(_$BleErrorStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$BleErrorStateImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$BleErrorStateImpl implements BleErrorState {
  const _$BleErrorStateImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'BleUiState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BleErrorStateImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BleErrorStateImplCopyWith<_$BleErrorStateImpl> get copyWith =>
      __$$BleErrorStateImplCopyWithImpl<_$BleErrorStateImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(List<BleDeviceModel> devices) scanning,
    required TResult Function(List<BleDeviceModel> devices) idle,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(List<BleDeviceModel> devices)? scanning,
    TResult? Function(List<BleDeviceModel> devices)? idle,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(List<BleDeviceModel> devices)? scanning,
    TResult Function(List<BleDeviceModel> devices)? idle,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(BleInitialState value) initial,
    required TResult Function(BleScanningState value) scanning,
    required TResult Function(BleIdleState value) idle,
    required TResult Function(BleErrorState value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(BleInitialState value)? initial,
    TResult? Function(BleScanningState value)? scanning,
    TResult? Function(BleIdleState value)? idle,
    TResult? Function(BleErrorState value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(BleInitialState value)? initial,
    TResult Function(BleScanningState value)? scanning,
    TResult Function(BleIdleState value)? idle,
    TResult Function(BleErrorState value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class BleErrorState implements BleUiState {
  const factory BleErrorState(final String message) = _$BleErrorStateImpl;

  String get message;

  /// Create a copy of BleUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BleErrorStateImplCopyWith<_$BleErrorStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
