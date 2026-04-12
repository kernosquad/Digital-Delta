class OtpSetupResultModel {
  final String deviceId;
  final String userId;
  final String qrCode;
  final String secret;

  const OtpSetupResultModel({
    required this.deviceId,
    required this.userId,
    required this.qrCode,
    required this.secret,
  });
}
