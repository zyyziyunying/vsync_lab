import 'argument_validation.dart';

class FrameMetricsSnapshot {
  const FrameMetricsSnapshot({
    required this.generatedAt,
    required this.targetRefreshRate,
    required this.sampleCount,
    required this.averageFps,
    required this.low1PercentFps,
    required this.jankRatio,
    required this.frameIntervalStdDevMs,
    required this.vsyncMissCount,
    required this.maxConsecutiveVsyncMiss,
    required this.averageUiThreadMs,
    required this.averageRasterThreadMs,
    required this.frameBudgetMs,
  });

  factory FrameMetricsSnapshot.empty({required double targetRefreshRate}) {
    final validatedTargetRefreshRate =
        validateTargetRefreshRate(targetRefreshRate);

    return FrameMetricsSnapshot(
      generatedAt: DateTime.now(),
      targetRefreshRate: validatedTargetRefreshRate,
      sampleCount: 0,
      averageFps: 0,
      low1PercentFps: 0,
      jankRatio: 0,
      frameIntervalStdDevMs: 0,
      vsyncMissCount: 0,
      maxConsecutiveVsyncMiss: 0,
      averageUiThreadMs: 0,
      averageRasterThreadMs: 0,
      frameBudgetMs: frameBudgetMsForRefreshRate(validatedTargetRefreshRate),
    );
  }

  final DateTime generatedAt;
  final double targetRefreshRate;
  final int sampleCount;

  final double averageFps;
  final double low1PercentFps;
  final double jankRatio;
  final double frameIntervalStdDevMs;

  final int vsyncMissCount;
  final int maxConsecutiveVsyncMiss;

  final double averageUiThreadMs;
  final double averageRasterThreadMs;
  final double frameBudgetMs;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'generatedAt': generatedAt.toIso8601String(),
      'targetRefreshRate': targetRefreshRate,
      'sampleCount': sampleCount,
      'averageFps': averageFps,
      'low1PercentFps': low1PercentFps,
      'jankRatio': jankRatio,
      'frameIntervalStdDevMs': frameIntervalStdDevMs,
      'vsyncMissCount': vsyncMissCount,
      'maxConsecutiveVsyncMiss': maxConsecutiveVsyncMiss,
      'averageUiThreadMs': averageUiThreadMs,
      'averageRasterThreadMs': averageRasterThreadMs,
      'frameBudgetMs': frameBudgetMs,
    };
  }
}
