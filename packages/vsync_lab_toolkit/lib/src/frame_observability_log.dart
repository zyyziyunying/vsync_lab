import 'dart:collection';

import 'argument_validation.dart';
import 'frame_metrics_snapshot.dart';

class FrameObservabilityLog {
  FrameObservabilityLog({
    required double targetRefreshRate,
    int maxRecords = 1200,
  })  : maxRecords = validatePositiveInt(maxRecords, 'maxRecords'),
        _targetRefreshRate = validateTargetRefreshRate(targetRefreshRate);

  final int maxRecords;
  final Queue<FrameIntervalRecord> _records = Queue<FrameIntervalRecord>();

  double _targetRefreshRate;
  int _nextFrameIndex = 1;
  int? _lastFrameEndUs;

  double get targetRefreshRate => _targetRefreshRate;
  int get recordCount => _records.length;
  bool get isFull => _records.length >= maxRecords;

  void updateTargetRefreshRate(double hz) {
    _targetRefreshRate = validateTargetRefreshRate(hz);
  }

  void clear() {
    _records.clear();
    _nextFrameIndex = 1;
    _lastFrameEndUs = null;
  }

  void addSample({
    required int frameEndUs,
    required int buildUs,
    required int rasterUs,
    required int totalUs,
  }) {
    final expectedIntervalUs =
        expectedFrameIntervalUsForRefreshRate(_targetRefreshRate);
    final actualIntervalUs =
        _lastFrameEndUs == null ? null : frameEndUs - _lastFrameEndUs!;
    final intervalDeltaUs =
        actualIntervalUs == null ? null : actualIntervalUs - expectedIntervalUs;
    final intervalDeltaRatio =
        intervalDeltaUs == null ? null : intervalDeltaUs / expectedIntervalUs;

    final frameBudgetUs = expectedIntervalUs;
    final missThresholdUs = (expectedIntervalUs * 1.5).round();
    final isVsyncMiss =
        actualIntervalUs != null && actualIntervalUs > missThresholdUs;

    _records.add(
      FrameIntervalRecord(
        frameIndex: _nextFrameIndex,
        frameEndUs: frameEndUs,
        targetRefreshRateHz: _targetRefreshRate,
        expectedIntervalUs: expectedIntervalUs,
        actualIntervalUs: actualIntervalUs,
        intervalDeltaUs: intervalDeltaUs,
        intervalDeltaRatio: intervalDeltaRatio,
        buildUs: buildUs,
        rasterUs: rasterUs,
        totalUs: totalUs,
        isOverBudget: frameBudgetUs > 0 && totalUs > frameBudgetUs,
        isVsyncMiss: isVsyncMiss,
      ),
    );
    _lastFrameEndUs = frameEndUs;
    _nextFrameIndex++;

    while (_records.length > maxRecords) {
      _records.removeFirst();
    }
  }

  Map<String, dynamic> buildUnifiedLog({
    required FrameMetricsSnapshot snapshot,
    String? scenario,
    Map<String, dynamic>? scenarioSettings,
  }) {
    return <String, dynamic>{
      'schemaVersion': 1,
      'logType': 'vsync_lab.frame_observability',
      'generatedAt': DateTime.now().toIso8601String(),
      'targetRefreshRateHz': _targetRefreshRate,
      'frameBudgetMs': frameBudgetMsForRefreshRate(_targetRefreshRate),
      'recordCount': recordCount,
      'maxRecords': maxRecords,
      'scenario': scenario ?? 'unknown',
      if (scenarioSettings != null && scenarioSettings.isNotEmpty)
        'scenarioSettings': scenarioSettings,
      'snapshot': snapshot.toJson(),
      'records':
          _records.map((record) => record.toJson()).toList(growable: false),
    };
  }
}

class FrameIntervalRecord {
  const FrameIntervalRecord({
    required this.frameIndex,
    required this.frameEndUs,
    required this.targetRefreshRateHz,
    required this.expectedIntervalUs,
    required this.actualIntervalUs,
    required this.intervalDeltaUs,
    required this.intervalDeltaRatio,
    required this.buildUs,
    required this.rasterUs,
    required this.totalUs,
    required this.isOverBudget,
    required this.isVsyncMiss,
  });

  final int frameIndex;
  final int frameEndUs;
  final double targetRefreshRateHz;
  final int expectedIntervalUs;
  final int? actualIntervalUs;
  final int? intervalDeltaUs;
  final double? intervalDeltaRatio;
  final int buildUs;
  final int rasterUs;
  final int totalUs;
  final bool isOverBudget;
  final bool isVsyncMiss;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'frameIndex': frameIndex,
      'frameEndUs': frameEndUs,
      'targetRefreshRateHz': targetRefreshRateHz,
      'expectedIntervalUs': expectedIntervalUs,
      'actualIntervalUs': actualIntervalUs,
      'intervalDeltaUs': intervalDeltaUs,
      'intervalDeltaRatio': intervalDeltaRatio,
      'buildUs': buildUs,
      'rasterUs': rasterUs,
      'totalUs': totalUs,
      'isOverBudget': isOverBudget,
      'isVsyncMiss': isVsyncMiss,
    };
  }
}
