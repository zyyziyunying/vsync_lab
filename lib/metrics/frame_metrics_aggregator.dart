import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'frame_metrics_snapshot.dart';

class FrameMetricsAggregator {
  FrameMetricsAggregator({
    required double targetRefreshRate,
    this.maxSamples = 240,
  }) : _targetRefreshRate = targetRefreshRate;

  final int maxSamples;
  final Queue<_FrameSample> _samples = Queue<_FrameSample>();

  double _targetRefreshRate;

  double get targetRefreshRate => _targetRefreshRate;
  int get sampleCount => _samples.length;

  void updateTargetRefreshRate(double value) {
    _targetRefreshRate = value;
  }

  void clear() {
    _samples.clear();
  }

  void addTiming(FrameTiming timing) {
    final frameEndUs = timing.timestampInMicroseconds(FramePhase.rasterFinish);
    _samples.add(
      _FrameSample(
        frameEndUs: frameEndUs,
        buildMs: _durationToMs(timing.buildDuration),
        rasterMs: _durationToMs(timing.rasterDuration),
        totalMs: _durationToMs(timing.totalSpan),
      ),
    );

    while (_samples.length > maxSamples) {
      _samples.removeFirst();
    }
  }

  FrameMetricsSnapshot snapshot() {
    if (_samples.length < 2) {
      return FrameMetricsSnapshot.empty(targetRefreshRate: _targetRefreshRate);
    }

    final sampleList = _samples.toList(growable: false);
    final intervalsMs = <double>[];
    for (var index = 1; index < sampleList.length; index++) {
      final deltaUs =
          sampleList[index].frameEndUs - sampleList[index - 1].frameEndUs;
      intervalsMs.add(deltaUs / 1000);
    }

    final averageIntervalMs = _average(intervalsMs);
    final frameBudgetMs = 1000 / _targetRefreshRate;

    final averageFps = averageIntervalMs == 0 ? 0.0 : 1000 / averageIntervalMs;

    final worstIntervals = <double>[...intervalsMs]
      ..sort((a, b) => b.compareTo(a));
    final worstCount = math.max(1, (worstIntervals.length * 0.01).ceil());
    final low1PercentIntervalMs = _average(worstIntervals.take(worstCount));
    final low1PercentFps =
        low1PercentIntervalMs == 0 ? 0.0 : 1000 / low1PercentIntervalMs;

    final jankCount =
        sampleList.where((sample) => sample.totalMs > frameBudgetMs).length;
    final jankRatio = sampleList.isEmpty ? 0.0 : jankCount / sampleList.length;

    final intervalStdDevMs = _stdDev(intervalsMs, averageIntervalMs);

    final missThresholdMs = frameBudgetMs * 1.5;
    var vsyncMissCount = 0;
    var currentStreak = 0;
    var maxStreak = 0;
    for (final interval in intervalsMs) {
      if (interval > missThresholdMs) {
        vsyncMissCount++;
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }

    return FrameMetricsSnapshot(
      generatedAt: DateTime.now(),
      targetRefreshRate: _targetRefreshRate,
      sampleCount: sampleList.length,
      averageFps: averageFps,
      low1PercentFps: low1PercentFps,
      jankRatio: jankRatio,
      frameIntervalStdDevMs: intervalStdDevMs,
      vsyncMissCount: vsyncMissCount,
      maxConsecutiveVsyncMiss: maxStreak,
      averageUiThreadMs: _average(sampleList.map((sample) => sample.buildMs)),
      averageRasterThreadMs:
          _average(sampleList.map((sample) => sample.rasterMs)),
      frameBudgetMs: frameBudgetMs,
    );
  }

  static double _durationToMs(Duration duration) =>
      duration.inMicroseconds / 1000;

  static double _average(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      return 0;
    }

    final total = list.fold<double>(0, (sum, value) => sum + value);
    return total / list.length;
  }

  static double _stdDev(List<double> values, double average) {
    if (values.isEmpty) {
      return 0;
    }

    var variance = 0.0;
    for (final value in values) {
      variance += math.pow(value - average, 2) as double;
    }
    variance /= values.length;
    return math.sqrt(variance).toDouble();
  }
}

class _FrameSample {
  const _FrameSample({
    required this.frameEndUs,
    required this.buildMs,
    required this.rasterMs,
    required this.totalMs,
  });

  final int frameEndUs;
  final double buildMs;
  final double rasterMs;
  final double totalMs;
}
