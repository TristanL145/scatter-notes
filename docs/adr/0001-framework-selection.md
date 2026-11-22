# ADR 0001: Cross-Platform Framework Selection (Flutter)

- **Status:** Accepted
- **Date:** 2026-11-22

## Context

Scatter Notes targets **Android mobile** first, with planned expansion to **iOS**, **Desktop** (Windows/macOS/Linux), and **Web**. Key requirements:
- Fast, smooth UI rendering (especially for interactive block editing, scrolling long notes, and quick capture).
- Single codebase efficiency for a solo developer / small team.
- Strong offline-first local database and native Android capability support (file system, camera/attachments, share intents).

## Options Considered

1. **Flutter (Dart)**
   - Compiles AOT to native ARM machine code on Android and iOS; Impeller/Skia rendering delivers consistent 60/120fps UI performance.
   - Single codebase covers Android, iOS, Windows, macOS, Linux, and Web with one UI layer (Material 3 + adaptive layouts).
   - Mature local-first ecosystem (`drift` for SQLite + FTS5, `riverpod`, `go_router`).
2. **Kotlin Multiplatform (KMP) + Compose Multiplatform**
   - Excellent native Android experience, but iOS/Desktop/Web tooling and third-party library parity require more platform-specific bridging.
3. **React Native (Expo / TypeScript)**
   - Large ecosystem, but JavaScript bridge/runtime overhead and native dependency upgrades across mobile + desktop are heavier than Flutter for a custom block editor.

## Decision

Choose **Flutter (Dart)** as the application framework for Scatter Notes.

## Consequences

- **Positive:** Fast native ARM execution on Android, single UI & business-logic codebase across mobile/desktop/web, strong deterministic widget & unit testing.
- **Negative / Trade-off:** Requires Dart/Flutter SDK toolchain setup; platform-specific Android features (e.g., share targets, home-screen quick-capture widgets) use lightweight MethodChannels or Flutter plugins.
