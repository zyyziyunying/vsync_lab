# vsync_lab_toolkit

Reusable Flutter frame timing monitoring and frame-log exporting extracted from `vsync_lab`.

## What it provides

- `FrameTimingMonitor`: listens to `FrameTiming`, aggregates rolling metrics, and manages frame-log capture.
- `FrameMetricsSnapshot`: immutable summary of the current rolling window.
- `FrameLogExporter` and `FrameLogFileExporter`: save unified logs to app cache.
- `FrameLogSaveResult`: carries exported file names and cache paths back to the host app.

## Stable public API

Import the package barrel:

```dart
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';
```

The stable barrel export is intentionally limited to:

- `FrameTimingMonitor`
- `FrameMetricsSnapshot`
- `FrameLogExporter`
- `FrameLogFileExporter`
- `FrameLogSaveResult`

Internal implementation details such as `FrameMetricsAggregator`,
`FrameObservabilityLog`, and `FrameIntervalRecord` remain under `lib/src/` and
are not part of the stable public API.

## Requirements

- Flutter app runtime
- Android-focused workflow today
- Flutter SDK compatible with Dart `^3.11.0`

Core aggregation and observability logic operate on plain sample data so they can be exercised without real Flutter frame callbacks. Flutter runtime APIs such as `WidgetsBinding` and `FrameTiming` are now confined to the monitor's integration layer, so the package remains intended for Flutter apps while keeping its core logic easier to test.

## Install

Use it as a path dependency inside the workspace or as a git dependency from another app.

```yaml
dependencies:
  vsync_lab_toolkit:
    path: ../vsync_lab/packages/vsync_lab_toolkit
```

## Minimal integration

```dart
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

final monitor = FrameTimingMonitor(
  targetRefreshRate: 60,
  scenario: 'home_feed',
  scenarioSettingsBuilder: () => <String, Object?>{
    'entry': 'feed_tab',
  },
);

monitor.start();
```

Manual frame-log save:

```dart
final result = await monitor.saveObservabilityLog();
debugPrint(result.latestAbsolutePath);
```

Repo-specific follow-up actions such as `adb exec-out run-as ...` or
archiving into `artifacts/` are intentionally left to the host app or scripts.
Use `result.scenario`, `result.latestFileName`, and `result.latestAbsolutePath`
to build those commands outside the package.

Default behavior: when the frame-log ring buffer reaches capacity, `FrameTimingMonitor` auto-saves the current log once per filled buffer. Calling `reset()` clears the buffer and re-arms auto-save.

`targetRefreshRate`, `maxSamples`, and `maxLogRecords` must all be greater than `0`. Invalid values throw `ArgumentError` so edge-case behavior stays explicit.

The unified frame-log envelope keeps `schemaVersion`, `logType`, `generatedAt`, `targetRefreshRateHz`, `frameBudgetMs`, `recordCount`, `maxRecords`, `scenario`, `snapshot`, and `records` as toolkit-owned stable fields. `scenarioSettings` remains optional and host-defined, but it must contain only JSON-compatible values.

## Example

See `example/lib/main.dart` for a minimal Flutter app that:

- initializes `FrameTimingMonitor`
- starts monitoring immediately
- shows live snapshot values
- manually saves a frame log with one button

## Validate locally

From the package directory:

```bash
flutter analyze
flutter test
```
