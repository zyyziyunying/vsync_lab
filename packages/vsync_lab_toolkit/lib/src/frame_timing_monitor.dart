import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'argument_validation.dart';
import 'frame_log_exporter.dart';
import 'frame_log_file_exporter.dart';
import 'frame_metrics_recorder.dart';
import 'frame_metrics_snapshot.dart';
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
  })  : _recorder = FrameMetricsRecorder(
          targetRefreshRate: targetRefreshRate,
          maxSamples: maxSamples,
          maxLogRecords: maxLogRecords,
        ),
        _exporter = exporter,
        _scenarioSettingsBuilder = scenarioSettingsBuilder,
        _onFrameLogSaved = onFrameLogSaved,
        _onFrameLogSaveError = onFrameLogSaveError;

  final FrameMetricsRecorder _recorder;
  final FrameLogExporter _exporter;
  final Map<String, Object?> Function()? _scenarioSettingsBuilder;
  final ValueChanged<FrameLogSaveResult>? _onFrameLogSaved;
  final void Function(Object error, StackTrace stackTrace)?
      _onFrameLogSaveError;

  final String scenario;
  final bool autoSaveOnBufferFull;

  bool _running = false;
  bool _isSavingObservabilityLog = false;
  bool _hasAutoSavedCurrentBuffer = false;
  int _bufferEpoch = 0;
  FrameLogSaveResult? _lastFrameLogSaveResult;
  Object? _lastFrameLogSaveError;
  Future<FrameLogSaveResult>? _pendingSave;

  FrameMetricsSnapshot get snapshot => _recorder.snapshot;
  bool get isRunning => _running;
  double get targetRefreshRate => _recorder.targetRefreshRate;
  int get observabilityRecordCount => _recorder.observabilityRecordCount;
  bool get isObservabilityLogFull => _recorder.isObservabilityLogFull;
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
    _recorder.reset();
    _resetCaptureBufferState();
    notifyListeners();
  }

  void applyTargetRefreshRate(double hz) {
    final validatedHz = validateTargetRefreshRate(hz);
    if (validatedHz == targetRefreshRate) {
      return;
    }

    _recorder.applyTargetRefreshRate(validatedHz);
    _resetCaptureBufferState();
    notifyListeners();
  }

  Map<String, Object?> buildObservabilityLog({
    String? scenario,
    Map<String, Object?>? scenarioSettings,
  }) {
    return _recorder.buildObservabilityLog(
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

    final saveBufferEpoch = _bufferEpoch;
    final saveFuture = Future<FrameLogSaveResult>.sync(() {
      return _exporter.save(
        buildObservabilityLog(
          scenario: scenario,
          scenarioSettings: scenarioSettings,
        ),
      );
    }).then((result) {
      _lastFrameLogSaveResult = result;
      if (markAutoSaved && saveBufferEpoch == _bufferEpoch) {
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
    final samples = frameSamplesFromFrameTimings(timings);
    if (samples.isEmpty) {
      return;
    }

    _recorder.addFrameSamples(samples);
    _finishRecordingBatch();
  }

  void _recordFrameSample(FrameSample sample) {
    _recorder.addFrameSample(sample);
  }

  void _finishRecordingBatch() {
    notifyListeners();
    _maybeAutoSaveObservabilityLog();
  }

  void _resetCaptureBufferState() {
    _bufferEpoch++;
    _hasAutoSavedCurrentBuffer = false;
    _lastFrameLogSaveError = null;
  }

  void _maybeAutoSaveObservabilityLog() {
    if (!autoSaveOnBufferFull ||
        !_recorder.isObservabilityLogFull ||
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
