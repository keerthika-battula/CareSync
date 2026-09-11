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
      sendTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    _AuthInterceptor(storage),
    _LoggingInterceptor(),
    _RetryInterceptor(dio),
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

/// Automatically retries idempotent GET requests on Render cold start (502/503/504) or connection timeouts.
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const int _maxRetries = 3;

  _RetryInterceptor(this._dio);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final method = requestOptions.method.toUpperCase();
    final retryCount = (requestOptions.extra['retryCount'] as int?) ?? 0;

    // Only retry idempotent GET requests
    final isGet = method == 'GET';
    final status = err.response?.statusCode;
    final isTransientStatus = status == 502 || status == 503 || status == 504;
    final isTimeoutOrNetwork = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (isGet && (isTransientStatus || isTimeoutOrNetwork) && retryCount < _maxRetries) {
      final nextAttempt = retryCount + 1;
      final delayMs = nextAttempt * 1500; // 1.5s, 3.0s, 4.5s
      if (kDebugMode) {
        _logger.i('Retrying GET ${requestOptions.uri} (attempt $nextAttempt/$_maxRetries) in ${delayMs}ms...');
      }

      await Future.delayed(Duration(milliseconds: delayMs));

      requestOptions.extra['retryCount'] = nextAttempt;

      try {
        final response = await _dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}

/// Converts DioException into human-readable messages without leaking internal traces or crashing on HTML responses.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _extractCleanErrorMessage(err);

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

  String _extractCleanErrorMessage(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out while reaching CareSync. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Unable to reach CareSync server. Please check your connection or try again shortly.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please check your network security settings.';
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        final data = err.response?.data;

        // Handle cold start / gateway errors (Render waking up)
        if (status == 502 || status == 503 || status == 504) {
          return 'The CareSync server is starting up. Please try again in a few seconds.';
        }

        // Handle structured JSON backend responses safely
        if (data is Map) {
          final serverMsg = data['message']?.toString();
          if (serverMsg != null && serverMsg.isNotEmpty) {
            return serverMsg;
          }
          final serverError = data['error']?.toString();
          if (serverError != null && serverError.isNotEmpty) {
            return serverError;
          }
        }

        // Handle string response (e.g. HTML 502 page from Render / Cloudflare)
        if (data is String && data.isNotEmpty) {
          if (data.contains('<html') || data.contains('<!DOCTYPE') || data.contains('<head>')) {
            if (status >= 500) {
              return 'CareSync server is starting up or temporarily unavailable ($status).';
            }
            return 'Unexpected response from server ($status).';
          }
          if (data.length < 200) {
            return data;
          }
        }

        // Fallback status code mapping
        if (status == 400) {
          return 'Invalid request. Please check the entered data.';
        } else if (status == 401) {
          return 'Your session has expired. Please log in again.';
        } else if (status == 403) {
          return 'Access denied. You do not have permission for this action.';
        } else if (status == 404) {
          return 'The requested resource was not found.';
        } else if (status == 409) {
          return 'This record already exists or conflicts with existing data.';
        } else if (status == 422) {
          return 'Unable to process the submitted information.';
        } else if (status == 429) {
          return 'Too many requests. Please wait a moment and try again.';
        } else if (status >= 500) {
          return 'Server error ($status). Please try again later.';
        }

        return 'An unexpected server error occurred ($status).';

      default:
        if (err.message != null && err.message!.isNotEmpty && !err.message!.contains('DioException')) {
          return err.message!;
        }
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
