# Changelog

## Unreleased

- Remove repo-specific `adb` pull command generation from `FrameLogSaveResult`.
- Keep `FrameLogSaveResult` focused on exported file names and paths.

## 0.1.0

- Extract reusable frame timing monitor and frame-log exporter into `vsync_lab_toolkit`.
- Add package-owned tests for monitor, observability log, and file export result behavior.
- Add standalone package README for installation and validation.
- Add a minimal `example/` app showing monitor startup and manual frame-log save.
