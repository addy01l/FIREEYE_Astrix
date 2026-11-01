import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/incident_model.dart';

class IncidentService {
  final ApiClient _client = ApiClient.instance;
  Future<List<IncidentModel>> getIncidents() async {
    final List<IncidentModel> combined = [];

    // 1. Fetch real active civilian SOS requests from backend
    try {
      final sosRes = await _client.get(ApiConfig.activeSosEndpoint);
      if (sosRes.statusCode == 200 && sosRes.data is List) {
        for (final item in (sosRes.data as List)) {
          final s = item as Map<String, dynamic>;
          final priority = (s['priority_score'] as num?)?.toDouble() ?? 50.0;
          final code = s['sos_code']?.toString() ?? 'SOS-${s['id']}';
          final emergencyType =
              s['emergency_type']?.toString().replaceAll('_', ' ') ?? 'Civilian SOS';
          final status = (s['status'] as String? ?? 'PENDING').toUpperCase();
          final lat = (s['latitude'] as num?)?.toDouble() ?? 0.0;
          final lng = (s['longitude'] as num?)?.toDouble() ?? 0.0;

          combined.add(IncidentModel(
            id: code,
            title: '🚨 SOS: $emergencyType',
            type: emergencyType,
            severity: priority >= 75
                ? 'CRITICAL'
                : (priority >= 50 ? 'HIGH' : 'WARNING'),
            status: status == 'PENDING' ? 'ACTIVE' : status,
            latitude: lat,
            longitude: lng,
            timestamp: s['created_at'] != null
                ? DateTime.tryParse(s['created_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
            description:
                'PRIORITY SCORE: ${priority.toStringAsFixed(1)} (Severity: ${s['severity'] ?? 'HIGH'})\n'
                '${s['notes'] ?? 'Immediate civilian rescue dispatch requested.'}',
            locationName: 'GPS Target (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})',
            source: 'Emergency SOS Beacon',
            frp: priority, // stores priority score for UI badges
          ));
        }
      }
    } catch (_) {}

    // 2. Fetch Monitored Risk Zones from backend
    try {
      final zonesRes = await _client.get(ApiConfig.zonesEndpoint);
      if (zonesRes.statusCode == 200 && zonesRes.data is List) {
        for (final item in (zonesRes.data as List)) {
          final zone = item as Map<String, dynamic>;
          final level = (zone['risk_level'] as String? ?? 'LOW').toUpperCase();
          final riskScore = (zone['risk_score'] as num?)?.toDouble() ?? 0.0;
          combined.add(IncidentModel(
            id: zone['zone_code']?.toString() ?? 'ZONE',
            title: zone['name'] as String? ?? 'Monitored Risk Zone',
            type: 'Hazard Zone',
            severity: level == 'HIGH'
                ? 'CRITICAL'
                : (level == 'MEDIUM' ? 'WARNING' : 'SAFE'),
            status: level == 'LOW' ? 'RESOLVED' : 'ACTIVE',
            latitude: (zone['center_lat'] as num?)?.toDouble() ?? 0.0,
            longitude: (zone['center_lng'] as num?)?.toDouble() ?? 0.0,
            timestamp: DateTime.now(),
            description:
                'Hazard Risk Score ${(riskScore * 100).toStringAsFixed(1)}; ${zone['vulnerable_population'] ?? 0} residents at risk.',
            locationName: zone['name'] as String? ?? 'Risk Zone',
            source: 'FIRE-EYE Risk Sensor',
            frp: riskScore * 100,
          ));
        }
      }
    } catch (_) {}

    if (combined.isNotEmpty) {
      // Sort descending so highest priority emergencies appear at the very top
      combined.sort((a, b) => (b.frp ?? 0).compareTo(a.frp ?? 0));
      return combined;
    }

    return combined;
  }

  Future<bool> createIncident(IncidentModel incident) async {
    try {
      final res = await _client.post(ApiConfig.sosEndpoint, data: {
        'latitude': incident.latitude,
        'longitude': incident.longitude,
        'emergency_type': incident.type,
        'severity': incident.severity,
        'notes': '${incident.title}\n${incident.description}',
        'sender_device_id': 'FIELD-OPERATOR',
        'idempotency_key': incident.id,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<bool> updateIncidentStatus(String id, String newStatus) async {
    try {
      final res = await _client.patch(
        '${ApiConfig.sosEndpoint}$id/status',
        data: {'status': newStatus},
      );
      if (res.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    return false;
  }
}
