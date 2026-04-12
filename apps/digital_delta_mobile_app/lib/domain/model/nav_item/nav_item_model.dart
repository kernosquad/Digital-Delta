import 'package:freezed_annotation/freezed_annotation.dart';

part 'nav_item_model.freezed.dart';

@freezed
class NavItemModel with _$NavItemModel {
  const factory NavItemModel({
    required String label,
    required String route,
    required int index,
    String? icon,
  }) = _NavItemModel;
}
