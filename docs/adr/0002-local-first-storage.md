# ADR 0002: Local-First Storage Strategy (SQLite via Drift)

- **Status:** Accepted
- **Date:** 2026-11-22

## Context

A student and project note-taking app must open instantly, work reliably in lecture halls or transit with zero internet, and support rich relational queries:
- Filter notes by `Space -> Collection (Class/Project) -> Topic` and cross-cutting `Labels`.
- Query open checklist items across notes.
- Perform instant full-text search across hundreds or thousands of notes.

## Options Considered

1. **SQLite via Drift (with FTS5)**
   - Relational integrity (foreign keys across Spaces, Collections, Topics, Labels, NoteLinks).
   - Built-in SQLite **FTS5** full-text search.
   - Reactive Dart streams (`watch()`) that update Riverpod providers automatically on write.
   - Cross-platform support (Android, iOS, Desktop, and Web via WASM).
2. **Plain Markdown Files on Disk**
   - Simple portability, but slow/fragile for cross-cutting queries (labels, backlinks, checklists, topic sorting) without building a custom index anyway.
3. **Cloud-First NoSQL (e.g., Firestore)**
   - Introduces account/network dependency on day one and complicates full-text search offline.

## Decision

Use **SQLite via Drift** with **FTS5** as the primary local-first persistence layer, paired with Markdown/JSON export capabilities so users always own their data.

## Consequences

- **Positive:** Fast relational + full-text queries offline, compile-time checked SQL in Dart, easy schema migrations, and future sync readiness via UUIDs and timestamps.
- **Negative / Trade-off:** Requires `build_runner` code generation during development when changing Drift tables.
