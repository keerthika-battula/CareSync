import 'package:caresync/core/constants/app_constants.dart';
import 'package:caresync/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    _AuthInterceptor(storage),
    _LoggingInterceptor(),
    _ErrorInterceptor(),
  ]);

  return dio;
});

/// Attaches the Bearer token from secure storage to every request.
class _AuthInterceptor extends Interceptor {
  const _AuthInterceptor(this._storage);

  final SecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // TODO: implement token refresh logic here
      // For now, just propagate the error
      _logger.w('401 Unauthorized — token may be expired.');
    }
    handler.next(err);
  }
}

/// Logs requests and responses in debug mode.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.d('[REQ] ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.d('[RES] ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.e('[ERR] ${err.response?.statusCode} ${err.message}');
    }
    handler.next(err);
  }
}

/// Converts DioException into a human-readable message.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please check your network.';
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please try again.';
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        if (status >= 500) {
          message = 'Server error ($status). Please try again later.';
        } else if (status == 404) {
          message = 'Resource not found.';
        } else if (status == 403) {
          message = 'Access denied.';
        } else if (status == 401) {
          message = 'Session expired. Please log in again.';
        } else {
          message = err.response?.data?['message'] as String? ??
              'An unexpected error occurred.';
        }
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
      default:
        message = err.message ?? 'An unexpected error occurred.';
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: message,
        message: message,
      ),
    );
  }
}
