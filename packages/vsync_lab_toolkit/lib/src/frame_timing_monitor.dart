import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'frame_log_file_exporter.dart';
import 'frame_metrics_aggregator.dart';
import 'frame_metrics_snapshot.dart';
import 'frame_observability_log.dart';

typedef FrameLogScenarioSettingsBuilder = Map<String, dynamic> Function();
typedef FrameLogSaveErrorCallback = void Function(
  Object error,
  StackTrace stackTrace,
);

class FrameTimingMonitor extends ChangeNotifier {
  FrameTimingMonitor({
    double targetRefreshRate = 60,
    int maxSamples = 240,
    int maxLogRecords = 1200,
    this.scenario = 'unknown',
    FrameLogExporter exporter = const FrameLogFileExporter(),
    FrameLogScenarioSettingsBuilder? scenarioSettingsBuilder,
    this.autoSaveOnBufferFull = true,
    ValueChanged<FrameLogSaveResult>? onFrameLogSaved,
    FrameLogSaveErrorCallback? onFrameLogSaveError,
  })  : _aggregator = FrameMetricsAggregator(
          targetRefreshRate: targetRefreshRate,
          maxSamples: maxSamples,
        ),
        _observabilityLog = FrameObservabilityLog(
          targetRefreshRate: targetRefreshRate,
          maxRecords: maxLogRecords,
        ),
        _exporter = exporter,
        _scenarioSettingsBuilder = scenarioSettingsBuilder,
        _onFrameLogSaved = onFrameLogSaved,
        _onFrameLogSaveError = onFrameLogSaveError,
        _snapshot =
            FrameMetricsSnapshot.empty(targetRefreshRate: targetRefreshRate);

  final FrameMetricsAggregator _aggregator;
  final FrameObservabilityLog _observabilityLog;
  final FrameLogExporter _exporter;
  final FrameLogScenarioSettingsBuilder? _scenarioSettingsBuilder;
  final ValueChanged<FrameLogSaveResult>? _onFrameLogSaved;
  final FrameLogSaveErrorCallback? _onFrameLogSaveError;

  final String scenario;
  final bool autoSaveOnBufferFull;

  FrameMetricsSnapshot _snapshot;
  bool _running = false;
  bool _isSavingObservabilityLog = false;
  bool _hasAutoSavedCurrentBuffer = false;
  FrameLogSaveResult? _lastFrameLogSaveResult;
  Object? _lastFrameLogSaveError;
  Future<FrameLogSaveResult>? _pendingSave;

  FrameMetricsSnapshot get snapshot => _snapshot;
  bool get isRunning => _running;
  double get targetRefreshRate => _aggregator.targetRefreshRate;
  int get observabilityRecordCount => _observabilityLog.recordCount;
  bool get isObservabilityLogFull => _observabilityLog.isFull;
  bool get isSavingObservabilityLog => _isSavingObservabilityLog;
  bool get hasAutoSavedCurrentBuffer => _hasAutoSavedCurrentBuffer;
  FrameLogSaveResult? get lastFrameLogSaveResult => _lastFrameLogSaveResult;
  Object? get lastFrameLogSaveError => _lastFrameLogSaveError;

  void start() {
    if (_running) {
      return;
    }
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
    _running = true;
    notifyListeners();
  }

  void stop() {
    if (!_running) {
      return;
    }
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);
    _running = false;
    notifyListeners();
  }

  void reset() {
    _aggregator.clear();
    _observabilityLog.clear();
    _hasAutoSavedCurrentBuffer = false;
    _lastFrameLogSaveError = null;
    _snapshot =
        FrameMetricsSnapshot.empty(targetRefreshRate: targetRefreshRate);
    notifyListeners();
  }

  void applyTargetRefreshRate(double hz) {
    _aggregator.updateTargetRefreshRate(hz);
    _observabilityLog.updateTargetRefreshRate(hz);
    _snapshot = _aggregator.sampleCount < 2
        ? FrameMetricsSnapshot.empty(targetRefreshRate: hz)
        : _aggregator.snapshot();
    notifyListeners();
  }

  Map<String, dynamic> buildObservabilityLog({
    String? scenario,
    Map<String, dynamic>? scenarioSettings,
  }) {
    return _observabilityLog.buildUnifiedLog(
      snapshot: _snapshot,
      scenario: scenario ?? this.scenario,
      scenarioSettings: scenarioSettings ?? _scenarioSettingsBuilder?.call(),
    );
  }

  Future<FrameLogSaveResult> saveObservabilityLog({
    String? scenario,
    Map<String, dynamic>? scenarioSettings,
  }) {
    return _saveObservabilityLog(
      scenario: scenario,
      scenarioSettings: scenarioSettings,
      markAutoSaved: false,
    );
  }

  Future<FrameLogSaveResult> _saveObservabilityLog({
    String? scenario,
    Map<String, dynamic>? scenarioSettings,
    required bool markAutoSaved,
  }) {
    final pendingSave = _pendingSave;
    if (pendingSave != null) {
      return pendingSave;
    }

    _isSavingObservabilityLog = true;
    _lastFrameLogSaveError = null;
    notifyListeners();

    final saveFuture = _exporter
        .save(
      buildObservabilityLog(
        scenario: scenario,
        scenarioSettings: scenarioSettings,
      ),
    )
        .then((result) {
      _lastFrameLogSaveResult = result;
      if (markAutoSaved) {
        _hasAutoSavedCurrentBuffer = true;
      }
      _onFrameLogSaved?.call(result);
      return result;
    }).catchError((error, stackTrace) {
      _lastFrameLogSaveError = error;
      _onFrameLogSaveError?.call(error, stackTrace as StackTrace);
      throw error;
    }).whenComplete(() {
      _pendingSave = null;
      _isSavingObservabilityLog = false;
      notifyListeners();
    });

    _pendingSave = saveFuture;
    return saveFuture;
  }

  void addTiming(FrameTiming timing) {
    _recordSample(
      frameEndUs: timing.timestampInMicroseconds(FramePhase.rasterFinish),
      buildUs: timing.buildDuration.inMicroseconds,
      rasterUs: timing.rasterDuration.inMicroseconds,
      totalUs: timing.totalSpan.inMicroseconds,
    );
    _finishRecordingBatch();
  }

  void addSample({
    required int frameEndUs,
    required int buildUs,
    required int rasterUs,
    required int totalUs,
  }) {
    _recordSample(
      frameEndUs: frameEndUs,
      buildUs: buildUs,
      rasterUs: rasterUs,
      totalUs: totalUs,
    );
    _finishRecordingBatch();
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _recordSample(
        frameEndUs: timing.timestampInMicroseconds(FramePhase.rasterFinish),
        buildUs: timing.buildDuration.inMicroseconds,
        rasterUs: timing.rasterDuration.inMicroseconds,
        totalUs: timing.totalSpan.inMicroseconds,
      );
    }
    _finishRecordingBatch();
  }

  void _recordSample({
    required int frameEndUs,
    required int buildUs,
    required int rasterUs,
    required int totalUs,
  }) {
    _aggregator.addSample(
      frameEndUs: frameEndUs,
      buildUs: buildUs,
      rasterUs: rasterUs,
      totalUs: totalUs,
    );
    _observabilityLog.addSample(
      frameEndUs: frameEndUs,
      buildUs: buildUs,
      rasterUs: rasterUs,
      totalUs: totalUs,
    );
  }

  void _finishRecordingBatch() {
    _snapshot = _aggregator.snapshot();
    notifyListeners();
    _maybeAutoSaveObservabilityLog();
  }

  void _maybeAutoSaveObservabilityLog() {
    if (!autoSaveOnBufferFull ||
        !_observabilityLog.isFull ||
        _hasAutoSavedCurrentBuffer ||
        _pendingSave != null) {
      return;
    }

    unawaited(
      _saveObservabilityLog(markAutoSaved: true),
    );
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
