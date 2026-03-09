import 'package:flutter_test/flutter_test.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

void main() {
  test('uses target refresh rate to derive empty snapshot frame budget', () {
    final snapshot = FrameMetricsSnapshot.empty(targetRefreshRate: 120);

    expect(snapshot.targetRefreshRate, 120);
    expect(snapshot.frameBudgetMs, closeTo(8.3333333333, 0.000001));
  });

  test('retains only the latest sample at the minimum valid window size', () {
    final aggregator = FrameMetricsAggregator(
      targetRefreshRate: 60,
      maxSamples: 1,
    );

    aggregator.addSample(
      frameEndUs: 1000000,
      buildUs: 2000,
      rasterUs: 1500,
      totalUs: 5000,
    );
    aggregator.addSample(
      frameEndUs: 1016667,
      buildUs: 2100,
      rasterUs: 1600,
      totalUs: 5100,
    );

    expect(aggregator.sampleCount, 1);
  });

  test('rejects invalid refresh rates and sample window sizes', () {
    expect(
      () => FrameMetricsAggregator(targetRefreshRate: 0),
      throwsArgumentError,
    );
    expect(
      () => FrameMetricsAggregator(targetRefreshRate: double.nan),
      throwsArgumentError,
    );
    expect(
      () => FrameMetricsAggregator(targetRefreshRate: 60, maxSamples: 0),
      throwsArgumentError,
    );

    final aggregator = FrameMetricsAggregator(targetRefreshRate: 60);
    expect(
      () => aggregator.updateTargetRefreshRate(double.infinity),
      throwsArgumentError,
    );
    expect(aggregator.targetRefreshRate, 60);
  });
}
