import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enum/connection_type.dart';

part 'connectivity_status_model.freezed.dart';

@freezed
class ConnectivityStatusModel with _$ConnectivityStatusModel {
  const factory ConnectivityStatusModel.online({required ConnectionType type}) =
      OnlineConnectivity;

  const factory ConnectivityStatusModel.offline() = OfflineConnectivity;
}
