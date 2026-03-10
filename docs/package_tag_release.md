# Package Tag Release Guide

This repository currently exposes one reusable package:

- `packages/vsync_lab_toolkit`

The recommended external dependency strategy is:

- local development: `path`
- external consumption: `git` + `tag_pattern` + `version`
- not recommended: branch-based `ref`

## Tag Policy

Use package-scoped annotated tags so repo-wide tags stay unambiguous.

Tag format:

- `vsync_lab_toolkit-v0.1.0`
- `vsync_lab_toolkit-v0.1.1`
- `vsync_lab_toolkit-v0.2.0`

Rules:

- tag version must match `packages/vsync_lab_toolkit/pubspec.yaml`
- tag version must have a matching section in `packages/vsync_lab_toolkit/CHANGELOG.md`
- create annotated tags, not lightweight tags
- do not recommend moving branch refs such as `main` to external consumers

## Consumer Dependency Format

External apps should depend on the package like this:

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

Notes:

- `tag_pattern` requires Dart `>=3.9.0` in the consuming app
- if the remote points at a workspace repo root that contains `vsync_lab/`, then the dependency `path` becomes `vsync_lab/packages/vsync_lab_toolkit`

## Next Release Workflow

When releasing the next version, for example `0.1.1` or `0.2.0`:

1. Update `packages/vsync_lab_toolkit/pubspec.yaml`.
2. Move release-ready items from `Unreleased` into a new changelog heading.
3. Update README / example if the public API or setup flow changed.
4. Run package verification.
5. Commit the release-ready state.
6. Create the annotated package-scoped tag.
7. Push branch and tag.

## What Not To Do

- Do not document `ref: main` as the recommended external install path.
- Do not create unscoped tags like `v0.1.0`; they do not scale once the repo contains multiple reusable packages.
- Do not publish a tag whose version does not match both `pubspec.yaml` and `CHANGELOG.md`.
