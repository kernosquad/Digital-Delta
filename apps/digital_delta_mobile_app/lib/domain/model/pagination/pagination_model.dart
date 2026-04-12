import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_model.freezed.dart';

@freezed
class PaginationModel<T> with _$PaginationModel<T> {
  const factory PaginationModel({
    required List<T> items,
    required int total,
    required int page,
    required int limit,
    required int totalPages,
  }) = _PaginationModel;
}
