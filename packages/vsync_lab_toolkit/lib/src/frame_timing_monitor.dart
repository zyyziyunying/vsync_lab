import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'argument_validation.dart';
import 'frame_log_file_exporter.dart';
import 'frame_metrics_aggregator.dart';
import 'frame_metrics_snapshot.dart';
import 'frame_observability_log.dart';
import 'frame_sample.dart';
import 'frame_timing_adapter.dart';

class FrameTimingMonitor extends ChangeNotifier {
  FrameTimingMonitor({
    double targetRefreshRate = 60,
    int maxSamples = 240,
    int maxLogRecords = 1200,
    String scenario = 'unknown',
    FrameLogExporter exporter = const FrameLogFileExporter(),
    Map<String, Object?> Function()? scenarioSettingsBuilder,
    bool autoSaveOnBufferFull = true,
    ValueChanged<FrameLogSaveResult>? onFrameLogSaved,
    void Function(Object error, StackTrace stackTrace)? onFrameLogSaveError,
  }) : this._(
          targetRefreshRate: validateTargetRefreshRate(targetRefreshRate),
          maxSamples: validatePositiveInt(maxSamples, 'maxSamples'),
          maxLogRecords: validatePositiveInt(
            maxLogRecords,
            'maxLogRecords',
          ),
          scenario: scenario,
          exporter: exporter,
          scenarioSettingsBuilder: scenarioSettingsBuilder,
          autoSaveOnBufferFull: autoSaveOnBufferFull,
          onFrameLogSaved: onFrameLogSaved,
          onFrameLogSaveError: onFrameLogSaveError,
        );

  FrameTimingMonitor._({
    required double targetRefreshRate,
    required int maxSamples,
    required int maxLogRecords,
    required this.scenario,
    required FrameLogExporter exporter,
    required Map<String, Object?> Function()? scenarioSettingsBuilder,
    required this.autoSaveOnBufferFull,
    required ValueChanged<FrameLogSaveResult>? onFrameLogSaved,
    required void Function(Object error, StackTrace stackTrace)?
        onFrameLogSaveError,
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
  final Map<String, Object?> Function()? _scenarioSettingsBuilder;
  final ValueChanged<FrameLogSaveResult>? _onFrameLogSaved;
  final void Function(Object error, StackTrace stackTrace)?
      _onFrameLogSaveError;

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
    final validatedHz = validateTargetRefreshRate(hz);

    _aggregator.updateTargetRefreshRate(validatedHz);
    _observabilityLog.updateTargetRefreshRate(validatedHz);
    _snapshot = _aggregator.sampleCount < 2
        ? FrameMetricsSnapshot.empty(targetRefreshRate: validatedHz)
        : _aggregator.snapshot();
    notifyListeners();
  }

  Map<String, Object?> buildObservabilityLog({
    String? scenario,
    Map<String, Object?>? scenarioSettings,
  }) {
    return _observabilityLog.buildUnifiedLog(
      snapshot: _snapshot,
      scenario: scenario ?? this.scenario,
      scenarioSettings: scenarioSettings ?? _scenarioSettingsBuilder?.call(),
    );
  }

  Future<FrameLogSaveResult> saveObservabilityLog({
    String? scenario,
    Map<String, Object?>? scenarioSettings,
  }) {
    return _saveObservabilityLog(
      scenario: scenario,
      scenarioSettings: scenarioSettings,
      markAutoSaved: false,
    );
  }

  Future<FrameLogSaveResult> _saveObservabilityLog({
    String? scenario,
    Map<String, Object?>? scenarioSettings,
    required bool markAutoSaved,
  }) {
    final pendingSave = _pendingSave;
    if (pendingSave != null) {
      return pendingSave;
    }

    _isSavingObservabilityLog = true;
    _lastFrameLogSaveError = null;
    notifyListeners();

    final saveFuture = Future<FrameLogSaveResult>.sync(() {
      return _exporter.save(
        buildObservabilityLog(
          scenario: scenario,
          scenarioSettings: scenarioSettings,
        ),
      );
    }).then((result) {
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
    _recordFrameSample(frameSampleFromFrameTiming(timing));
    _finishRecordingBatch();
  }

  void addSample({
    required int frameEndUs,
    required int buildUs,
    required int rasterUs,
    required int totalUs,
  }) {
    _recordFrameSample(
      FrameSample(
        frameEndUs: frameEndUs,
        buildUs: buildUs,
        rasterUs: rasterUs,
        totalUs: totalUs,
      ),
    );
    _finishRecordingBatch();
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final sample in frameSamplesFromFrameTimings(timings)) {
      _recordFrameSample(sample);
    }
    _finishRecordingBatch();
  }

  void _recordFrameSample(FrameSample sample) {
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
      _saveObservabilityLog(
        markAutoSaved: true,
      ).then<void>((_) {}, onError: (Object error, StackTrace stackTrace) {}),
    );
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
