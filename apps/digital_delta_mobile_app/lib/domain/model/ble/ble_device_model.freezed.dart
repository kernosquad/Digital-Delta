// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ble_device_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BleDeviceModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get rssi => throw _privateConstructorUsedError;
  BleDeviceConnectionState get connectionState =>
      throw _privateConstructorUsedError;

  /// Create a copy of BleDeviceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BleDeviceModelCopyWith<BleDeviceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BleDeviceModelCopyWith<$Res> {
  factory $BleDeviceModelCopyWith(
    BleDeviceModel value,
    $Res Function(BleDeviceModel) then,
  ) = _$BleDeviceModelCopyWithImpl<$Res, BleDeviceModel>;
  @useResult
  $Res call({
    String id,
    String name,
    int rssi,
    BleDeviceConnectionState connectionState,
  });
}

/// @nodoc
class _$BleDeviceModelCopyWithImpl<$Res, $Val extends BleDeviceModel>
    implements $BleDeviceModelCopyWith<$Res> {
  _$BleDeviceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BleDeviceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? rssi = null,
    Object? connectionState = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            rssi: null == rssi
                ? _value.rssi
                : rssi // ignore: cast_nullable_to_non_nullable
                      as int,
            connectionState: null == connectionState
                ? _value.connectionState
                : connectionState // ignore: cast_nullable_to_non_nullable
                      as BleDeviceConnectionState,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BleDeviceModelImplCopyWith<$Res>
    implements $BleDeviceModelCopyWith<$Res> {
  factory _$$BleDeviceModelImplCopyWith(
    _$BleDeviceModelImpl value,
    $Res Function(_$BleDeviceModelImpl) then,
  ) = __$$BleDeviceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int rssi,
    BleDeviceConnectionState connectionState,
  });
}

/// @nodoc
class __$$BleDeviceModelImplCopyWithImpl<$Res>
    extends _$BleDeviceModelCopyWithImpl<$Res, _$BleDeviceModelImpl>
    implements _$$BleDeviceModelImplCopyWith<$Res> {
  __$$BleDeviceModelImplCopyWithImpl(
    _$BleDeviceModelImpl _value,
    $Res Function(_$BleDeviceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BleDeviceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? rssi = null,
    Object? connectionState = null,
  }) {
    return _then(
      _$BleDeviceModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        rssi: null == rssi
            ? _value.rssi
            : rssi // ignore: cast_nullable_to_non_nullable
                  as int,
        connectionState: null == connectionState
            ? _value.connectionState
            : connectionState // ignore: cast_nullable_to_non_nullable
                  as BleDeviceConnectionState,
      ),
    );
  }
}

/// @nodoc

class _$BleDeviceModelImpl implements _BleDeviceModel {
  const _$BleDeviceModelImpl({
    required this.id,
    required this.name,
    required this.rssi,
    this.connectionState = BleDeviceConnectionState.disconnected,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final int rssi;
  @override
  @JsonKey()
  final BleDeviceConnectionState connectionState;

  @override
  String toString() {
    return 'BleDeviceModel(id: $id, name: $name, rssi: $rssi, connectionState: $connectionState)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BleDeviceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.rssi, rssi) || other.rssi == rssi) &&
            (identical(other.connectionState, connectionState) ||
                other.connectionState == connectionState));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, rssi, connectionState);

  /// Create a copy of BleDeviceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BleDeviceModelImplCopyWith<_$BleDeviceModelImpl> get copyWith =>
      __$$BleDeviceModelImplCopyWithImpl<_$BleDeviceModelImpl>(
        this,
        _$identity,
      );
}

abstract class _BleDeviceModel implements BleDeviceModel {
  const factory _BleDeviceModel({
    required final String id,
    required final String name,
    required final int rssi,
    final BleDeviceConnectionState connectionState,
  }) = _$BleDeviceModelImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  int get rssi;
  @override
  BleDeviceConnectionState get connectionState;

  /// Create a copy of BleDeviceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BleDeviceModelImplCopyWith<_$BleDeviceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
