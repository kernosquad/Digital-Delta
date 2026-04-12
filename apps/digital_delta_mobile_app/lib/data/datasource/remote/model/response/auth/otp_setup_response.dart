class OtpSetupResponse {
  final String deviceId;
  final String userId;
  final String qrCode;
  final String secret;

  const OtpSetupResponse({
    required this.deviceId,
    required this.userId,
    required this.qrCode,
    required this.secret,
  });

  factory OtpSetupResponse.fromJson(Map<String, dynamic> json) {
    return OtpSetupResponse(
      deviceId: json['device_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      qrCode: json['qr_code']?.toString() ?? '',
      secret: json['secret']?.toString() ?? '',
    );
  }
}
