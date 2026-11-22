# Scatter Notes — Flutter App Workspace

This directory is reserved for the **Flutter** mobile/cross-platform application.

> **Status:** Phase 0 (Repository & GitHub setup). This directory is intentionally kept clean (only this `README.md`) so `flutter create` can scaffold the native Android/iOS/Desktop/Web runners cleanly in Phase 1.

## Initializing the Flutter App (Phase 1)

Once the Flutter SDK and Android toolchain are installed, initialize the project from inside `app/`:

```bash
cd app
flutter create . --project-name scatter_notes --org com.tristanlaliberte.scatternotes --platforms=android,ios,windows,macos,linux,web
```

After running `flutter create`:
1. Add core dependencies (`flutter_riverpod`, `go_router`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `uuid`, etc.).
2. Uncomment the `pub` ecosystem entry in [`../.github/dependabot.yml`](../.github/dependabot.yml) so Dependabot tracks Flutter packages.
3. Verify locally before opening a PR:
   ```bash
   flutter pub get
   dart format --output=none --set-exit-if-changed .
   flutter analyze --fatal-infos
   flutter test
   ```
4. Once `flutter-ci` passes on `main`, add `flutter-ci` as a required status check in branch protection.

See [`../docs/architecture.md`](../docs/architecture.md) for the target `lib/` feature structure.
