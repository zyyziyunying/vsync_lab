# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains the Flutter app code. Keep diagnosis screens under `lib/features/frame_diagnosis/`, legacy dashboard code under `lib/features/home/`, legacy jank scenes under `lib/features/stress/`, route wiring under `lib/routes/` and `lib/frame_diagnosis/`, and reusable UI in `lib/widgets/`. Tests live in `test/` and generally mirror the source area they cover, for example `test/metrics/frame_observability_log_test.dart`. Documentation and experiment templates live in `docs/`; capture helpers live in `scripts/`. Store local trace outputs in `artifacts/`, which is ignored by Git except for `.gitkeep`.

## Build, Test, and Development Commands
From the workspace root, run `flutter pub get`, then `cd vsync_lab`.

- `flutter run -d <android_device_id>`: launch the default diagnosis app on a device.
- `flutter run -t lib/main_legacy.dart -d <android_device_id>`: launch the legacy stress lab with frame-log tooling.
- `flutter analyze`: run static analysis using `flutter_lints`.
- `flutter test`: run widget and unit tests.
- `./scripts/collect_gfxinfo.ps1 -PackageName com.harrypet.vsync_lab`: collect `gfxinfo` output.
- `./scripts/collect_perfetto.ps1 -TraceSeconds 15`: record a Perfetto trace into `artifacts/`.

## Coding Style & Naming Conventions
Follow standard Flutter/Dart style: 2-space indentation, `UpperCamelCase` for classes/widgets, `lowerCamelCase` for fields and methods, and `snake_case.dart` for file names. Prefer small, focused widgets and keep reusable measurement code out of page files. Run `dart format .` before review if you touch Dart sources.

## Testing Guidelines
Use `flutter_test` for both widget and unit coverage. Name files `*_test.dart` and keep the test path aligned with the implementation path. Add unit tests for metric aggregation, parsing, and logging changes; add widget tests for navigation or panel behavior. No formal coverage gate is configured, but new behavior should include tests or a short rationale in the PR.

## Commit & Pull Request Guidelines
Git history follows Conventional Commit prefixes such as `feat:`, `fix:`, and `docs:`. Keep subjects short, imperative, and scoped to one change. Pull requests should explain the affected scenario, note the device/refresh-rate context when relevant, and list verification steps such as `flutter analyze` and `flutter test`. Include screenshots for UI changes and link supporting docs or logs when metrics, scripts, or experiment workflows change.

## Android & Experiment Notes
This repository targets Android only, with Android 10 as the baseline environment. Update `experiment_log_template.md` or related docs when you change observability fields or collection steps, and avoid committing raw `artifacts/` outputs unless the change specifically requires checked-in evidence.

## Documentation References
In prose, refer to repo files by filename only, such as `device_matrix.md` or `frame_metrics_panel.dart`. Do not use repo-relative paths like `docs/device_matrix.md` or `./device_matrix.md` unless the exact path is operationally required in a command, config snippet, import, or code block. If the same filename exists in multiple places, add a short natural-language qualifier instead of a path, for example the docs README (`README.md` under `docs`).
