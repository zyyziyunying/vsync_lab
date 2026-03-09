# vsync_lab_toolkit

Reusable Flutter frame timing monitoring and frame-log exporting extracted from `vsync_lab`.

## What it provides

- `FrameTimingMonitor`: listens to `FrameTiming`, aggregates rolling metrics, and manages frame-log capture.
- `FrameMetricsSnapshot`: immutable summary of the current rolling window.
- `FrameObservabilityLog`: bounded per-frame log builder for later export or analysis.
- `FrameLogExporter` and `FrameLogFileExporter`: save unified logs to app cache.

## Requirements

- Flutter app runtime
- Android-focused workflow today
- Flutter SDK compatible with Dart `^3.11.0`

This package currently depends on Flutter runtime APIs such as `WidgetsBinding` and `FrameTiming`, so it is intended for Flutter apps rather than pure Dart usage.

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
  scenarioSettingsBuilder: () => <String, dynamic>{
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

## Example

See `example/lib/main.dart` for a minimal Flutter app that:

- initializes `FrameTimingMonitor`
- starts monitoring immediately
- shows live snapshot values
- manually saves a frame log with one button

## Public entrypoint

Import the package barrel:

```dart
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';
```

## Validate locally

From the package directory:

```bash
flutter analyze
flutter test
```
