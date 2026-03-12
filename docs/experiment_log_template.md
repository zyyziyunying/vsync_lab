# Experiment Log Template

Use one copy of this template for each experiment run. Keep raw captures in `artifacts/`, and only check them into git when the change specifically requires evidence in the repo.

Before filling this template, make sure the device already exists in [device_matrix.md](device_matrix.md) and use the same `device_alias`.

## 1. Copyable template

````md
# Experiment: <YYYY-MM-DD> <scenario> <device_alias>

## Goal
- question:
- expected signal:
- compared against:

## Environment
- date:
- owner:
- branch:
- commit:
- device_alias:
- package_name: `com.harrypet.vsync_lab`
- app_target: `diagnosis_default` / `legacy_stress`
- scenario: `state_commit` / `route_commit` / `animation` / `scroll`
- target_refresh_rate_hz:
- warmup_seconds:
- capture_seconds:

## Scenario settings
- animation:
  - particle_count:
  - cpu_workload:
- scroll:
  - item_count:
  - blur_enabled:
  - auto_scroll_enabled:
- other_runtime_notes:

## Commands
```powershell
flutter run -t lib/main_legacy.dart -d <device_id>
./scripts/pull_and_analyze_frame_log.ps1 -Scenario <scenario>
./scripts/collect_gfxinfo.ps1 -PackageName com.harrypet.vsync_lab
./scripts/collect_perfetto.ps1 -TraceSeconds <seconds>
```

## Artifacts
- frame_log_json:
- frame_log_analysis_output:
- gfxinfo_txt:
- device_info_txt:
- perfetto_or_atrace:
- screenshots_or_screen_recording:

## Frame log metadata
- schema_version:
- log_type:
- generated_at:
- target_refresh_rate_hz:
- frame_budget_ms:
- scenario_settings:
- record_count:
- max_records:

## Analyzer summary
- recent_window:
- warmup_skip:
- all.avg_fps_est:
- all.over_budget_ratio:
- all.vsync_miss_ratio:
- all.max_consecutive_vsync_miss:
- recent.avg_fps_est:
- recent.vsync_miss_ratio:
- post_warmup.avg_fps_est:
- post_warmup.vsync_miss_ratio:
- build_p95_ms:
- raster_p95_ms:
- total_p95_ms:

## Worst frames / streaks
- top_frame_by_total_ms:
- top_frame_by_interval_ms:
- longest_vsync_miss_streak:
- trend_by_chunk:

## gfxinfo summary
- janky_frames:
- percentile_90_ms:
- percentile_95_ms:
- percentile_99_ms:
- notes:

## Perfetto / trace notes
- trace_type: `pftrace` / `atrace`
- abnormal_time_range:
- choreographer_or_vsync_observation:
- flutter_ui_thread_observation:
- flutter_raster_thread_observation:
- surfaceflinger_or_frame_timeline_observation:

## Conclusion
- classification: `vsync_source_gap` / `ui_thread_over_budget` / `raster_over_budget` / `mixed` / `inconclusive`
- confidence:
- next_action:
- regression_risk:
````

## 2. Minimal usage notes

- Until diagnosis export lands, this template mainly covers the legacy frame-log workflow launched through `main_legacy.dart`.
- The in-app button is `Save frame log`. It writes the latest observability log into the app cache; `pull_and_analyze_frame_log.ps1` then pulls and analyzes it.
- `collect_gfxinfo.ps1` writes both device/display information and `framestats` output into `artifacts/gfxinfo/`.
- `collect_perfetto.ps1` prefers Perfetto and automatically falls back to `atrace` on Android 10 devices that cannot produce a usable `.pftrace`.
- `analyze_frame_log.ps1` already computes the fields listed in `Analyzer summary`, `Worst frames / streaks`, and chunk trends. Paste those values directly instead of re-deriving them by hand.

## 3. When to update this file

Update this template whenever one of these changes:

- the saved frame-log schema or required fields change
- the experiment scripts change their outputs or artifact paths
- the standard diagnosis flow changes for Android 10 baseline devices
