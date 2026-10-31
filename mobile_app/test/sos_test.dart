import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/alert_provider.dart';
import 'package:mobile_app/providers/anomaly_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/incident_provider.dart';
import 'package:mobile_app/providers/rescue_center_provider.dart';
import 'package:mobile_app/providers/shelter_provider.dart';
import 'package:mobile_app/providers/victim_provider.dart';
import 'package:mobile_app/screens/auth/login_screen.dart';
import 'package:mobile_app/screens/dashboard/dashboard_screen.dart';

void main() {
  group('Landing Page, Emergency SOS & Official Logout Workflow', () {
    testWidgets('Landing screen displays prominent Request Emergency Help button and Official Login', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => IncidentProvider()),
            ChangeNotifierProvider(create: (_) => AlertProvider()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Settle session restore
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the hero Request Emergency Help button is present
      expect(find.text('REQUEST EMERGENCY HELP'), findsOneWidget);
      expect(find.text('IN IMMEDIATE DANGER?'), findsOneWidget);

      // Verify the Rescuers & Officials section is present
      expect(find.text('RESCUERS & OFFICIALS LOGIN'), findsOneWidget);
      expect(find.text('SIGN IN TO COMMAND CONSOLE'), findsOneWidget);
    });

    testWidgets('Tapping Request Emergency Help opens EmergencyHelpScreen with all SOS options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => IncidentProvider()),
            ChangeNotifierProvider(create: (_) => AlertProvider()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Tap Request Emergency Help
      await tester.tap(find.text('REQUEST EMERGENCY HELP'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify EmergencyHelpScreen loaded
      expect(find.text('EMERGENCY SOS ASSISTANCE'), findsOneWidget);
      expect(find.text('CIVILIAN EMERGENCY CHANNEL'), findsOneWidget);
      expect(find.text('Trapped / Structural Collapse'), findsOneWidget);
      expect(find.text('Active Fire / Wildfire'), findsOneWidget);
      expect(find.text('🚨 TRANSMIT EMERGENCY SOS BEACON'), findsOneWidget);

      // Scroll and tap Transmit SOS beacon
      await tester.ensureVisible(find.text('🚨 TRANSMIT EMERGENCY SOS BEACON'));
      await tester.tap(find.text('🚨 TRANSMIT EMERGENCY SOS BEACON'));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Active SOS Beacon view is shown
      expect(find.text('SOS DISTRESS BEACON ACTIVE'), findsOneWidget);
      expect(find.text('DISPATCH TELEMETRY'), findsOneWidget);
      expect(find.text('CANCEL BEACON / I AM SAFE NOW'), findsOneWidget);
    });

    testWidgets('Dashboard displays visible official Logout button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => IncidentProvider()),
            ChangeNotifierProvider(create: (_) => AlertProvider()),
            ChangeNotifierProvider(create: (_) => AnomalyProvider()),
            ChangeNotifierProvider(create: (_) => ShelterProvider()),
            ChangeNotifierProvider(create: (_) => RescueCenterProvider()),
            ChangeNotifierProvider(create: (_) => VictimProvider()),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify Logout icon button is present in the Dashboard AppBar
      expect(find.byTooltip('Logout Official Session'), findsOneWidget);

      // Tap Logout
      await tester.tap(find.byTooltip('Logout Official Session'));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify logout confirmation dialog is shown
      expect(find.text('LOGOUT OFFICIAL SESSION?'), findsOneWidget);
      expect(find.text('LOGOUT'), findsOneWidget);
    });
  });
}
