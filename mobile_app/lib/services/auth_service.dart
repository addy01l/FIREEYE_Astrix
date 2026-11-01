import 'package:dio/dio.dart';

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _client = ApiClient.instance;
  final Dio _supabase = Dio();

  Future<UserModel> login(String username, String password) async {
    if (!ApiConfig.hasSupabaseConfig) throw StateError('Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY at build time.');
    final response = await _supabase.post(
      '${ApiConfig.supabaseUrl}/auth/v1/token?grant_type=password',
      data: {'email': username.trim(), 'password': password},
      options: Options(headers: {'apikey': ApiConfig.supabaseAnonKey}),
    );
    if (response.data is! Map<String, dynamic>) {
      throw StateError('Backend returned an invalid login response');
    }

    final loginData = Map<String, dynamic>.from(response.data as Map);
    final token = loginData['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Backend login response did not contain an access token');
    }
    await SecureStorageService.saveToken(token);
    final refreshToken = loginData['refresh_token'] as String?;
    if (refreshToken != null) await SecureStorageService.saveRefreshToken(refreshToken);
    final authUser = Map<String, dynamic>.from(loginData['user'] as Map);
    await SecureStorageService.saveUsername((authUser['email'] as String?) ?? username.trim());
    final appMetadata = Map<String, dynamic>.from(authUser['app_metadata'] as Map? ?? const {});
    await SecureStorageService.saveUserRole((appMetadata['role'] as String? ?? 'CITIZEN').toLowerCase());

    try {
      final profile = await _client.get(ApiConfig.meEndpoint);
      if (profile.data is Map<String, dynamic>) {
        return UserModel.fromJson({
          ...(profile.data as Map<String, dynamic>),
          'access_token': token,
        });
      }
    } catch (e) {
      await SecureStorageService.clearAll();
      throw StateError('The API could not validate the Supabase identity and role: $e');
    }
    await SecureStorageService.clearAll();
    throw StateError('The API returned no profile for this Supabase account');
  }

  Future<void> register({required String email, required String password, required String fullName}) async {
    if (!ApiConfig.hasSupabaseConfig) throw StateError('Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY at build time.');
    await _supabase.post(
      '${ApiConfig.supabaseUrl}/auth/v1/signup',
      data: {'email': email.trim(), 'password': password, 'data': {'full_name': fullName}},
      options: Options(headers: {'apikey': ApiConfig.supabaseAnonKey}),
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

}
