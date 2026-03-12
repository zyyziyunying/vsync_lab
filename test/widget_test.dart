import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vsync_lab/frame_diagnosis/frame_diagnosis_app.dart';

void main() {
  testWidgets('diagnosis home shows standalone scenarios', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 1400));

    await tester.pumpWidget(const FrameDiagnosisApp());
    await tester.pumpAndSettle();

    expect(find.text('Frame Commit Diagnosis'), findsOneWidget);
    expect(find.text('Open state commit scenario'), findsOneWidget);
    expect(find.text('Open route commit scenario'), findsOneWidget);
  });

  testWidgets('can navigate to state commit scenario', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 1400));

    await tester.pumpWidget(const FrameDiagnosisApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open state commit scenario'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('State Commit Scenario'), findsWidgets);
    expect(find.text('Force scheduleFrame (Phase B)'), findsOneWidget);
  });

  testWidgets('route commit scenario performs a real route transition', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 1400));

    await tester.pumpWidget(const FrameDiagnosisApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open route commit scenario'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Route Commit Scenario'), findsWidgets);
    expect(find.text('Keep frames pumping (Phase B)'), findsOneWidget);
    expect(find.text('Route A viewport'), findsOneWidget);

    await tester.tap(find.text('Push Route B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Route B viewport'), findsOneWidget);
    expect(find.text('Navigator top route'), findsOneWidget);
    expect(find.text('Pop to Route A'), findsOneWidget);
  });

  testWidgets('route commit scenario ignores repeated push intents', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 1400));

    await tester.pumpWidget(const FrameDiagnosisApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open route commit scenario'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('Intent push Route B'));
    await tester.tap(find.text('Intent push Route B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Route B viewport'), findsOneWidget);

    await tester.tap(find.text('Pop to Route A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Route A viewport'), findsOneWidget);
    expect(find.text('Route B viewport'), findsNothing);
  });
}
