class FcmTokenRegistration {
  final String token;
  final String deviceType;

  FcmTokenRegistration({required this.token, required this.deviceType});
  Map<String, dynamic> toJson() => {'token': token, 'deviceType': deviceType};
}
