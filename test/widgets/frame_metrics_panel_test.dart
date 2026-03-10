import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vsync_lab/widgets/frame_metrics_panel.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

void main() {
  testWidgets('disables save action while a manual save is in flight',
      (tester) async {
    final saveCompleter = Completer<FrameLogSaveResult>();
    var saveCallCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FrameMetricsPanel(
            snapshot: FrameMetricsSnapshot.empty(targetRefreshRate: 60),
            isRunning: true,
            onToggle: () {},
            onReset: () {},
            observabilityRecordCount: 3,
            onSaveObservabilityLog: () {
              saveCallCount++;
              return saveCompleter.future;
            },
          ),
        ),
      ),
    );

    expect(find.text('Save frame log (3)'), findsOneWidget);

    await tester.tap(find.text('Save frame log (3)'));
    await tester.pump();

    expect(saveCallCount, 1);
    expect(find.text('Saving frame log...'), findsOneWidget);

    final savingButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Saving frame log...'),
    );
    expect(savingButton.onPressed, isNull);

    saveCompleter.complete(
      const FrameLogSaveResult(
        scenario: 'animation',
        latestFileName: 'frame_log_animation_latest.json',
        archivedFileName: 'frame_log_animation_20260310_120000_000000.json',
        cacheDirectoryPath: '/tmp',
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Frame log saved'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Save frame log (3)'), findsOneWidget);
  });

  testWidgets('disables save action when monitor reports an active save',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FrameMetricsPanel(
            snapshot: FrameMetricsSnapshot.empty(targetRefreshRate: 60),
            isRunning: true,
            onToggle: () {},
            onReset: () {},
            observabilityRecordCount: 5,
            isSavingObservabilityLog: true,
            onSaveObservabilityLog: () async {
              throw UnimplementedError('Save should be disabled.');
            },
          ),
        ),
      ),
    );

    expect(find.text('Saving frame log...'), findsOneWidget);
    final savingButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Saving frame log...'),
    );
    expect(savingButton.onPressed, isNull);
  });
}
