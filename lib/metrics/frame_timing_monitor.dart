import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'frame_observability_log.dart';
import 'frame_metrics_aggregator.dart';
import 'frame_metrics_snapshot.dart';

class FrameTimingMonitor extends ChangeNotifier {
  FrameTimingMonitor({
    double targetRefreshRate = 60,
    int maxSamples = 240,
    int maxLogRecords = 1200,
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
  bool _running = false;

  FrameMetricsSnapshot get snapshot => _snapshot;
  bool get isRunning => _running;
  double get targetRefreshRate => _aggregator.targetRefreshRate;
  int get observabilityRecordCount => _observabilityLog.recordCount;

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
      scenario: scenario,
      scenarioSettings: scenarioSettings,
    );
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _aggregator.addTiming(timing);
      _observabilityLog.addTiming(timing);
    }
    _snapshot = _aggregator.snapshot();
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
