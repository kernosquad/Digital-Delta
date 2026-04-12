// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operations_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OperationsUiState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(OperationsSnapshot snapshot) loaded,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(OperationsSnapshot snapshot)? loaded,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(OperationsSnapshot snapshot)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OperationsLoadingState value) loading,
    required TResult Function(OperationsLoadedState value) loaded,
    required TResult Function(OperationsErrorState value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OperationsLoadingState value)? loading,
    TResult? Function(OperationsLoadedState value)? loaded,
    TResult? Function(OperationsErrorState value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OperationsLoadingState value)? loading,
    TResult Function(OperationsLoadedState value)? loaded,
    TResult Function(OperationsErrorState value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OperationsUiStateCopyWith<$Res> {
  factory $OperationsUiStateCopyWith(
    OperationsUiState value,
    $Res Function(OperationsUiState) then,
  ) = _$OperationsUiStateCopyWithImpl<$Res, OperationsUiState>;
}

/// @nodoc
class _$OperationsUiStateCopyWithImpl<$Res, $Val extends OperationsUiState>
    implements $OperationsUiStateCopyWith<$Res> {
  _$OperationsUiStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OperationsUiState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$OperationsLoadingStateImplCopyWith<$Res> {
  factory _$$OperationsLoadingStateImplCopyWith(
    _$OperationsLoadingStateImpl value,
    $Res Function(_$OperationsLoadingStateImpl) then,
  ) = __$$OperationsLoadingStateImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$OperationsLoadingStateImplCopyWithImpl<$Res>
    extends _$OperationsUiStateCopyWithImpl<$Res, _$OperationsLoadingStateImpl>
    implements _$$OperationsLoadingStateImplCopyWith<$Res> {
  __$$OperationsLoadingStateImplCopyWithImpl(
    _$OperationsLoadingStateImpl _value,
    $Res Function(_$OperationsLoadingStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OperationsUiState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$OperationsLoadingStateImpl implements OperationsLoadingState {
  const _$OperationsLoadingStateImpl();

  @override
  String toString() {
    return 'OperationsUiState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OperationsLoadingStateImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(OperationsSnapshot snapshot) loaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(OperationsSnapshot snapshot)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(OperationsSnapshot snapshot)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OperationsLoadingState value) loading,
    required TResult Function(OperationsLoadedState value) loaded,
    required TResult Function(OperationsErrorState value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OperationsLoadingState value)? loading,
    TResult? Function(OperationsLoadedState value)? loaded,
    TResult? Function(OperationsErrorState value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OperationsLoadingState value)? loading,
    TResult Function(OperationsLoadedState value)? loaded,
    TResult Function(OperationsErrorState value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class OperationsLoadingState implements OperationsUiState {
  const factory OperationsLoadingState() = _$OperationsLoadingStateImpl;
}

/// @nodoc
abstract class _$$OperationsLoadedStateImplCopyWith<$Res> {
  factory _$$OperationsLoadedStateImplCopyWith(
    _$OperationsLoadedStateImpl value,
    $Res Function(_$OperationsLoadedStateImpl) then,
  ) = __$$OperationsLoadedStateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({OperationsSnapshot snapshot});
}

/// @nodoc
class __$$OperationsLoadedStateImplCopyWithImpl<$Res>
    extends _$OperationsUiStateCopyWithImpl<$Res, _$OperationsLoadedStateImpl>
    implements _$$OperationsLoadedStateImplCopyWith<$Res> {
  __$$OperationsLoadedStateImplCopyWithImpl(
    _$OperationsLoadedStateImpl _value,
    $Res Function(_$OperationsLoadedStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OperationsUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? snapshot = null}) {
    return _then(
      _$OperationsLoadedStateImpl(
        snapshot: null == snapshot
            ? _value.snapshot
            : snapshot // ignore: cast_nullable_to_non_nullable
                  as OperationsSnapshot,
      ),
    );
  }
}

/// @nodoc

class _$OperationsLoadedStateImpl implements OperationsLoadedState {
  const _$OperationsLoadedStateImpl({required this.snapshot});

  @override
  final OperationsSnapshot snapshot;

  @override
  String toString() {
    return 'OperationsUiState.loaded(snapshot: $snapshot)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OperationsLoadedStateImpl &&
            (identical(other.snapshot, snapshot) ||
                other.snapshot == snapshot));
  }

  @override
  int get hashCode => Object.hash(runtimeType, snapshot);

  /// Create a copy of OperationsUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OperationsLoadedStateImplCopyWith<_$OperationsLoadedStateImpl>
  get copyWith =>
      __$$OperationsLoadedStateImplCopyWithImpl<_$OperationsLoadedStateImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(OperationsSnapshot snapshot) loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(snapshot);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(OperationsSnapshot snapshot)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(snapshot);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(OperationsSnapshot snapshot)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(snapshot);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OperationsLoadingState value) loading,
    required TResult Function(OperationsLoadedState value) loaded,
    required TResult Function(OperationsErrorState value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OperationsLoadingState value)? loading,
    TResult? Function(OperationsLoadedState value)? loaded,
    TResult? Function(OperationsErrorState value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OperationsLoadingState value)? loading,
    TResult Function(OperationsLoadedState value)? loaded,
    TResult Function(OperationsErrorState value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class OperationsLoadedState implements OperationsUiState {
  const factory OperationsLoadedState({
    required final OperationsSnapshot snapshot,
  }) = _$OperationsLoadedStateImpl;

  OperationsSnapshot get snapshot;

  /// Create a copy of OperationsUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OperationsLoadedStateImplCopyWith<_$OperationsLoadedStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$OperationsErrorStateImplCopyWith<$Res> {
  factory _$$OperationsErrorStateImplCopyWith(
    _$OperationsErrorStateImpl value,
    $Res Function(_$OperationsErrorStateImpl) then,
  ) = __$$OperationsErrorStateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$OperationsErrorStateImplCopyWithImpl<$Res>
    extends _$OperationsUiStateCopyWithImpl<$Res, _$OperationsErrorStateImpl>
    implements _$$OperationsErrorStateImplCopyWith<$Res> {
  __$$OperationsErrorStateImplCopyWithImpl(
    _$OperationsErrorStateImpl _value,
    $Res Function(_$OperationsErrorStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OperationsUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$OperationsErrorStateImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$OperationsErrorStateImpl implements OperationsErrorState {
  const _$OperationsErrorStateImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'OperationsUiState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OperationsErrorStateImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of OperationsUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OperationsErrorStateImplCopyWith<_$OperationsErrorStateImpl>
  get copyWith =>
      __$$OperationsErrorStateImplCopyWithImpl<_$OperationsErrorStateImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(OperationsSnapshot snapshot) loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(OperationsSnapshot snapshot)? loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(OperationsSnapshot snapshot)? loaded,
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
    required TResult Function(OperationsLoadingState value) loading,
    required TResult Function(OperationsLoadedState value) loaded,
    required TResult Function(OperationsErrorState value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OperationsLoadingState value)? loading,
    TResult? Function(OperationsLoadedState value)? loaded,
    TResult? Function(OperationsErrorState value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OperationsLoadingState value)? loading,
    TResult Function(OperationsLoadedState value)? loaded,
    TResult Function(OperationsErrorState value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class OperationsErrorState implements OperationsUiState {
  const factory OperationsErrorState(final String message) =
      _$OperationsErrorStateImpl;

  String get message;

  /// Create a copy of OperationsUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OperationsErrorStateImplCopyWith<_$OperationsErrorStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
