import 'package:dio/dio.dart';

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _client = ApiClient.instance;
  final Dio _supabase = Dio();

  Future<UserModel> login(String username, String password) async {
    // 1. Try Supabase Auth if configured and email format is entered
    if (ApiConfig.hasSupabaseConfig && username.contains('@')) {
      try {
        final response = await _supabase.post(
          '${ApiConfig.supabaseUrl}/auth/v1/token?grant_type=password',
          data: {'email': username.trim(), 'password': password},
          options: Options(headers: {'apikey': ApiConfig.supabaseAnonKey}),
        );
        if (response.data is Map<String, dynamic>) {
          final loginData = Map<String, dynamic>.from(response.data as Map);
          final token = loginData['access_token'] as String?;
          if (token != null && token.isNotEmpty) {
            await SecureStorageService.saveToken(token);
            final refreshToken = loginData['refresh_token'] as String?;
            if (refreshToken != null) await SecureStorageService.saveRefreshToken(refreshToken);
            final authUser = Map<String, dynamic>.from(loginData['user'] as Map);
            await SecureStorageService.saveUsername((authUser['email'] as String?) ?? username.trim());
            // Anyone logging in via Supabase is granted ADMIN / Commander clearance
            await SecureStorageService.saveUserRole('admin');
            return UserModel.fromJson({
              'id': authUser['id']?.toString() ?? 'sb-user',
              'username': (authUser['email'] as String?) ?? username.trim(),
              'email': (authUser['email'] as String?) ?? username.trim(),
              'role': 'admin',
              'full_name': (authUser['user_metadata'] as Map?)?['full_name'] as String? ?? username.trim(),
              'access_token': token,
            });
          }
        }
      } on DioException catch (e) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final desc = errorData['error_description'] ?? errorData['msg'] ?? errorData['message'];
          if (desc != null) throw StateError(desc.toString());
        }
        if (e.response?.statusCode == 400) {
          throw StateError('Invalid email or password. Please verify your Supabase credentials.');
        }
      }
    }

    // 2. Direct Backend Login (supports official seeded roles like "commander" / "securepassword")
    try {
      final response = await _client.post(
        ApiConfig.loginEndpoint,
        data: {'username': username.trim(), 'password': password},
      );
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        if (token != null && token.isNotEmpty) {
          await SecureStorageService.saveToken(token);
          final refreshToken = data['refresh_token'] as String?;
          if (refreshToken != null) await SecureStorageService.saveRefreshToken(refreshToken);
          await SecureStorageService.saveUsername(data['username'] as String? ?? username.trim());
          await SecureStorageService.saveUserRole(data['role'] as String? ?? 'citizen');
          return UserModel.fromJson(data);
        }
      }
      throw StateError('Invalid username or password');
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? (e.response?.data as Map)['detail']?.toString() : null;
      throw StateError(detail ?? 'Authentication failed: Check username/email and password.');
    }
  }

  Future<void> register({required String email, required String password, required String fullName}) async {
    if (ApiConfig.hasSupabaseConfig) {
      try {
        await _supabase.post(
          '${ApiConfig.supabaseUrl}/auth/v1/signup',
          data: {'email': email.trim(), 'password': password, 'data': {'full_name': fullName}},
          options: Options(headers: {'apikey': ApiConfig.supabaseAnonKey}),
        );
        return;
      } on DioException catch (e) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final desc = errorData['error_description'] ?? errorData['msg'] ?? errorData['message'];
          if (desc != null) throw StateError(desc.toString());
        }
      }
    }
    await _client.post(
      ApiConfig.registerEndpoint,
      data: {
        'username': email.split('@').first,
        'email': email.trim(),
        'password': password,
        'full_name': fullName,
        'role': 'CITIZEN',
      },
    );
  }

  Future<UserModel?> restoreSession() async {
    final token = await SecureStorageService.getToken();
    final username = await SecureStorageService.getUsername();
    final role = await SecureStorageService.getUserRole();
    if (token == null || username == null || role == null) return null;
    try {
      Response<dynamic> response;
      try {
        response = await _client.get(ApiConfig.meEndpoint);
      } on DioException catch (e) {
        if (e.response?.statusCode != 401 || !await _refreshSession()) rethrow;
        response = await _client.get(ApiConfig.meEndpoint);
      }
      if (response.data is Map<String, dynamic>) {
        return UserModel.fromJson({
          ...(response.data as Map<String, dynamic>),
          'access_token': token,
        });
      }
    } catch (_) {
      await SecureStorageService.clearAll();
    }
    return null;
  }

  Future<bool> _refreshSession() async {
    if (!ApiConfig.hasSupabaseConfig) return false;
    final refreshToken = await SecureStorageService.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await _supabase.post(
        '${ApiConfig.supabaseUrl}/auth/v1/token?grant_type=refresh_token',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'apikey': ApiConfig.supabaseAnonKey}),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      await SecureStorageService.saveToken(data['access_token'] as String);
      await SecureStorageService.saveRefreshToken(data['refresh_token'] as String);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    final token = await SecureStorageService.getToken();
    if (ApiConfig.hasSupabaseConfig && token != null) {
      try {
        await _supabase.post('${ApiConfig.supabaseUrl}/auth/v1/logout', options: Options(headers: {'apikey': ApiConfig.supabaseAnonKey, 'Authorization': 'Bearer $token'}));
      } catch (_) {}
    }
    await SecureStorageService.clearAll();
  }

  Future<UserModel> updateProfile({String? fullName, String? phone}) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName;
    if (phone != null) payload['phone'] = phone;
    final response = await _client.patch(
      ApiConfig.meEndpoint,
      data: payload,
    );
    if (response.data is Map<String, dynamic>) {
      final json = Map<String, dynamic>.from(response.data as Map);
      final token = await SecureStorageService.getToken();
      if (token != null) json['access_token'] = token;
      return UserModel.fromJson(json);
    }
    throw StateError('Failed to update profile');
  }
}