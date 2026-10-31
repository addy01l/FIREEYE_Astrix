import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  static const _secureStorage = FlutterSecureStorage();

  // Token storage
  static Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: AppConstants.keyAuthToken, value: token);
    } catch (_) {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(AppConstants.keyAuthToken, token);
    }
  }

  static Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.keyAuthToken);
      if (token != null) return token;
    } catch (_) {}
    final sp = await SharedPreferences.getInstance();
    return sp.getString(AppConstants.keyAuthToken);
  }

  static Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: AppConstants.keyAuthToken);
    } catch (_) {}
    final sp = await SharedPreferences.getInstance();
    await sp.remove(AppConstants.keyAuthToken);
  }

  // Non-sensitive preferences
  static Future<void> saveUsername(String username) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(AppConstants.keyUsername, username);
  }

  static Future<String?> getUsername() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(AppConstants.keyUsername);
  }

  static Future<void> saveUserRole(String role) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(AppConstants.keyUserRole, role);
  }

  static Future<String?> getUserRole() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(AppConstants.keyUserRole);
  }

  static Future<void> saveApiBaseUrl(String url) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(AppConstants.keyApiBaseUrl, url);
  }

  static Future<String?> getApiBaseUrl() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(AppConstants.keyApiBaseUrl);
  }

  static Future<void> clearAll() async {
    await clearToken();
    final sp = await SharedPreferences.getInstance();
    await sp.remove(AppConstants.keyUserRole);
    await sp.remove(AppConstants.keyUsername);
  }
}

