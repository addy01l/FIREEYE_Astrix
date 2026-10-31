import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _client = ApiClient.instance;

  Future<UserModel> login(String username, String password) async {
    final demoUser = _demoLogin(username, password);
    if (demoUser != null) {
      await SecureStorageService.saveToken(demoUser.token!);
      await SecureStorageService.saveUsername(demoUser.username);
      await SecureStorageService.saveUserRole(demoUser.role.name);
      return demoUser;
    }

    final response = await _client.post(
      ApiConfig.loginEndpoint,
      data: {'username': username.trim(), 'password': password},
    );
    if (response.data is! Map<String, dynamic>) {
      throw StateError('Backend returned an invalid login response');
    }

    final loginData = response.data as Map<String, dynamic>;
    final token = loginData['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Backend login response did not contain an access token');
    }
    await SecureStorageService.saveToken(token);
    await SecureStorageService.saveUsername(loginData['username'] as String? ?? username);
    await SecureStorageService.saveUserRole((loginData['role'] as String? ?? 'CITIZEN').toLowerCase());

    try {
      final profile = await _client.get(ApiConfig.meEndpoint);
      if (profile.data is Map<String, dynamic>) {
        return UserModel.fromJson({
          ...(profile.data as Map<String, dynamic>),
          'access_token': token,
        });
      }
    } catch (_) {}
    return UserModel.fromJson(loginData);
  }

  Future<UserModel?> restoreSession() async {
    final token = await SecureStorageService.getToken();
    final username = await SecureStorageService.getUsername();
    final role = await SecureStorageService.getUserRole();
    if (token == null || username == null || role == null) return null;
    if (token == 'fire-eye-demo-token') {
      return _buildDemoUser(username);
    }

    try {
      final response = await _client.get(ApiConfig.meEndpoint);
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

  Future<void> logout() => SecureStorageService.clearAll();

  UserModel? _demoLogin(String username, String password) {
    if (password != 'tactical123') return null;
    const demoUsers = {'commander', 'responder', 'volunteer', 'citizen'};
    final normalizedUsername = username.trim().toLowerCase();
    if (!demoUsers.contains(normalizedUsername)) return null;
    return _buildDemoUser(normalizedUsername);
  }

  UserModel _buildDemoUser(String username) {
    final role = UserRole.fromString(username);
    final station = switch (role) {
      UserRole.commander => 'Central Command HQ',
      UserRole.responder => 'Tactical Unit 04',
      UserRole.volunteer => 'Relief Camp Beta',
      UserRole.citizen => 'Civil Sector 7',
    };
    return UserModel(
      id: 'DEMO-${role.name.toUpperCase()}',
      username: username,
      fullName: '${role.displayName} (Demo)',
      email: '$username@fireeye.gov.in',
      role: role,
      token: 'fire-eye-demo-token',
      assignedStation: station,
      phone: '+91 98765 43210',
    );
  }
}
