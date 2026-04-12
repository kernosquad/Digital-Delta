// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connectivity_status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ConnectivityStatusModel {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(ConnectionType type) online,
    required TResult Function() offline,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(ConnectionType type)? online,
    TResult? Function()? offline,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(ConnectionType type)? online,
    TResult Function()? offline,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OnlineConnectivity value) online,
    required TResult Function(OfflineConnectivity value) offline,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OnlineConnectivity value)? online,
    TResult? Function(OfflineConnectivity value)? offline,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OnlineConnectivity value)? online,
    TResult Function(OfflineConnectivity value)? offline,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectivityStatusModelCopyWith<$Res> {
  factory $ConnectivityStatusModelCopyWith(
    ConnectivityStatusModel value,
    $Res Function(ConnectivityStatusModel) then,
  ) = _$ConnectivityStatusModelCopyWithImpl<$Res, ConnectivityStatusModel>;
}

/// @nodoc
class _$ConnectivityStatusModelCopyWithImpl<
  $Res,
  $Val extends ConnectivityStatusModel
>
    implements $ConnectivityStatusModelCopyWith<$Res> {
  _$ConnectivityStatusModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectivityStatusModel
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$OnlineConnectivityImplCopyWith<$Res> {
  factory _$$OnlineConnectivityImplCopyWith(
    _$OnlineConnectivityImpl value,
    $Res Function(_$OnlineConnectivityImpl) then,
  ) = __$$OnlineConnectivityImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ConnectionType type});
}

/// @nodoc
class __$$OnlineConnectivityImplCopyWithImpl<$Res>
    extends
        _$ConnectivityStatusModelCopyWithImpl<$Res, _$OnlineConnectivityImpl>
    implements _$$OnlineConnectivityImplCopyWith<$Res> {
  __$$OnlineConnectivityImplCopyWithImpl(
    _$OnlineConnectivityImpl _value,
    $Res Function(_$OnlineConnectivityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConnectivityStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? type = null}) {
    return _then(
      _$OnlineConnectivityImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ConnectionType,
      ),
    );
  }
}

/// @nodoc

class _$OnlineConnectivityImpl implements OnlineConnectivity {
  const _$OnlineConnectivityImpl({required this.type});

  @override
  final ConnectionType type;

  @override
  String toString() {
    return 'ConnectivityStatusModel.online(type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OnlineConnectivityImpl &&
            (identical(other.type, type) || other.type == type));
  }

  @override
  int get hashCode => Object.hash(runtimeType, type);

  /// Create a copy of ConnectivityStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OnlineConnectivityImplCopyWith<_$OnlineConnectivityImpl> get copyWith =>
      __$$OnlineConnectivityImplCopyWithImpl<_$OnlineConnectivityImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(ConnectionType type) online,
    required TResult Function() offline,
  }) {
    return online(type);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(ConnectionType type)? online,
    TResult? Function()? offline,
  }) {
    return online?.call(type);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
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
    required TResult Function(OnlineConnectivity value) online,
    required TResult Function(OfflineConnectivity value) offline,
  }) {
    return online(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OnlineConnectivity value)? online,
    TResult? Function(OfflineConnectivity value)? offline,
  }) {
    return online?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OnlineConnectivity value)? online,
    TResult Function(OfflineConnectivity value)? offline,
    required TResult orElse(),
  }) {
    if (online != null) {
      return online(this);
    }
    return orElse();
  }
}

abstract class OnlineConnectivity implements ConnectivityStatusModel {
  const factory OnlineConnectivity({required final ConnectionType type}) =
      _$OnlineConnectivityImpl;

  ConnectionType get type;

  /// Create a copy of ConnectivityStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OnlineConnectivityImplCopyWith<_$OnlineConnectivityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$OfflineConnectivityImplCopyWith<$Res> {
  factory _$$OfflineConnectivityImplCopyWith(
    _$OfflineConnectivityImpl value,
    $Res Function(_$OfflineConnectivityImpl) then,
  ) = __$$OfflineConnectivityImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$OfflineConnectivityImplCopyWithImpl<$Res>
    extends
        _$ConnectivityStatusModelCopyWithImpl<$Res, _$OfflineConnectivityImpl>
    implements _$$OfflineConnectivityImplCopyWith<$Res> {
  __$$OfflineConnectivityImplCopyWithImpl(
    _$OfflineConnectivityImpl _value,
    $Res Function(_$OfflineConnectivityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConnectivityStatusModel
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$OfflineConnectivityImpl implements OfflineConnectivity {
  const _$OfflineConnectivityImpl();

  @override
  String toString() {
    return 'ConnectivityStatusModel.offline()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OfflineConnectivityImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(ConnectionType type) online,
    required TResult Function() offline,
  }) {
    return offline();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(ConnectionType type)? online,
    TResult? Function()? offline,
  }) {
    return offline?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
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
    required TResult Function(OnlineConnectivity value) online,
    required TResult Function(OfflineConnectivity value) offline,
  }) {
    return offline(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OnlineConnectivity value)? online,
    TResult? Function(OfflineConnectivity value)? offline,
  }) {
    return offline?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OnlineConnectivity value)? online,
    TResult Function(OfflineConnectivity value)? offline,
    required TResult orElse(),
  }) {
    if (offline != null) {
      return offline(this);
    }
    return orElse();
  }
}

abstract class OfflineConnectivity implements ConnectivityStatusModel {
  const factory OfflineConnectivity() = _$OfflineConnectivityImpl;
}
