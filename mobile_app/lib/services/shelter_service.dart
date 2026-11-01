import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/shelter_model.dart';

class ShelterService {
  final ApiClient _client = ApiClient.instance;

  Future<List<ShelterModel>> getShelters() async {
    try {
      final res = await _client.get(ApiConfig.sheltersEndpoint);
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((s) {
              final json = s as Map<String, dynamic>;
              return ShelterModel.fromJson({
                'id': json['shelter_code'] ?? json['id'],
                'name': json['name'],
                'address': json['facility_type'] ?? 'Emergency shelter',
                'capacity': json['capacity'],
                'occupancy': json['current_occupancy'],
                'latitude': json['latitude'],
                'longitude': json['longitude'],
                'contact_phone': json['contact_phone'],
                'has_medical': json['has_medical_staff'],
                'has_generator': json['has_power_backup'],
                'status': json['is_safe'] == true ? 'OPERATIONAL' : 'OFFLINE',
              });
            })
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    throw StateError('Shelter service returned an invalid response');
  }
}
