# GitHub Actions Workflows

Scatter Notes uses **modular orchestrator workflows** (`ci.yml` and `cd.yml`) that compose single-purpose **reusable task workflows** (`on: workflow_call`) and a shared composite action (`.github/actions/setup-flutter`).

> **Why files sit flat in `.github/workflows/`:** GitHub Actions only discovers workflow YAML files directly inside `.github/workflows/` (subdirectories are ignored). Prefixing tasks with `ci-*` and `cd-*` keeps CI and CD cleanly separated while letting `ci.yml` and `cd.yml` act as main entrypoints.

---

## Continuous Integration (`ci.yml`)

Triggered on pushes to `main`, pull requests targeting `main`, and `workflow_dispatch`:

| Orchestrator Job | Reusable Task File | Purpose |
| :--- | :--- | :--- |
| `repo-hygiene` | [`ci-repo-hygiene.yml`](ci-repo-hygiene.yml) | Verifies required docs exist and blocks tracked secrets/signing files |
| `flutter-format` | [`ci-flutter-format.yml`](ci-flutter-format.yml) | Enforces `dart format --output=none --set-exit-if-changed .` |
| `flutter-analyze` | [`ci-flutter-analyze.yml`](ci-flutter-analyze.yml) | Enforces `flutter analyze --fatal-infos` |
| `flutter-test` | [`ci-flutter-test.yml`](ci-flutter-test.yml) | Runs unit and widget tests (`flutter test`) |
| `flutter-build-android` | [`ci-flutter-build-android.yml`](ci-flutter-build-android.yml) | Builds a debug Android APK after format/analyze/test pass |

---

## Continuous Delivery (`cd.yml`)

Triggered on semantic version tags (`v*.*.*`) or manually via `workflow_dispatch`:

| Orchestrator Job | Reusable Task File | Purpose |
| :--- | :--- | :--- |
| `verify` | [`ci-flutter-test.yml`](ci-flutter-test.yml) | Runs `flutter test` before building release artifacts |
| `android-build` | [`cd-android-build.yml`](cd-android-build.yml) | Builds release APK & AAB using `android-release` environment secrets (if set) and uploads artifacts |
| `github-release` | [`cd-github-release.yml`](cd-github-release.yml) | Creates a draft GitHub Release with attached APK/AAB artifacts |

---

## Shared Composite Actions

- [`../actions/setup-flutter/action.yml`](../actions/setup-flutter/action.yml) — Sets up Flutter (stable, cached) and runs `flutter pub get`.
