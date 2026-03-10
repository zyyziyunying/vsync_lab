import 'argument_validation.dart';
import 'frame_metrics_aggregator.dart';
import 'frame_metrics_snapshot.dart';
import 'frame_observability_log.dart';
import 'frame_sample.dart';

class FrameMetricsRecorder {
  FrameMetricsRecorder({
    required double targetRefreshRate,
    int maxSamples = 240,
    int maxLogRecords = 1200,
  }) : this._(
          targetRefreshRate: validateTargetRefreshRate(targetRefreshRate),
          maxSamples: validatePositiveInt(maxSamples, 'maxSamples'),
          maxLogRecords: validatePositiveInt(maxLogRecords, 'maxLogRecords'),
        );

  FrameMetricsRecorder._({
    required double targetRefreshRate,
    required int maxSamples,
    required int maxLogRecords,
  })  : _aggregator = FrameMetricsAggregator(
          targetRefreshRate: targetRefreshRate,
          maxSamples: maxSamples,
        ),
        _observabilityLog = FrameObservabilityLog(
          targetRefreshRate: targetRefreshRate,
          maxRecords: maxLogRecords,
        ),
        _snapshot =
            FrameMetricsSnapshot.empty(targetRefreshRate: targetRefreshRate);

  final FrameMetricsAggregator _aggregator;
  final FrameObservabilityLog _observabilityLog;

  FrameMetricsSnapshot _snapshot;

  FrameMetricsSnapshot get snapshot => _snapshot;
  double get targetRefreshRate => _aggregator.targetRefreshRate;
  int get sampleCount => _aggregator.sampleCount;
  int get maxSamples => _aggregator.maxSamples;
  int get observabilityRecordCount => _observabilityLog.recordCount;
  int get maxLogRecords => _observabilityLog.maxRecords;
  bool get isObservabilityLogFull => _observabilityLog.isFull;

  void reset() {
    _clearCapturedData(targetRefreshRate: targetRefreshRate);
  }

  void applyTargetRefreshRate(double hz) {
    final validatedHz = validateTargetRefreshRate(hz);
    if (validatedHz == targetRefreshRate) {
      return;
    }

    _aggregator.updateTargetRefreshRate(validatedHz);
    _observabilityLog.updateTargetRefreshRate(validatedHz);
    _clearCapturedData(targetRefreshRate: validatedHz);
  }

  void addFrameSample(FrameSample sample) {
    addFrameSamples(<FrameSample>[sample]);
  }

  void addFrameSamples(Iterable<FrameSample> samples) {
    var hasSamples = false;
    for (final sample in samples) {
      hasSamples = true;
      _aggregator.addSample(
        frameEndUs: sample.frameEndUs,
        buildUs: sample.buildUs,
        rasterUs: sample.rasterUs,
        totalUs: sample.totalUs,
      );
      _observabilityLog.addSample(
        frameEndUs: sample.frameEndUs,
        buildUs: sample.buildUs,
        rasterUs: sample.rasterUs,
        totalUs: sample.totalUs,
      );
    }

    if (!hasSamples) {
      return;
    }

    _snapshot = _aggregator.snapshot();
  }

  void addSample({
    required int frameEndUs,
    required int buildUs,
    required int rasterUs,
    required int totalUs,
  }) {
    addFrameSample(
      FrameSample(
        frameEndUs: frameEndUs,
        buildUs: buildUs,
        rasterUs: rasterUs,
        totalUs: totalUs,
      ),
    );
  }

  Map<String, Object?> buildObservabilityLog({
    String? scenario,
    Map<String, Object?>? scenarioSettings,
  }) {
    return _observabilityLog.buildUnifiedLog(
      snapshot: _snapshot,
      scenario: scenario,
      scenarioSettings: scenarioSettings,
    );
  }

  void _clearCapturedData({required double targetRefreshRate}) {
    _aggregator.clear();
    _observabilityLog.clear();
    _snapshot =
        FrameMetricsSnapshot.empty(targetRefreshRate: targetRefreshRate);
  }
}
