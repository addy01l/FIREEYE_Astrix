import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/anomaly_model.dart';

class AnomalyService {
  final ApiClient _client = ApiClient.instance;

  Future<bool> checkBackendHealth() async {
    try {
      final res = await _client.get(ApiConfig.healthEndpoint);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<AnomalyModel>> fetchLiveAnomalies() async {
    try {
      final res = await _client.get(ApiConfig.zonesEndpoint);
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).asMap().entries.map((entry) {
          final zone = entry.value as Map<String, dynamic>;
          return AnomalyModel.fromJson({
            'id': entry.key,
            'latitude': zone['center_lat'],
            'longitude': zone['center_lng'],
            'brightness': zone['risk_score'],
            'frp': zone['rainfall_24h'],
            'is_wildfire': false,
          });
        })
            .toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }
}
