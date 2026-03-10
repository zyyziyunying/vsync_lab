# Changelog

## Unreleased

- Add `FrameMetricsRecorder` as a stable plain-sample entry point.
- Add `FrameSample` to the stable public API for source-agnostic integrations.
- Refactor `FrameTimingMonitor` into a thinner Flutter integration layer on top of the recorder.
- Remove repo-specific `adb` pull command generation from `FrameLogSaveResult`.
- Keep `FrameLogSaveResult` focused on exported file names and paths.
- Narrow the barrel export to stable host-app APIs only.
- Keep aggregator and observability builder types under `lib/src/`.
- Move `FrameTiming` adaptation into a thinner Flutter glue layer.
- Keep core aggregation and logging centered on `addSample(...)` input.

## 0.1.0

- Extract reusable frame timing monitor and frame-log exporter into `vsync_lab_toolkit`.
- Add package-owned tests for monitor, observability log, and file export result behavior.
- Add standalone package README for installation and validation.
- Add a minimal `example/` app showing monitor startup and manual frame-log save.
