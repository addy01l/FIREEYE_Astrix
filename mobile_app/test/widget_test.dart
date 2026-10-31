import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_app/widgets/brand_logo.dart';
import 'package:mobile_app/widgets/stat_kpi_card.dart';
import 'package:mobile_app/widgets/status_chip.dart';

void main() {
  group('FIRE-EYE Core Widgets', () {
    testWidgets('BrandLogo renders with title and tactical shield icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandLogo(size: 30),
          ),
        ),
      );

      expect(find.text('FIRE-EYE'), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldAlert), findsOneWidget);
    });

    testWidgets('StatusChip renders severity with expected label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusChip(label: 'CRITICAL'),
          ),
        ),
      );

      expect(find.text('CRITICAL'), findsOneWidget);
    });

    testWidgets('StatKpiCard renders metric values and handles tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatKpiCard(
              icon: LucideIcons.flame,
              label: 'Thermal Hotspots',
              value: '14',
              subtext: 'Satellite Telemetry',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('THERMAL HOTSPOTS'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Satellite Telemetry'), findsOneWidget);

      await tester.tap(find.text('THERMAL HOTSPOTS'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
