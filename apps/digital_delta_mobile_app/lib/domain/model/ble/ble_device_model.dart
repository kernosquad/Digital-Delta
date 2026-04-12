import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enum/ble_connection_state.dart';

part 'ble_device_model.freezed.dart';

@freezed
class BleDeviceModel with _$BleDeviceModel {
  const factory BleDeviceModel({
    required String id,
    required String name,
    required int rssi,
    @Default(BleDeviceConnectionState.disconnected)
    BleDeviceConnectionState connectionState,
  }) = _BleDeviceModel;
}
