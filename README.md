# VSync Lab

Android-only Flutter lab used to reproduce and observe VSync instability and frame pacing issues on legacy devices (Phase 0 baseline).

## Scope

- Platform: Android only
- Baseline OS: Android 10 (API 29)
- Goal in this phase: make jank and VSync-miss symptoms reproducible and measurable

## Common package usage

This app intentionally reuses workspace helpers from `packages/common`:

- `RouterFactory`, `NavigatorManager`, and `go_router` re-export for fast route bootstrap
- `CommonAdaptiveLayout` for compact vs expanded layout switching
- `CommonSectionCard` for reusable card sections
- `DateTimeFormatting.toYmd()` for quick date formatting
- `CommonResult` + `CommonFailure` in refresh-rate input parsing

## Run

From workspace root:

```bash
flutter pub get
cd vsync_lab
flutter run -d <android_device_id>
```

Useful checks:

```bash
cd vsync_lab
flutter analyze
flutter test
```

## In-app scenarios

1. `Animation stress`: particle orbit animation with tunable CPU workload.
2. `Scroll stress`: long list + optional blur + auto-scroll loop.

Both scenarios display live metrics from `FrameTiming` callbacks:

- average FPS
- 1% low FPS
- jank ratio
- frame interval standard deviation
- VSync miss count / max consecutive miss streak
- UI and Raster average time

Panel export actions:

- `Copy JSON`: snapshot metrics for the current rolling window
- `Copy frame log`: Phase 1 unified log (per-frame timestamp, expected interval, actual interval delta, and miss flags)

## Reuse in other apps

The reusable monitor/exporter core now lives in `packages/vsync_lab_toolkit`.

Current status:

- usable from other Flutter apps today through workspace path or git dependency
- not prepared for `pub.dev` publication yet
- intended for Flutter runtime integration, with Android-focused workflow today

Stable public API:

- `FrameTimingMonitor`
- `FrameMetricsSnapshot`
- `FrameLogExporter`
- `FrameLogFileExporter`
- `FrameLogSaveResult`

Do not depend on `lib/src/*` from external apps; those types are still internal implementation details.

Use `path` only for local workspace development:

```yaml
dependencies:
  vsync_lab_toolkit:
    path: ../vsync_lab/packages/vsync_lab_toolkit
```

For external apps, prefer git tags instead of `ref`-based branch pinning.
Recommended tag naming convention:

- `vsync_lab_toolkit-v0.1.0`
- `vsync_lab_toolkit-v0.1.1`
- `vsync_lab_toolkit-v0.2.0`

Recommended git dependency form:

```yaml
environment:
  sdk: ^3.11.0

dependencies:
  vsync_lab_toolkit:
    git:
      url: https://github.com/zyyziyunying/vsync_lab.git
      path: packages/vsync_lab_toolkit
      tag_pattern: vsync_lab_toolkit-v
    version: ^0.1.0
```

If the git remote points to a workspace repo whose root contains `vsync_lab/`, then use `path: vsync_lab/packages/vsync_lab_toolkit`.

This requires Dart `>=3.9.0` in the consuming app and matching git tags in the source repo. Branch-based `ref` examples are intentionally not documented here, because external consumers should depend on released tags instead of moving branches.

At the moment this repo still needs to publish package tags before the git example above becomes usable as-is. Until then, keep using the local `path` form for workspace integration.

Release and tag workflow: see `docs/package_tag_release.md`.

Minimal integration:

```dart
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

late final FrameTimingMonitor monitor;

@override
void initState() {
  super.initState();
  monitor = FrameTimingMonitor(
    targetRefreshRate: 60,
    scenario: 'home_feed',
    scenarioSettingsBuilder: () => <String, Object?>{
      'tab': 'for_you',
    },
  )..start();
}

@override
void dispose() {
  monitor
    ..stop()
    ..dispose();
  super.dispose();
}
```

Default behavior: when the frame-log ring buffer reaches capacity, `FrameTimingMonitor` automatically saves one frame log snapshot to the app cache. Manual saves still work through `saveObservabilityLog()`.

Manual save example:

```dart
final result = await monitor.saveObservabilityLog();
debugPrint(result.latestAbsolutePath);
```

Repo-specific follow-up actions such as `adb exec-out run-as ...`, copying into `artifacts/`, or invoking analysis scripts are intentionally left to the host app or its scripts. Use `result.scenario`, `result.latestFileName`, and `result.latestAbsolutePath` to build those commands outside the package.

For a complete minimal app, see `packages/vsync_lab_toolkit/example/`.

## Data collection scripts

- `scripts/collect_gfxinfo.ps1`
- `scripts/collect_perfetto.ps1`
- `scripts/analyze_frame_log.ps1`
- `scripts/pull_and_analyze_frame_log.ps1`

Example:

```powershell
./scripts/collect_gfxinfo.ps1 -PackageName com.harrypet.vsync_lab
./scripts/collect_perfetto.ps1 -TraceSeconds 15
./scripts/analyze_frame_log.ps1 -Path artifacts/frame_log_animation_latest.json
./scripts/pull_and_analyze_frame_log.ps1 -Scenario animation
```

One-click frame log workflow:

```powershell
./scripts/pull_and_analyze_frame_log.ps1
./scripts/pull_and_analyze_frame_log.ps1 -Scenario animation
./scripts/pull_and_analyze_frame_log.ps1 -UseExistingFile artifacts/frame_log_animation_latest.json
```

- If `-Scenario` is omitted, the script auto-detects the newest `frame_log_*_latest.json` in the app cache.
- If `-UseExistingFile` is provided, the script skips `adb pull` and only runs the analysis step.

Artifacts are stored in `artifacts/`.

## Experiment docs

- `docs/README.md`: project scope, phased goals, and Perfetto workflow
- `docs/device_matrix.md`: device inventory and environment baseline
- `docs/experiment_log_template.md`: per-run evidence template

## Independent repo / submodule note

`vsync_lab/` is initialized as an independent git repository.
When a remote is ready, register it as a workspace submodule from the root repo:

```bash
git submodule add <remote_url> vsync_lab
git submodule update --init --recursive
```
