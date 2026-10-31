import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/incident_model.dart';

class IncidentService {
  final ApiClient _client = ApiClient.instance;
  static final List<IncidentModel> _localIncidents = [
    IncidentModel(
      id: 'INC-9481',
      title: 'Chemical Storage Thermal Flare',
      type: 'Industrial Fire',
      severity: 'CRITICAL',
      status: 'ACTIVE',
      latitude: 30.3662,
      longitude: 77.9221,
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      description: 'Intense thermal spike near solvent storage tanks. FRP measured at 42.8 MW.',
      locationName: 'Selaqui Industrial Corridor, Dehradun',
      source: 'NASA FIRMS VIIRS (375m)',
      frp: 42.8,
      brightness: 368.4,
    ),
    IncidentModel(
      id: 'INC-8832',
      title: 'Monsoon Slope Debris Slide',
      type: 'Landslide',
      severity: 'CRITICAL',
      status: 'DISPATCHED',
      latitude: 30.3842,
      longitude: 78.0754,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      description: 'Hill destabilization blocked arterial evacuation link. 2 vehicles affected.',
      locationName: 'Rajpur Road / Mussoorie Bypass',
      source: 'Field Observer Report',
    ),
    IncidentModel(
      id: 'INC-7124',
      title: 'River Swell & Basin Inundation',
      type: 'Flash Flood',
      severity: 'WARNING',
      status: 'ACTIVE',
      latitude: 30.2921,
      longitude: 78.0125,
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
      description: 'Stream water reached 1.2m depth in residential pockets.',
      locationName: 'Clement Town Drainage Basin',
      source: 'IMD Sensor Network',
    ),
    IncidentModel(
      id: 'INC-6045',
      title: 'Refinery Normalized Flare Stack',
      type: 'Routine Flare',
      severity: 'SAFE',
      status: 'RESOLVED',
      latitude: 30.3420,
      longitude: 77.9510,
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
      description: 'Normal process flare within designated environmental tolerance limits.',
      locationName: 'Petrochemical Refining Unit 3',
      source: 'XGBoost Baseline Model',
      frp: 11.2,
      brightness: 324.1,
    ),
  ];

  Future<List<IncidentModel>> getIncidents() async {
    try {
      final res = await _client.get(ApiConfig.incidentsEndpoint);
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).map((item) {
          final zone = item as Map<String, dynamic>;
          final level = (zone['risk_level'] as String? ?? 'LOW').toUpperCase();
          return IncidentModel(
            id: zone['zone_code']?.toString() ?? 'ZONE',
            title: zone['name'] as String? ?? 'Monitored risk zone',
            type: 'Landslide Risk',
            severity: level == 'HIGH' ? 'CRITICAL' : level == 'MEDIUM' ? 'WARNING' : 'SAFE',
            status: level == 'LOW' ? 'RESOLVED' : 'ACTIVE',
            latitude: (zone['center_lat'] as num?)?.toDouble() ?? 0,
            longitude: (zone['center_lng'] as num?)?.toDouble() ?? 0,
            timestamp: DateTime.now(),
            description: 'Risk score ${(zone['risk_score'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}; ${zone['vulnerable_population'] ?? 0} vulnerable people.',
            locationName: zone['name'] as String? ?? 'Risk zone',
            source: 'FIRE-EYE risk monitoring',
          );
        }).toList();
      }
    } catch (_) {
      return _localIncidents;
    }
    return _localIncidents;
  }

  Future<bool> createIncident(IncidentModel incident) async {
    try {
      final res = await _client.post(ApiConfig.incidentsEndpoint, data: incident.toJson());
      if (res.statusCode == 200 || res.statusCode == 201) {
        _localIncidents.insert(0, incident);
        return true;
      }
    } catch (_) {}

    _localIncidents.insert(0, incident);
    return true;
  }

  Future<bool> updateIncidentStatus(String id, String newStatus) async {
    try {
      final res = await _client.patch('${ApiConfig.incidentsEndpoint}$id', data: {'status': newStatus});
      if (res.statusCode == 200) {
        _updateLocalStatus(id, newStatus);
        return true;
      }
    } catch (_) {}

    _updateLocalStatus(id, newStatus);
    return true;
  }

  void _updateLocalStatus(String id, String newStatus) {
    final idx = _localIncidents.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _localIncidents[idx] = _localIncidents[idx].copyWith(status: newStatus);
    }
  }
}
