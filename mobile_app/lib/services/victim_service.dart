import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/victim_model.dart';

class VictimService {
  final ApiClient _client = ApiClient.instance;

  Future<List<VictimModel>> getVictims() async {
    final response = await _client.get(ApiConfig.activeSosEndpoint);
    if (response.data is! List) throw StateError('The active SOS endpoint returned an invalid response');
    return (response.data as List).map((item) {
      final sos = Map<String, dynamic>.from(item as Map);
      final notes = sos['notes']?.toString() ?? '';
      final latitude = sos['latitude'] as num?;
      final longitude = sos['longitude'] as num?;
      final createdAt = DateTime.tryParse(sos['created_at']?.toString() ?? '');
      if (latitude == null || longitude == null || createdAt == null || sos['sos_code'] == null || sos['priority_score'] == null) {
        throw const FormatException('SOS record is missing required location, time, identity, or priority data');
      }
      final code = sos['sos_code'].toString();
      return VictimModel(
        id: code,
        fullName: sos['emergency_type']?.toString() ?? 'Emergency caller',
        incidentId: code,
        location: '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
        status: (sos['status']?.toString() ?? 'PENDING').toUpperCase(),
        priorityScore: (sos['priority_score'] as num).round(),
        hasInfants: notes.toLowerCase().contains('child') || notes.toLowerCase().contains('infant'),
        hasElderly: notes.toLowerCase().contains('elderly'),
        medicalCondition: notes,
        contactNumber: '',
        reportedAt: createdAt,
      );
    }).toList();
  }

  Future<bool> updateVictimStatus(String id, String newStatus, {String? notes}) async {
    try {
      final response = await _client.patch(
        '${ApiConfig.sosEndpoint}$id/status',
        data: {'status': newStatus, if (notes != null && notes.isNotEmpty) 'notes': notes},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
