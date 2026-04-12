class KeyProvisionResponse {
  final String deviceId;
  final String keyId;
  final String expiresAt;

  const KeyProvisionResponse({
    required this.deviceId,
    required this.keyId,
    required this.expiresAt,
  });

  factory KeyProvisionResponse.fromJson(Map<String, dynamic> json) {
    return KeyProvisionResponse(
      deviceId: json['device_id']?.toString() ?? '',
      keyId: json['key_id']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString() ?? '',
    );
  }
}
