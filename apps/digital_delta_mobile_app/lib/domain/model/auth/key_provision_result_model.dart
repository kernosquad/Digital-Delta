class KeyProvisionResultModel {
  final String deviceId;
  final String keyId;
  final String expiresAt;

  const KeyProvisionResultModel({
    required this.deviceId,
    required this.keyId,
    required this.expiresAt,
  });
}
