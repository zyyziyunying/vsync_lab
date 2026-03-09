import 'package:flutter_test/flutter_test.dart';
import 'package:vsync_lab_toolkit/src/frame_observability_log.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

void main() {
  test('records per-frame interval deviation and miss flags', () {
    final log = FrameObservabilityLog(targetRefreshRate: 60, maxRecords: 10);

    log.addSample(
      frameEndUs: 1000000,
      buildUs: 3000,
      rasterUs: 2000,
      totalUs: 7000,
    );
    log.addSample(
      frameEndUs: 1016667,
      buildUs: 4000,
      rasterUs: 2500,
      totalUs: 17000,
    );
    log.addSample(
      frameEndUs: 1050000,
      buildUs: 4500,
      rasterUs: 2700,
      totalUs: 8000,
    );

    final data = log.buildUnifiedLog(
      snapshot: FrameMetricsSnapshot.empty(targetRefreshRate: 60),
      scenario: 'animation',
    );
    final records =
        (data['records'] as List<dynamic>).cast<Map<String, dynamic>>();

    expect(records.length, 3);

    expect(records[0]['actualIntervalUs'], isNull);
    expect(records[0]['intervalDeltaUs'], isNull);

    expect(records[1]['actualIntervalUs'], 16667);
    expect(records[1]['intervalDeltaUs'], 0);
    expect(records[1]['isOverBudget'], isTrue);

    expect(records[2]['actualIntervalUs'], 33333);
    expect(records[2]['isVsyncMiss'], isTrue);
  });

  test('keeps a bounded ring buffer for unified logs', () {
    final log = FrameObservabilityLog(targetRefreshRate: 60, maxRecords: 2);

    log.addSample(
      frameEndUs: 1000000,
      buildUs: 2000,
      rasterUs: 2000,
      totalUs: 5000,
    );
    log.addSample(
      frameEndUs: 1016667,
      buildUs: 2000,
      rasterUs: 2000,
      totalUs: 5000,
    );
    log.addSample(
      frameEndUs: 1033334,
      buildUs: 2000,
      rasterUs: 2000,
      totalUs: 5000,
    );

    final data = log.buildUnifiedLog(
      snapshot: FrameMetricsSnapshot.empty(targetRefreshRate: 60),
    );
    final records =
        (data['records'] as List<dynamic>).cast<Map<String, dynamic>>();

    expect(data['recordCount'], 2);
    expect(log.isFull, isTrue);
    expect(records.first['frameIndex'], 2);
    expect(records.last['frameIndex'], 3);
  });

  test('retains only the latest record at the minimum valid buffer size', () {
    final log = FrameObservabilityLog(targetRefreshRate: 60, maxRecords: 1);

    log.addSample(
      frameEndUs: 1000000,
      buildUs: 2000,
      rasterUs: 2000,
      totalUs: 5000,
    );
    log.addSample(
      frameEndUs: 1016667,
      buildUs: 2200,
      rasterUs: 2100,
      totalUs: 5200,
    );

    final data = log.buildUnifiedLog(
      snapshot: FrameMetricsSnapshot.empty(targetRefreshRate: 60),
    );
    final records =
        (data['records'] as List<dynamic>).cast<Map<String, dynamic>>();

    expect(log.recordCount, 1);
    expect(log.isFull, isTrue);
    expect(records.single['frameIndex'], 2);
  });

  test('rejects invalid refresh rates and record capacities', () {
    expect(
      () => FrameObservabilityLog(targetRefreshRate: 0, maxRecords: 1),
      throwsArgumentError,
    );
    expect(
      () => FrameObservabilityLog(targetRefreshRate: 60, maxRecords: 0),
      throwsArgumentError,
    );

    final log = FrameObservabilityLog(targetRefreshRate: 60, maxRecords: 2);
    expect(() => log.updateTargetRefreshRate(-120), throwsArgumentError);
    expect(log.targetRefreshRate, 60);
  });
}
