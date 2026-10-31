import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/shelter_model.dart';

class ShelterService {
  final ApiClient _client = ApiClient.instance;

  static final List<ShelterModel> _fallbackShelters = [
    ShelterModel(
      id: 'SHL-01',
      name: 'Doon Central Relief Center',
      address: 'Sector 4, Rajpur Road, Dehradun',
      capacity: 500,
      occupancy: 210,
      latitude: 30.3340,
      longitude: 78.0550,
      contactPhone: '+91 94101 22334',
      hasMedical: true,
      hasGenerator: true,
      status: 'OPERATIONAL',
    ),
    ShelterModel(
      id: 'SHL-02',
      name: 'Selaqui Government Secondary Camp',
      address: 'Main Industrial Bypass, Selaqui',
      capacity: 350,
      occupancy: 140,
      latitude: 30.3700,
      longitude: 77.9300,
      contactPhone: '+91 98370 66551',
      hasMedical: false,
      hasGenerator: true,
      status: 'OPERATIONAL',
    ),
    ShelterModel(
      id: 'SHL-03',
      name: 'Clement Town Community Auditorium',
      address: 'Post Office Road, Clement Town',
      capacity: 400,
      occupancy: 375,
      latitude: 30.2680,
      longitude: 78.0080,
      contactPhone: '+91 97601 44332',
      hasMedical: true,
      hasGenerator: false,
      status: 'NEAR CAPACITY',
    ),
    ShelterModel(
      id: 'SHL-04',
      name: 'Premnagar Regional Sports Stadium',
      address: 'Chakrata Road, Dehradun',
      capacity: 650,
      occupancy: 85,
      latitude: 30.3390,
      longitude: 77.9620,
      contactPhone: '+91 94111 99001',
      hasMedical: true,
      hasGenerator: true,
      status: 'OPERATIONAL',
    ),
  ];

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
      // Backend does not expose shelters endpoint yet
    }
    return _fallbackShelters;
  }
}
