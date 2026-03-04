import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'frame_metrics_aggregator.dart';
import 'frame_metrics_snapshot.dart';

class FrameTimingMonitor extends ChangeNotifier {
  FrameTimingMonitor({
    double targetRefreshRate = 60,
    int maxSamples = 240,
  })  : _aggregator = FrameMetricsAggregator(
          targetRefreshRate: targetRefreshRate,
          maxSamples: maxSamples,
        ),
        _snapshot =
            FrameMetricsSnapshot.empty(targetRefreshRate: targetRefreshRate);

  final FrameMetricsAggregator _aggregator;

  FrameMetricsSnapshot _snapshot;
  bool _running = false;

  FrameMetricsSnapshot get snapshot => _snapshot;
  bool get isRunning => _running;
  double get targetRefreshRate => _aggregator.targetRefreshRate;

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
    _snapshot =
        FrameMetricsSnapshot.empty(targetRefreshRate: targetRefreshRate);
    notifyListeners();
  }

  void applyTargetRefreshRate(double hz) {
    _aggregator.updateTargetRefreshRate(hz);
    _snapshot = _aggregator.sampleCount < 2
        ? FrameMetricsSnapshot.empty(targetRefreshRate: hz)
        : _aggregator.snapshot();
    notifyListeners();
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _aggregator.addTiming(timing);
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
