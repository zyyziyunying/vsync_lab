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

## Data collection scripts

- `scripts/collect_gfxinfo.ps1`
- `scripts/collect_perfetto.ps1`
- `scripts/analyze_frame_log.ps1`

Example:

```powershell
./scripts/collect_gfxinfo.ps1 -PackageName com.harrypet.vsync_lab
./scripts/collect_perfetto.ps1 -TraceSeconds 15
./scripts/analyze_frame_log.ps1 -Path artifacts/frame_log_animation_latest.json
```

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
