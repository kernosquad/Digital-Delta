enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  bluetooth,
  vpn,
  other,
  none;

  String get displayName {
    switch (this) {
      case wifi:
        return 'Wi-Fi';
      case mobile:
        return 'Mobile Data';
      case ethernet:
        return 'Ethernet';
      case bluetooth:
        return 'Bluetooth';
      case vpn:
        return 'VPN';
      case other:
        return 'Internet';
      case none:
        return 'No Connection';
    }
  }

  String get onlineMessage {
    switch (this) {
      case wifi:
        return 'You are connected via Wi-Fi';
      case mobile:
        return 'You are connected via Mobile Data';
      case ethernet:
        return 'You are connected via Ethernet';
      case bluetooth:
        return 'You are connected via Bluetooth';
      case vpn:
        return 'You are connected via VPN';
      case other:
        return 'You are connected to the Internet';
      case none:
        return 'No Internet Connection';
    }
  }

  String get offlineMessage =>
      'No internet connection. Please check your Wi-Fi, Mobile Data, or Bluetooth and try again.';

  bool get isConnected => this != none;
}
