enum BleDeviceConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting;

  bool get isConnected => this == connected;
  bool get isBusy => this == connecting || this == disconnecting;

  String get label {
    switch (this) {
      case disconnected:
        return 'Disconnected';
      case connecting:
        return 'Connecting…';
      case connected:
        return 'Connected';
      case disconnecting:
        return 'Disconnecting…';
    }
  }
}
