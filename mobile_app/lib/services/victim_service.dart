import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/victim_model.dart';

class VictimService {
  final ApiClient _client = ApiClient.instance;

  static final List<VictimModel> _fallbackVictims = [
    VictimModel(
      id: 'VIC-901',
      fullName: 'Ramesh C*** (Protected)',
      incidentId: 'INC-9481',
      location: 'Selaqui Sector 2, Factory Perimeter',
      status: 'TRAPPED',
      priorityScore: 92,
      hasInfants: false,
      hasElderly: true,
      medicalCondition: 'Chemical vapor inhalation distress',
      contactNumber: '+91 94120 *****',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 22)),
    ),
    VictimModel(
      id: 'VIC-902',
      fullName: 'Anita R*** (Protected)',
      incidentId: 'INC-8832',
      location: 'Rajpur Road Hill Slope',
      status: 'IN TRANSIT',
      priorityScore: 88,
      hasInfants: true,
      hasElderly: false,
      medicalCondition: 'Minor laceration on shoulder',
      contactNumber: '+91 98371 *****',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 50)),
    ),
    VictimModel(
      id: 'VIC-903',
      fullName: 'Gurmeet S*** (Protected)',
      incidentId: 'INC-7124',
      location: 'Clement Town Sub-ward 3',
      status: 'MEDICAL CARE',
      priorityScore: 74,
      hasInfants: false,
      hasElderly: true,
      medicalCondition: 'Hypothermia / safe at Doon Relief Center',
      contactNumber: '+91 97600 *****',
      reportedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
    ),
    VictimModel(
      id: 'VIC-904',
      fullName: 'Deepak B*** (Protected)',
      incidentId: 'INC-9481',
      location: 'Selaqui Sector 3',
      status: 'RESCUED',
      priorityScore: 40,
      hasInfants: false,
      hasElderly: false,
      medicalCondition: 'Evacuated without injury',
      contactNumber: '+91 94111 *****',
      reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  Future<List<VictimModel>> getVictims() async {
    try {
      final res = await _client.get(ApiConfig.victimsEndpoint);
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final queue = (res.data as Map<String, dynamic>)['queue'];
        if (queue is List) {
          return queue.map((item) {
            final v = item as Map<String, dynamic>;
            return VictimModel.fromJson({
              'id': v['sos_code'] ?? v['sos_id'],
              'full_name': v['household_code'] ?? 'Emergency caller',
              'incident_id': v['sos_code'],
              'location': '${v['latitude']}, ${v['longitude']}',
              'status': v['status'],
              'priority_score': v['priority_score'],
              'has_elderly': (v['elderly_count'] as num?)?.toInt() != 0,
              'medical_condition': v['medical_needs'],
              'reported_at': v['created_at'],
            });
          }).toList();
        }
      }
    } catch (_) {
      return _fallbackVictims;
    }
    return _fallbackVictims;
  }

  Future<bool> updateVictimStatus(String id, String newStatus, {String? notes}) async {
    try {
      final res = await _client.patch(
        '${ApiConfig.victimsEndpoint}$id',
        data: {
          'status': newStatus,
          ...?notes == null ? null : {'medical_condition': notes},
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
