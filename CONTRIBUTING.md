# Contributing to Scatter Notes

Thank you for contributing to **Scatter Notes**! This repository follows a clean PR-based workflow to keep `main` reliable and secure.

## Branching & Pull Request Workflow

Direct pushes to `main` are restricted. All changes should go through a pull request:

1. Create a descriptive branch from `main`:
   - `feat/<short-name>` — new features (e.g., `feat/cornell-flow`)
   - `fix/<short-name>` — bug fixes (e.g., `fix/label-filter-crash`)
   - `docs/<short-name>` — documentation updates
   - `chore/<short-name>` — CI, dependencies, tooling, refactors
2. Commit changes using [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat: add topic filtering in note list`
   - `fix: preserve block order when toggling checklist`
   - `docs: update local storage ADR`
   - `chore: configure dependabot for pub`
3. Open a pull request against `main` using the PR template.
4. Ensure all required CI checks (`repo-hygiene`, and `flutter-ci` once `app/` is initialized) pass and all review conversations are resolved.
5. PRs are **squash-merged** into `main`, and head branches are automatically deleted.

## Local Verification (Flutter App)

Once the Flutter project is initialized inside `app/`, run the following checks before opening or updating a PR:

```bash
cd app
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Security & Privacy Rules for Contributors

- **Never commit secrets**: API keys, `.env` files, Android keystores (`*.jks`, `*.keystore`), `key.properties`, or `google-services.json`.
- **Keep it local-first**: Scatter Notes must work offline by default. Do not introduce hidden analytics, tracking SDKs, or unapproved network calls.
- **Minimal permissions**: Android permissions should only be requested when directly required by a user-facing feature (e.g., camera/storage for attaching an image).
