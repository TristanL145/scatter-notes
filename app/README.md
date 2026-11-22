# Scatter Notes — Flutter App

Offline-first Flutter application for **Scatter Notes**, targeting Android mobile first and supporting iOS, Desktop (Windows/macOS/Linux), and Web.

> **Status:** Phase 1 — Flutter app scaffold, local-first Drift (SQLite + FTS5) data layer, Riverpod state management, GoRouter navigation shell, and unit/widget tests.

## Core Packages

- **State Management:** `flutter_riverpod`
- **Navigation:** `go_router`
- **Local Database & Search:** `drift`, `drift_flutter`, `sqlite3` (FTS5 full-text search)
- **IDs & Codegen:** `uuid`, `drift_dev`, `build_runner`

## Development Commands

Run all commands from inside `app/`:

```bash
# Install dependencies
flutter pub get

# Generate Drift database code (*.g.dart)
dart run build_runner build --delete-conflicting-outputs

# Format code
dart format .
dart format --output=none --set-exit-if-changed .

# Static analysis (enforced in CI)
flutter analyze --fatal-infos

# Run unit & widget tests
flutter test
```

See [`../docs/architecture.md`](../docs/architecture.md) for the feature-first directory layout under `lib/` and [`../docs/product-spec.md`](../docs/product-spec.md) for the phased roadmap.
