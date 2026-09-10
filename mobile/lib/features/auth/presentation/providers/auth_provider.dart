import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/core/storage/secure_storage.dart';
import 'package:caresync/features/auth/data/models/auth_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isLoading;
  final Object? error;
  final UserModel? user;
  final bool isInitialized;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get hasError => error != null;

  AuthState copyWith({
    bool? isLoading,
    Object? error,
    UserModel? user,
    bool? isInitialized,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      user: user ?? this.user,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref);
  notifier.checkAuth();
  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState());

  Future<void> checkAuth() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(isInitialized: true, user: null);
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/v1/users/me');
      final data = response.data['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data);
      await storage.saveUserRole(user.role);
      await storage.saveUserName(user.fullName);
      await storage.saveUserEmail(user.email);
      await storage.saveUserId(user.id);
      state = state.copyWith(isInitialized: true, user: user);
    } catch (_) {
      final cachedRole = await storage.getUserRole();
      final cachedEmail = await storage.getUserEmail();
      final cachedId = await storage.getUserId();
      final cachedName = await storage.getUserName();
      if (cachedRole != null && cachedId != null) {
        final names = (cachedName ?? '').split(' ');
        state = state.copyWith(
          isInitialized: true,
          user: UserModel(
            id: cachedId,
            email: cachedEmail ?? '',
            firstName: names.isNotEmpty ? names.first : '',
            lastName: names.length > 1 ? names.sublist(1).join(' ') : '',
            role: cachedRole,
          ),
        );
      } else {
        await storage.clearAll();
        state = state.copyWith(isInitialized: true, user: null);
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/auth/login',
        data: LoginRequest(email: email.trim(), password: password).toJson(),
      );

      final authData = AuthResponse.fromJson(response.data);
      final storage = ref.read(secureStorageProvider);

      await storage.saveAccessToken(authData.accessToken);
      await storage.saveRefreshToken(authData.refreshToken);

      UserModel? user = authData.user;
      if (user == null) {
        final meRes = await dio.get('/v1/users/me');
        user = UserModel.fromJson(meRes.data['data']);
      }

      await storage.saveUserId(user.id);
      await storage.saveUserRole(user.role);
      await storage.saveUserName(user.fullName);
      await storage.saveUserEmail(user.email);

      state = state.copyWith(
        isLoading: false,
        user: user,
        isInitialized: true,
      );
      return true;
    } catch (e) {
      String errorMessage = 'Login failed. Please check your credentials.';
      if (e is DioException && e.response?.data != null && e.response?.data is Map) {
        errorMessage = (e.response!.data as Map)['message']?.toString() ?? errorMessage;
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> register(String firstName, String lastName, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioProvider);
      final req = RegisterRequest(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        password: password,
      );
      final response = await dio.post('/auth/register', data: req.toJson());

      final authData = AuthResponse.fromJson(response.data);
      final storage = ref.read(secureStorageProvider);

      await storage.saveAccessToken(authData.accessToken);
      await storage.saveRefreshToken(authData.refreshToken);

      UserModel? user = authData.user;
      if (user == null) {
        final meRes = await dio.get('/v1/users/me');
        user = UserModel.fromJson(meRes.data['data']);
      }

      await storage.saveUserId(user.id);
      await storage.saveUserRole(user.role);
      await storage.saveUserName(user.fullName);
      await storage.saveUserEmail(user.email);

      state = state.copyWith(
        isLoading: false,
        user: user,
        isInitialized: true,
      );
      return true;
    } catch (e) {
      String errorMessage = 'Registration failed. Please try again.';
      if (e is DioException && e.response?.data != null && e.response?.data is Map) {
        errorMessage = (e.response!.data as Map)['message']?.toString() ?? errorMessage;
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.clearAll();
    state = const AuthState(isInitialized: true);
  }

  Future<String> requestPasswordReset(String email) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );
      final message = response.data['message']?.toString() ??
          'If the account exists, a password reset code has been sent.';
      return message;
    } catch (e) {
      String errorMessage = 'Failed to send reset code. Please try again.';
      if (e is DioException && e.response?.data != null && e.response?.data is Map) {
        errorMessage = (e.response!.data as Map)['message']?.toString() ?? errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  Future<String> resetPassword(String email, String code, String newPassword) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/auth/reset-password',
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
      );
      final message = response.data['message']?.toString() ??
          'Password has been reset successfully. Please sign in with your new password.';
      return message;
    } catch (e) {
      String errorMessage = 'Failed to reset password. Please check your verification code.';
      if (e is DioException && e.response?.data != null && e.response?.data is Map) {
        errorMessage = (e.response!.data as Map)['message']?.toString() ?? errorMessage;
      }
      throw Exception(errorMessage);
    }
  }
}
