import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

class UserService {
  final ApiClient _client = ApiClient.instance;

  Future<List<Map<String, dynamic>>> listUsers() async {
    final response = await _client.get(ApiConfig.usersEndpoint);
    if (response.data is List) {
      return (response.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> updateUserRole(String userId, String role) async {
    final response = await _client.patch(
      '${ApiConfig.usersEndpoint}$userId/role',
      data: {'role': role.toLowerCase().trim()},
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw StateError('Failed to update user role');
  }

  Future<Map<String, dynamic>> updateUserStatus(String userId, bool isActive) async {
    final response = await _client.patch(
      '${ApiConfig.usersEndpoint}$userId/status',
      data: {'is_active': isActive},
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw StateError('Failed to update user status');
  }
}
