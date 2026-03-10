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

  FrameObservabilityLogDocument buildDocument({
    required FrameMetricsSnapshot snapshot,
    String? scenario,
    Map<String, Object?>? scenarioSettings,
  }) {
    return FrameObservabilityLogDocument(
      generatedAt: DateTime.now(),
      targetRefreshRateHz: _targetRefreshRate,
      frameBudgetMs: frameBudgetMsForRefreshRate(_targetRefreshRate),
      maxRecords: maxRecords,
      scenario: scenario ?? 'unknown',
      scenarioSettings: scenarioSettings,
      snapshot: snapshot,
      records: _records,
    );
  }

  Map<String, Object?> buildUnifiedLog({
    required FrameMetricsSnapshot snapshot,
    String? scenario,
    Map<String, Object?>? scenarioSettings,
  }) {
    return buildDocument(
      snapshot: snapshot,
      scenario: scenario,
      scenarioSettings: scenarioSettings,
    ).toJson();
  }
}

class FrameObservabilityLogDocument {
  static const int currentSchemaVersion = 1;
  static const String currentLogType = 'vsync_lab.frame_observability';

  FrameObservabilityLogDocument({
    required this.generatedAt,
    required this.targetRefreshRateHz,
    required this.frameBudgetMs,
    required this.maxRecords,
    required String scenario,
    Map<String, Object?>? scenarioSettings,
    required this.snapshot,
    required Iterable<FrameIntervalRecord> records,
    this.schemaVersion = currentSchemaVersion,
    this.logType = currentLogType,
  })  : scenario = _normalizeScenario(scenario),
        scenarioSettings = _normalizeScenarioSettings(scenarioSettings),
        records = List<FrameIntervalRecord>.unmodifiable(records) {
    if (schemaVersion <= 0) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'schemaVersion must be greater than 0.',
      );
    }
    if (logType.trim().isEmpty) {
      throw ArgumentError.value(logType, 'logType', 'logType cannot be empty.');
    }
  }

  final int schemaVersion;
  final String logType;
  final DateTime generatedAt;
  final double targetRefreshRateHz;
  final double frameBudgetMs;
  final int maxRecords;
  final String scenario;
  final Map<String, Object?>? scenarioSettings;
  final FrameMetricsSnapshot snapshot;
  final List<FrameIntervalRecord> records;

  int get recordCount => records.length;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'logType': logType,
      'generatedAt': generatedAt.toIso8601String(),
      'targetRefreshRateHz': targetRefreshRateHz,
      'frameBudgetMs': frameBudgetMs,
      'recordCount': recordCount,
      'maxRecords': maxRecords,
      'scenario': scenario,
      if (scenarioSettings != null) 'scenarioSettings': scenarioSettings,
      'snapshot': snapshot.toJson(),
      'records':
          records.map((record) => record.toJson()).toList(growable: false),
    };
  }

  static String _normalizeScenario(String scenario) {
    final trimmed = scenario.trim();
    return trimmed.isEmpty ? 'unknown' : trimmed;
  }

  static Map<String, Object?>? _normalizeScenarioSettings(
    Map<String, Object?>? scenarioSettings,
  ) {
    if (scenarioSettings == null || scenarioSettings.isEmpty) {
      return null;
    }
    final normalized = <String, Object?>{};
    scenarioSettings.forEach((key, value) {
      normalized[key] = _normalizeJsonValue(
        value,
        path: 'scenarioSettings.$key',
      );
    });
    return Map<String, Object?>.unmodifiable(normalized);
  }

  static Object? _normalizeJsonValue(Object? value, {required String path}) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    if (value is Map) {
      final normalized = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw ArgumentError.value(
            value,
            'scenarioSettings',
            'scenarioSettings keys must be strings. Invalid entry at $path.',
          );
        }
        normalized[key] = _normalizeJsonValue(
          entry.value,
          path: '$path.$key',
        );
      }
      return Map<String, Object?>.unmodifiable(normalized);
    }

    if (value is Iterable) {
      return List<Object?>.unmodifiable(
        value
            .map((item) => _normalizeJsonValue(item, path: '$path[]'))
            .toList(growable: false),
      );
    }

    throw ArgumentError.value(
      value,
      'scenarioSettings',
      'scenarioSettings must contain only JSON-compatible values. '
          'Unsupported value at $path: ${value.runtimeType}.',
    );
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

  Map<String, Object?> toJson() {
    return <String, Object?>{
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
