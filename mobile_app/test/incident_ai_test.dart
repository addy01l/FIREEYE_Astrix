import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/models/incident_model.dart';
import 'package:mobile_app/providers/incident_provider.dart';
import 'package:mobile_app/screens/incidents/incident_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final responsePayload = jsonEncode({
      'sos_code': 'SOS-TEST-99',
      'incident_summary': 'Rapid landslide collapse trapped families in residential structure.',
      'identified_risk_factors': ['Secondary slope mud movement', 'Structural fracture risk'],
      'recommended_rescue_actions': ['Deploy tactical search team', 'Establish triage perimeter'],
      'required_rescue_resources': ['4x4 Rescue Vehicle', 'Hydraulic Spreaders'],
      'suggested_urgency_level': 'CRITICAL',
      'model_used': 'groq-openai/gpt-oss-120b',
      'reviewed_by_human': false,
    });

    return ResponseBody.fromString(
      responsePayload,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.dio.httpClientAdapter = _MockDioAdapter();
  });

  testWidgets('IncidentDetailScreen renders AI SOS Response Assistant section and parsed content', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final incident = IncidentModel(
      id: 'SOS-TEST-99',
      title: '🚨 SOS: Landslide Entrapment',
      type: 'Landslide',
      severity: 'CRITICAL',
      status: 'ACTIVE',
      latitude: 30.2846,
      longitude: 78.9815,
      timestamp: DateTime.now(),
      description: 'Multiple families trapped in residential block after flash slope collapse',
      locationName: 'Sector 4, Hill Road',
      source: 'Emergency SOS Beacon',
      frp: 95.0,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ],
        child: MaterialApp(
          home: IncidentDetailScreen(incident: incident),
        ),
      ),
    );

    // Pump to process microtasks and HTTP response
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));


    // Verify AI SOS Response Assistant UI elements
    expect(find.text('AI SOS RESPONSE ASSISTANT'), findsOneWidget);
    expect(find.text('GROQ LLM'), findsOneWidget);
    expect(find.text('SUGGESTED URGENCY: CRITICAL'), findsOneWidget);
    expect(find.text('INCIDENT SUMMARY'), findsOneWidget);
    expect(find.textContaining('Rapid landslide collapse trapped families'), findsOneWidget);
    expect(find.text('IDENTIFIED RISK FACTORS'), findsOneWidget);
    expect(find.text('RECOMMENDED RESCUE ACTIONS'), findsOneWidget);
    expect(find.text('REQUIRED RESCUE RESOURCES'), findsOneWidget);
    expect(find.text('4x4 Rescue Vehicle'), findsOneWidget);
    expect(find.text('Hydraulic Spreaders'), findsOneWidget);

    // Verify human rescuer disclaimer is present
    expect(
      find.text('Advisory only — review and confirm tactical actions prior to dispatch.'),
      findsOneWidget,
    );
  });
}
