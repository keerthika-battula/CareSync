import 'package:caresync/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

class SecureStorage {
  SecureStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  final FlutterSecureStorage _storage;

  // ── Access Token ────────────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: AppConstants.accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
  }

  // ── Refresh Token ────────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  // ── User ID ──────────────────────────────────────────────────────────────────

  Future<void> saveUserId(String id) async {
    await _storage.write(key: AppConstants.userIdKey, value: id);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: AppConstants.userIdKey);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: AppConstants.userIdKey);
  }

  // ── Generic ──────────────────────────────────────────────────────────────────

  Future<void> save(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Clears all stored secure data (use on logout).
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
