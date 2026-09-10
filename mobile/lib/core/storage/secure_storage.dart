import 'package:caresync/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

class SecureStorage {
  SecureStorage()
      : _storage = kIsWeb
            ? null
            : const FlutterSecureStorage(
                aOptions: AndroidOptions(encryptedSharedPreferences: true),
                iOptions: IOSOptions(
                  accessibility: KeychainAccessibility.first_unlock_this_device,
                ),
              );

  final FlutterSecureStorage? _storage;
  final Map<String, String> _memory = {};

  // ── Access Token ────────────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) => save(AppConstants.accessTokenKey, token);
  Future<String?> getAccessToken() => read(AppConstants.accessTokenKey);
  Future<void> deleteAccessToken() => delete(AppConstants.accessTokenKey);

  // ── Refresh Token ────────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) => save(AppConstants.refreshTokenKey, token);
  Future<String?> getRefreshToken() => read(AppConstants.refreshTokenKey);
  Future<void> deleteRefreshToken() => delete(AppConstants.refreshTokenKey);

  // ── User ID ──────────────────────────────────────────────────────────────────

  Future<void> saveUserId(String id) => save(AppConstants.userIdKey, id);
  Future<String?> getUserId() => read(AppConstants.userIdKey);
  Future<void> deleteUserId() => delete(AppConstants.userIdKey);

  // ── User Role & Info ─────────────────────────────────────────────────────────

  Future<void> saveUserRole(String role) => save(AppConstants.userRoleKey, role);
  Future<String?> getUserRole() => read(AppConstants.userRoleKey);

  Future<void> saveUserEmail(String email) => save(AppConstants.userEmailKey, email);
  Future<String?> getUserEmail() => read(AppConstants.userEmailKey);

  Future<void> saveUserName(String name) => save(AppConstants.userNameKey, name);
  Future<String?> getUserName() => read(AppConstants.userNameKey);

  // ── Generic ──────────────────────────────────────────────────────────────────

  Future<void> save(String key, String value) async {
    if (kIsWeb) {
      _memory[key] = value;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } catch (_) {}
    } else {
      await _storage!.write(key: key, value: value);
    }
  }

  Future<String?> read(String key) async {
    if (kIsWeb) {
      if (_memory.containsKey(key)) return _memory[key];
      try {
        final prefs = await SharedPreferences.getInstance();
        final val = prefs.getString(key);
        if (val != null) _memory[key] = val;
        return val;
      } catch (_) {
        return null;
      }
    } else {
      return _storage!.read(key: key);
    }
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      _memory.remove(key);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } catch (_) {}
    } else {
      await _storage!.delete(key: key);
    }
  }

  /// Clears all stored secure data (use on logout).
  Future<void> clearAll() async {
    if (kIsWeb) {
      _memory.clear();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}
    } else {
      await _storage!.deleteAll();
    }
  }
}
