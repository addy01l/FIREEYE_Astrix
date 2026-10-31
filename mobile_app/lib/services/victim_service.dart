import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/victim_model.dart';

class VictimService {
  final ApiClient _client = ApiClient.instance;

  static final List<VictimModel> _fallbackVictims = [
    VictimModel(
      id: 'SOS-901',
      fullName: 'Trapped / Structural Collapse',
      incidentId: 'SOS-901',
      location: '30.3662, 77.9221',
      status: 'TRAPPED',
      priorityScore: 92,
      hasInfants: false,
      hasElderly: true,
      medicalCondition: 'Chemical vapor inhalation distress / 3 people trapped',
      contactNumber: '+91 94120 11111',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 22)),
    ),
    VictimModel(
      id: 'SOS-902',
      fullName: 'Monsoon Slope Debris Slide',
      incidentId: 'SOS-902',
      location: '30.3842, 78.0754',
      status: 'IN TRANSIT',
      priorityScore: 85,
      hasInfants: true,
      hasElderly: false,
      medicalCondition: 'Vehicle overturned on slope / urgent evacuation',
      contactNumber: '+91 98371 22222',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 50)),
    ),
  ];

  Future<List<VictimModel>> getVictims() async {
    try {
      // 1. Try prioritized queue from /api/v1/priority/queue
      final res = await _client.get(ApiConfig.victimsEndpoint);
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final queue = (res.data as Map<String, dynamic>)['queue'];
        if (queue is List && queue.isNotEmpty) {
          return queue.map((item) {
            final v = item as Map<String, dynamic>;
            final priority = (v['priority_score'] as num?)?.toInt() ?? 75;
            final code = v['sos_code']?.toString() ?? 'SOS-${v['sos_id']}';
            final notes = v['notes']?.toString() ?? '';
            final lat = (v['latitude'] as num?)?.toDouble() ?? 0.0;
            final lng = (v['longitude'] as num?)?.toDouble() ?? 0.0;
            return VictimModel.fromJson({
              'id': code,
              'full_name': v['emergency_type']?.toString().replaceAll('_', ' ') ?? 'Civilian SOS Caller',
              'incident_id': code,
              'location': '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
              'status': v['status'] ?? 'TRAPPED',
              'priority_score': priority,
              'has_elderly': (v['elderly_count'] as num?)?.toInt() != 0 || notes.toLowerCase().contains('elderly'),
              'has_infants': notes.toLowerCase().contains('child') || notes.toLowerCase().contains('infant'),
              'medical_condition': notes.isNotEmpty ? notes : (v['medical_needs'] ?? 'Immediate triage dispatch required'),
              'reported_at': v['created_at'],
            });
          }).toList();
        }
      }

      // 2. Fallback to /api/v1/sos/active
      final sosRes = await _client.get(ApiConfig.activeSosEndpoint);
      if (sosRes.statusCode == 200 && sosRes.data is List && (sosRes.data as List).isNotEmpty) {
        return (sosRes.data as List).map((item) {
          final v = item as Map<String, dynamic>;
          final priority = (v['priority_score'] as num?)?.toInt() ?? 75;
          final code = v['sos_code']?.toString() ?? 'SOS-${v['id']}';
          final notes = v['notes']?.toString() ?? '';
          final lat = (v['latitude'] as num?)?.toDouble() ?? 0.0;
          final lng = (v['longitude'] as num?)?.toDouble() ?? 0.0;
          return VictimModel.fromJson({
            'id': code,
            'full_name': v['emergency_type']?.toString().replaceAll('_', ' ') ?? 'Civilian SOS Caller',
            'incident_id': code,
            'location': '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
            'status': v['status'] ?? 'TRAPPED',
            'priority_score': priority,
            'has_elderly': notes.toLowerCase().contains('elderly'),
            'has_infants': notes.toLowerCase().contains('child') || notes.toLowerCase().contains('infant'),
            'medical_condition': notes.isNotEmpty ? notes : 'Immediate triage dispatch required',
            'reported_at': v['created_at'],
          });
        }).toList();
      }
    } catch (_) {
      return _fallbackVictims;
    }
    return _fallbackVictims;
  }

  Future<bool> updateVictimStatus(String id, String newStatus, {String? notes}) async {
    try {
      final res = await _client.patch(
        '${ApiConfig.sosEndpoint}$id/status',
        data: {
          'status': newStatus,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      if (res.statusCode == 200) {
        _updateLocal(id, newStatus, notes);
        return true;
      }
    } catch (_) {}

    _updateLocal(id, newStatus, notes);
    return true;
  }

  void _updateLocal(String id, String newStatus, String? notes) {
    final idx = _fallbackVictims.indexWhere((v) => v.id == id);
    if (idx != -1) {
      _fallbackVictims[idx] = _fallbackVictims[idx].copyWith(
        status: newStatus,
        medicalCondition: notes,
      );
    }
  }
}
