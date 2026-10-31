import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

class SosService {
  final ApiClient _client = ApiClient.instance;
  static const String _offlineQueueKey = 'offline_sos_queue';

  Future<Map<String, dynamic>> createSos({
    required double latitude,
    required double longitude,
    required String emergencyType,
    required String notes,
    String severity = 'CRITICAL',
    String? idempotencyKey,
  }) async {
    final payload = {
      'latitude': latitude,
      'longitude': longitude,
      'emergency_type': emergencyType,
      'severity': severity,
      'notes': notes,
      'sender_device_id': 'MOBILE-CLIENT',
      'via_mesh': 'FALSE',
      'idempotency_key': idempotencyKey,
    };

    try {
      final response = await _client.post(
        ApiConfig.sosEndpoint,
        data: payload,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw StateError('Backend returned an invalid SOS response');
    } catch (e) {
      // Offline fallback: save to persistent offline queue
      await _queueOfflineSos(payload);
      return {
        'sos_code': idempotencyKey ?? 'SOS-OFFLINE',
        'status': 'QUEUED_OFFLINE',
        'is_offline': true,
      };
    }
  }

  Future<void> _queueOfflineSos(Map<String, dynamic> item) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final list = sp.getStringList(_offlineQueueKey) ?? [];
      list.add(jsonEncode({
        ...item,
        'queued_at': DateTime.now().toIso8601String(),
      }));
      await sp.setStringList(_offlineQueueKey, list);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final list = sp.getStringList(_offlineQueueKey) ?? [];
      return list
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> syncOfflineQueue() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final list = sp.getStringList(_offlineQueueKey) ?? [];
      if (list.isEmpty) return 0;

      int synced = 0;
      final remaining = <String>[];

      for (final raw in list) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final res = await _client.post(ApiConfig.sosEndpoint, data: data);
          if (res.statusCode == 200 || res.statusCode == 201) {
            synced++;
          } else {
            remaining.add(raw);
          }
        } catch (_) {
          remaining.add(raw);
        }
      }

      await sp.setStringList(_offlineQueueKey, remaining);
      return synced;
    } catch (_) {
      return 0;
    }
  }
}
