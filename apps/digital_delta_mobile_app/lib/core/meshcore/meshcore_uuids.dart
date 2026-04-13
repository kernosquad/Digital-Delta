// MeshCore BLE Nordic UART Service (NUS) constants.
//
// These match exactly `lib/connector/meshcore_uuids.dart` in the meshcore-open
// reference implementation (https://github.com/zjs81/meshcore-open).
//
// Module 2 — BLE Device Discovery & Connection
// Module 3 — MeshCore LoRa communication protocol

/// Nordic UART Service UUIDs used by all MeshCore companion radio devices.
class MeshCoreUuids {
  MeshCoreUuids._();

  /// NUS GATT service UUID.
  static const String service = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

  /// RX characteristic — host writes frames TO the device.
  static const String rxCharacteristic = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  /// TX characteristic — device sends frames TO the host (notify).
  static const String txCharacteristic = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  /// All known device name prefixes for MeshCore companion radios.
  /// Devices advertising any of these prefixes will appear in the scanner.
  static const List<String> deviceNamePrefixes = [
    'MeshCore-',
    'Whisper-',
    'WisCore-',
    'Seeed',
    'Lilygo',
    'HT-',
    'LowMesh_MC_',
  ];
}
