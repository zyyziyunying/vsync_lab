import 'dart:ui';

import 'frame_sample.dart';

FrameSample frameSampleFromFrameTiming(FrameTiming timing) {
  return FrameSample(
    frameEndUs: timing.timestampInMicroseconds(FramePhase.rasterFinish),
    buildUs: timing.buildDuration.inMicroseconds,
    rasterUs: timing.rasterDuration.inMicroseconds,
    totalUs: timing.totalSpan.inMicroseconds,
  );
}

List<FrameSample> frameSamplesFromFrameTimings(Iterable<FrameTiming> timings) {
  return timings.map(frameSampleFromFrameTiming).toList(growable: false);
}
