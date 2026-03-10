import 'package:flutter_test/flutter_test.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

void main() {
  test('records plain frame samples without Flutter frame callbacks', () {
    final recorder = FrameMetricsRecorder(
      targetRefreshRate: 60,
      maxSamples: 4,
      maxLogRecords: 4,
    );

    recorder.addFrameSamples(const <FrameSample>[
      FrameSample(
        frameEndUs: 1000000,
        buildUs: 3000,
        rasterUs: 2000,
        totalUs: 7000,
      ),
      FrameSample(
        frameEndUs: 1016667,
        buildUs: 4000,
        rasterUs: 2500,
        totalUs: 17000,
      ),
    ]);

    expect(recorder.sampleCount, 2);
    expect(recorder.observabilityRecordCount, 2);
    expect(recorder.snapshot.sampleCount, 2);
    expect(recorder.snapshot.jankRatio, closeTo(0.5, 0.000001));
  });

  test('changing refresh rate clears captured data and rebuilds frame budget',
      () {
    final recorder = FrameMetricsRecorder(
      targetRefreshRate: 60,
      maxSamples: 4,
      maxLogRecords: 4,
    );

    recorder.addSample(
      frameEndUs: 1000000,
      buildUs: 3000,
      rasterUs: 2000,
      totalUs: 7000,
    );
    recorder.addSample(
      frameEndUs: 1016667,
      buildUs: 4000,
      rasterUs: 2500,
      totalUs: 17000,
    );

    recorder.applyTargetRefreshRate(120);

    expect(recorder.targetRefreshRate, 120);
    expect(recorder.sampleCount, 0);
    expect(recorder.observabilityRecordCount, 0);
    expect(recorder.snapshot.sampleCount, 0);
    expect(recorder.snapshot.frameBudgetMs, closeTo(8.3333333333, 0.000001));

    final log = recorder.buildObservabilityLog(scenario: 'feed');
    expect(log['targetRefreshRateHz'], 120);
    expect(log['frameBudgetMs'], closeTo(8.3333333333, 0.000001));
    expect(log['recordCount'], 0);
    expect(log['scenario'], 'feed');
  });

  test('reapplying the same refresh rate keeps the current capture window', () {
    final recorder = FrameMetricsRecorder(targetRefreshRate: 60);

    recorder.addSample(
      frameEndUs: 1000000,
      buildUs: 3000,
      rasterUs: 2000,
      totalUs: 7000,
    );
    recorder.addSample(
      frameEndUs: 1016667,
      buildUs: 4000,
      rasterUs: 2500,
      totalUs: 17000,
    );

    recorder.applyTargetRefreshRate(60);

    expect(recorder.sampleCount, 2);
    expect(recorder.observabilityRecordCount, 2);
  });

  test('normalizes scenario settings in the unified log output', () {
    final recorder = FrameMetricsRecorder(targetRefreshRate: 60);

    final log = recorder.buildObservabilityLog(
      scenario: '  feed_scroll  ',
      scenarioSettings: <String, Object?>{
        'refreshRates': <int>[60, 120],
        'metadata': <String, Object?>{
          'entry': 'home',
        },
      },
    );

    expect(log['scenario'], 'feed_scroll');
    expect(log['scenarioSettings'], <String, Object?>{
      'refreshRates': <Object?>[60, 120],
      'metadata': <String, Object?>{'entry': 'home'},
    });
  });

  test('rejects invalid constructor parameters and refresh rate updates', () {
    expect(
        () => FrameMetricsRecorder(targetRefreshRate: 0), throwsArgumentError);
    expect(() => FrameMetricsRecorder(maxSamples: 0, targetRefreshRate: 60),
        throwsArgumentError);
    expect(() => FrameMetricsRecorder(maxLogRecords: 0, targetRefreshRate: 60),
        throwsArgumentError);

    final recorder = FrameMetricsRecorder(targetRefreshRate: 60);
    expect(
      () => recorder.applyTargetRefreshRate(double.nan),
      throwsArgumentError,
    );
    expect(recorder.targetRefreshRate, 60);
  });
}
