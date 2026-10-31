import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

class SosService {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> createSos({
    required double latitude,
    required double longitude,
    required String emergencyType,
    required String notes,
    String severity = 'CRITICAL',
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      ApiConfig.sosEndpoint,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'emergency_type': emergencyType,
        'severity': severity,
        'notes': notes,
        'sender_device_id': 'MOBILE-CLIENT',
        'via_mesh': 'FALSE',
        'idempotency_key': idempotencyKey,
      },
    );
    if (response.data is! Map<String, dynamic>) {
      throw StateError('Backend returned an invalid SOS response');
    }
    return response.data as Map<String, dynamic>;
  }
}
