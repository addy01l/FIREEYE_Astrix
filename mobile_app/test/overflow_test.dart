import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/incident_provider.dart';
import 'package:mobile_app/screens/incidents/create_incident_screen.dart';

void main() {
  group('CreateIncidentScreen layout & responsiveness', () {
    testWidgets('Renders cleanly on standard phone screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.75; // Approx 392 x 698 logical pixels
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => IncidentProvider()),
          ],
          child: const MaterialApp(
            home: CreateIncidentScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders and scrolls on short screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 2.0; // 400 x 500 logical pixels
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => IncidentProvider()),
          ],
          child: const MaterialApp(
            home: CreateIncidentScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify scrolling down to the submit button works smoothly
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('TRANSMIT TO REGISTRY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Handles keyboard appearance without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.75;
      tester.view.viewInsets = const FakeViewPadding(bottom: 350); // Software keyboard
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetViewInsets();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => IncidentProvider()),
          ],
          child: const MaterialApp(
            home: CreateIncidentScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
    