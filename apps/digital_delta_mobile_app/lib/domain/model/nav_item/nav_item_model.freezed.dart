// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nav_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NavItemModel {
  String get label => throw _privateConstructorUsedError;
  String get route => throw _privateConstructorUsedError;
  int get index => throw _privateConstructorUsedError;
  String? get icon => throw _privateConstructorUsedError;

  /// Create a copy of NavItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NavItemModelCopyWith<NavItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NavItemModelCopyWith<$Res> {
  factory $NavItemModelCopyWith(
    NavItemModel value,
    $Res Function(NavItemModel) then,
  ) = _$NavItemModelCopyWithImpl<$Res, NavItemModel>;
  @useResult
  $Res call({String label, String route, int index, String? icon});
}

/// @nodoc
class _$NavItemModelCopyWithImpl<$Res, $Val extends NavItemModel>
    implements $NavItemModelCopyWith<$Res> {
  _$NavItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NavItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? route = null,
    Object? index = null,
    Object? icon = freezed,
  }) {
    return _then(
      _value.copyWith(
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            route: null == route
                ? _value.route
                : route // ignore: cast_nullable_to_non_nullable
                      as String,
            index: null == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                      as int,
            icon: freezed == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NavItemModelImplCopyWith<$Res>
    implements $NavItemModelCopyWith<$Res> {
  factory _$$NavItemModelImplCopyWith(
    _$NavItemModelImpl value,
    $Res Function(_$NavItemModelImpl) then,
  ) = __$$NavItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String label, String route, int index, String? icon});
}

/// @nodoc
class __$$NavItemModelImplCopyWithImpl<$Res>
    extends _$NavItemModelCopyWithImpl<$Res, _$NavItemModelImpl>
    implements _$$NavItemModelImplCopyWith<$Res> {
  __$$NavItemModelImplCopyWithImpl(
    _$NavItemModelImpl _value,
    $Res Function(_$NavItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NavItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? route = null,
    Object? index = null,
    Object? icon = freezed,
  }) {
    return _then(
      _$NavItemModelImpl(
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        route: null == route
            ? _value.route
            : route // ignore: cast_nullable_to_non_nullable
                  as String,
        index: null == index
            ? _value.index
            : index // ignore: cast_nullable_to_non_nullable
                  as int,
        icon: freezed == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$NavItemModelImpl implements _NavItemModel {
  const _$NavItemModelImpl({
    required this.label,
    required this.route,
    required this.index,
    this.icon,
  });

  @override
  final String label;
  @override
  final String route;
  @override
  final int index;
  @override
  final String? icon;

  @override
  String toString() {
    return 'NavItemModel(label: $label, route: $route, index: $index, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NavItemModelImpl &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.route, route) || other.route == route) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @override
  int get hashCode => Object.hash(runtimeType, label, route, index, icon);

  /// Create a copy of NavItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NavItemModelImplCopyWith<_$NavItemModelImpl> get copyWith =>
      __$$NavItemModelImplCopyWithImpl<_$NavItemModelImpl>(this, _$identity);
}

abstract class _NavItemModel implements NavItemModel {
  const factory _NavItemModel({
    required final String label,
    required final String route,
    required final int index,
    final String? icon,
  }) = _$NavItemModelImpl;

  @override
  String get label;
  @override
  String get route;
  @override
  int get index;
  @override
  String? get icon;

  /// Create a copy of NavItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NavItemModelImplCopyWith<_$NavItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
