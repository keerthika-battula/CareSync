import 'package:dio/dio.dart';

class AppErrorFormatter {
  AppErrorFormatter._();

  static String format(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';

    if (error is DioException) {
      if (error.error is String && (error.error as String).isNotEmpty) {
        return error.error as String;
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }

    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11).trim();
    }

    if (str.contains('TypeError') || str.contains('CastError')) {
      return 'Received an unexpected response format from the server. Please try again.';
    }

    return str;
  }
}
