# Experiment Log Template

## Metadata

- Date:
- Device:
- Android/API:
- Build mode: (debug/profile/release)
- App commit:
- Workspace commit:
- Scenario: (animation/scroll)
- Duration:

## Scenario Settings

- Target refresh rate:
- Animation particle count:
- Animation workload level:
- Color shift:
- Scroll item count:
- Auto-scroll:
- Blur enabled:

## In-app Frame Metrics Snapshot

Paste copied JSON here:

```json
{
}
```

## System Sampling

- `collect_gfxinfo.ps1` output path:
- `collect_perfetto.ps1` output path:
- In-app unified frame log JSON (`Save frame log` -> prefer `./scripts/pull_and_analyze_frame_log.ps1 -Scenario <scenario>`; use `adb exec-out run-as ... cat ...` only as a manual fallback for `<app_data_dir>/cache/frame_log_<scenario>_latest.json`):
- Additional logs:

## Timeline Observations

- VSync continuity (`view_vsync`/`Choreographer`):
- SurfaceFlinger frame timeline:
- Flutter UI thread behavior:
- Flutter Raster thread behavior:

## Initial Diagnosis

- Is this likely VSync signal loss, app processing over-budget, or mixed?
- Strongest evidence:

## Next Action

- What parameter or strategy will be changed in next run?
- Expected impact:
