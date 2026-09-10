import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // API
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        return 'http://localhost:8080';
      }
      return 'https://caresync-4dfr.onrender.com';
    }
    return 'http://10.0.2.2:8080';
  }
  static const String apiPrefix = '/api';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Auth
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';

  // App
  static const String appName = 'CareSync';
  static const String appTagline = 'Your Care. In Sync. On Time.';

  // Medicine Actions
  static const String actionTaken = 'TAKEN';
  static const String actionSkipped = 'SKIPPED';
  static const String actionSnoozed = 'SNOOZED';

  // Appointment Status
  static const String statusUpcoming = 'UPCOMING';
  static const String statusCompleted = 'COMPLETED';
  static const String statusCancelled = 'CANCELLED';

  // Document Types
  static const String docPrescription = 'PRESCRIPTION';
  static const String docLabReport = 'LAB_REPORT';
  static const String docMedicalReport = 'MEDICAL_REPORT';
  static const String docInsurance = 'INSURANCE';
  static const String docOther = 'OTHER';
}
