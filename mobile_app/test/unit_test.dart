import 'package:mobile_app/core/config/api_config.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/alert_model.dart';
import 'package:mobile_app/models/anomaly_model.dart';
import 'package:mobile_app/models/incident_model.dart';
import 'package:mobile_app/models/shelter_model.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/models/victim_model.dart';
import 'package:mobile_app/services/sos_service.dart';

void main() {
  group('FIRE-EYE Data Models & Parsers', () {
    test('AnomalyModel parses NASA FIRMS / FastAPI structure correctly', () {
      final json = {
        'id': 883,
        'latitude': 30.3165,
        'longitude': 78.0322,
        'brightness': 325.4,
        'frp': 45.8,
        'is_wildfire': true,
      };

      final anomaly = AnomalyModel.fromJson(json);

      expect(anomaly.id, equals(883));
      expect(anomaly.latitude, closeTo(30.3165, 0.0001));
      expect(anomaly.longitude, closeTo(78.0322, 0.0001));
      expect(anomaly.brightness, closeTo(325.4, 0.01));
      expect(anomaly.frp, closeTo(45.8, 0.001));
      expect(anomaly.isWildfire, isTrue);
    });

    test('AlertModel parses WebSocket /ws/alerts payload', () {
      final wsPayload = {
        'type': 'ALERT',
        'data': {
          'latitude': 30.3662,
          'longitude': 77.9221,
          'confidence': 'very high',
          'is_wildfire': true,
        }
      };

      final alert = AlertModel.fromWebSocket(wsPayload);

      expect(alert.severity, equals('CRITICAL'));
      expect(alert.title, contains('CRITICAL THERMAL ANOMALY'));
      expect(alert.isLiveWebSocket, isTrue);
      expect(alert.latitude, closeTo(30.3662, 0.0001));
      expect(alert.longitude, closeTo(77.9221, 0.0001));
    });

    test('IncidentModel parses JSON and defaults correctly', () {
      final json = {
        'id': 'INC-2026-001',
        'title': 'Wildfire in Rajpur Hills',
        'description': 'Rapid brush fire heading east',
        'type': 'WILDFIRE',
        'severity': 'CRITICAL',
        'status': 'ACTIVE',
        'latitude': 30.3842,
        'longitude': 78.0754,
        'reported_at': '2026-10-31T08:30:00Z',
        'reported_by': 'Commander Singh',
      };

      final incident = IncidentModel.fromJson(json);

      expect(incident.id, equals('INC-2026-001'));
      expect(incident.severity, equals('CRITICAL'));
      expect(incident.status, equals('ACTIVE'));
      expect(incident.latitude, closeTo(30.3842, 0.0001));
    });

    test('ShelterModel parses shelter schema correctly', () {
      final json = {
        'id': 'SHL-01',
        'name': 'Doon Relief Camp',
        'address': 'Rajpur Road',
        'capacity': 500,
        'occupancy': 200,
        'latitude': 30.3340,
        'longitude': 78.0550,
        'contact_phone': '+91 94101 22334',
        'has_medical': true,
        'has_generator': true,
        'status': 'OPERATIONAL',
      };

      final shelter = ShelterModel.fromJson(json);
      expect(shelter.id, equals('SHL-01'));
      expect(shelter.name, equals('Doon Relief Camp'));
      expect(shelter.availableBeds, equals(300));
      expect(shelter.occupancyRate, closeTo(0.4, 0.01));
    });

    test('VictimModel parses triage queue correctly', () {
      final json = {
        'id': 'VIC-901',
        'full_name': 'Ramesh C.',
        'incident_id': 'INC-9481',
        'location': 'Selaqui Sector 2',
        'status': 'TRAPPED',
        'priority_score': 92,
        'has_elderly': true,
        'medical_condition': 'Vapor inhalation',
        'reported_at': '2026-10-31T09:00:00Z',
      };

      final victim = VictimModel.fromJson(json);
      expect(victim.id, equals('VIC-901'));
      expect(victim.priorityScore, equals(92));
      expect(victim.hasElderly, isTrue);
    });

    test('UserRole parser maps strings to correct enum', () {
      expect(UserRole.fromString('commander'), equals(UserRole.commander));
      expect(UserRole.fromString('admin'), equals(UserRole.commander));
      expect(UserRole.fromString('responder'), equals(UserRole.responder));
      expect(UserRole.fromString('volunteer'), equals(UserRole.volunteer));
      expect(UserRole.fromString('unknown'), equals(UserRole.citizen));
      expect(UserRole.fromString(null), equals(UserRole.citizen));
    });

    test('SosService queues offline SOS when network is unreachable', () async {
      SharedPreferences.setMockInitialValues({});
      final originalUrl = ApiConfig.baseUrl;
      ApiClient.instance.updateBaseUrl('http://127.0.0.1:59999');
      addTearDown(() => ApiClient.instance.updateBaseUrl(originalUrl));

      final service = SosService();

      final res = await service.createSos(
        latitude: 30.3165,
        longitude: 78.0322,
        emergencyType: 'Flash Flood',
        notes: 'Water rising rapidly',
        idempotencyKey: 'SOS-TEST-OFFLINE',
      );

      expect(res['status'], equals('QUEUED_OFFLINE'));
      expect(res['is_offline'], isTrue);

      final queue = await service.getOfflineQueue();
      expect(queue.length, equals(1));
      expect(queue.first['emergency_type'], equals('Flash Flood'));
      expect(queue.first['idempotency_key'], equals('SOS-TEST-OFFLINE'));
    });
  });
}
