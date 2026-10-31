import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/alert_model.dart';
import 'package:mobile_app/models/anomaly_model.dart';
import 'package:mobile_app/models/incident_model.dart';
import 'package:mobile_app/models/user_model.dart';

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

    test('UserRole parser maps strings to correct enum', () {
      expect(UserRole.fromString('commander'), equals(UserRole.commander));
      expect(UserRole.fromString('admin'), equals(UserRole.commander));
      expect(UserRole.fromString('responder'), equals(UserRole.responder));
      expect(UserRole.fromString('volunteer'), equals(UserRole.volunteer));
      expect(UserRole.fromString('unknown'), equals(UserRole.citizen));
      expect(UserRole.fromString(null), equals(UserRole.citizen));
    });
  });
}

