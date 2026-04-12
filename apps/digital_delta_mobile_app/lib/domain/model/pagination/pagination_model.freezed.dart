// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pagination_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PaginationModel<T> {
  List<T> get items => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;
  int get totalPages => throw _privateConstructorUsedError;

  /// Create a copy of PaginationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaginationModelCopyWith<T, PaginationModel<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginationModelCopyWith<T, $Res> {
  factory $PaginationModelCopyWith(
    PaginationModel<T> value,
    $Res Function(PaginationModel<T>) then,
  ) = _$PaginationModelCopyWithImpl<T, $Res, PaginationModel<T>>;
  @useResult
  $Res call({List<T> items, int total, int page, int limit, int totalPages});
}

/// @nodoc
class _$PaginationModelCopyWithImpl<T, $Res, $Val extends PaginationModel<T>>
    implements $PaginationModelCopyWith<T, $Res> {
  _$PaginationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaginationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? totalPages = null,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<T>,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPages: null == totalPages
                ? _value.totalPages
                : totalPages // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaginationModelImplCopyWith<T, $Res>
    implements $PaginationModelCopyWith<T, $Res> {
  factory _$$PaginationModelImplCopyWith(
    _$PaginationModelImpl<T> value,
    $Res Function(_$PaginationModelImpl<T>) then,
  ) = __$$PaginationModelImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({List<T> items, int total, int page, int limit, int totalPages});
}

/// @nodoc
class __$$PaginationModelImplCopyWithImpl<T, $Res>
    extends _$PaginationModelCopyWithImpl<T, $Res, _$PaginationModelImpl<T>>
    implements _$$PaginationModelImplCopyWith<T, $Res> {
  __$$PaginationModelImplCopyWithImpl(
    _$PaginationModelImpl<T> _value,
    $Res Function(_$PaginationModelImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of PaginationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? totalPages = null,
  }) {
    return _then(
      _$PaginationModelImpl<T>(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<T>,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPages: null == totalPages
            ? _value.totalPages
            : totalPages // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$PaginationModelImpl<T> implements _PaginationModel<T> {
  const _$PaginationModelImpl({
    required final List<T> items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  }) : _items = items;

  final List<T> _items;
  @override
  List<T> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  final int limit;
  @override
  final int totalPages;

  @override
  String toString() {
    return 'PaginationModel<$T>(items: $items, total: $total, page: $page, limit: $limit, totalPages: $totalPages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginationModelImpl<T> &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    total,
    page,
    limit,
    totalPages,
  );

  /// Create a copy of PaginationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginationModelImplCopyWith<T, _$PaginationModelImpl<T>> get copyWith =>
      __$$PaginationModelImplCopyWithImpl<T, _$PaginationModelImpl<T>>(
        this,
        _$identity,
      );
}

abstract class _PaginationModel<T> implements PaginationModel<T> {
  const factory _PaginationModel({
    required final List<T> items,
    required final int total,
    required final int page,
    required final int limit,
    required final int totalPages,
  }) = _$PaginationModelImpl<T>;

  @override
  List<T> get items;
  @override
  int get total;
  @override
  int get page;
  @override
  int get limit;
  @override
  int get totalPages;

  /// Create a copy of PaginationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaginationModelImplCopyWith<T, _$PaginationModelImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}
