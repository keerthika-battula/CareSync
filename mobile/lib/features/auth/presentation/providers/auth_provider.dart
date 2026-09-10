import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/core/storage/secure_storage.dart';
import 'package:caresync/features/auth/data/models/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  AuthNotifier(this.ref) : super(const AsyncData(null));

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/login', data: LoginRequest(email: email, password: password).toJson());
      
      final authData = AuthResponse.fromJson(response.data);
      final storage = ref.read(secureStorageProvider);
      
      await storage.saveAccessToken(authData.accessToken);
      await storage.saveRefreshToken(authData.refreshToken);
      
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> register(String firstName, String lastName, String email, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final req = RegisterRequest(firstName: firstName, lastName: lastName, email: email, password: password);
      final response = await dio.post('/auth/register', data: req.toJson());
      
      final authData = AuthResponse.fromJson(response.data);
      final storage = ref.read(secureStorageProvider);
      
      await storage.saveAccessToken(authData.accessToken);
      await storage.saveRefreshToken(authData.refreshToken);
      
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}
