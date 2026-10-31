import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/rescue_center_model.dart';

class RescueCenterService {
  final ApiClient _client = ApiClient.instance;

  static final List<RescueCenterModel> _fallbackCenters = [
    RescueCenterModel(
      id: 'RC-01',
      name: 'Central Disaster Command HQ',
      stationUnit: 'Rapid Action Battalion 01',
      location: 'Civil Lines, Dehradun',
      latitude: 30.3165,
      longitude: 78.0322,
      contactPhone: '+91 135 2710100',
      activePersonnel: 48,
      availableVehicles: 12,
      status: 'READY',
    ),
    RescueCenterModel(
      id: 'RC-02',
      name: 'Selaqui Industrial Hazmat Post',
      stationUnit: 'Chemical Fire Brigade Squad 4',
      location: 'Selaqui Industrial Area Gate 1',
      latitude: 30.3680,
      longitude: 77.9250,
      contactPhone: '+91 135 2698011',
      activePersonnel: 22,
      availableVehicles: 5,
      status: 'DISPATCHED',
    ),
    RescueCenterModel(
      id: 'RC-03',
      name: 'Mussoorie Foothills SDRF Station',
      stationUnit: 'Mountain Search & Rescue Alpha',
      location: 'Rajpur Road Checkpoint',
      latitude: 30.3800,
      longitude: 78.0700,
      contactPhone: '+91 135 2734122',
      activePersonnel: 30,
      availableVehicles: 8,
      status: 'READY',
    ),
  ];

  Future<List<RescueCenterModel>> getRescueCenters() async {
    try {
      final res = await _client.get(ApiConfig.rescueCentersEndpoint);
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((c) => RescueCenterModel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Backend does not expose rescue centers endpoint yet
    }
    return _fallbackCenters;
  }
}

