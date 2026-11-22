# Scatter Notes — Technical Architecture

## 1. Architectural Principles

1. **Offline-First & Instant Startup**: Every read and write hits local SQLite on-device with zero network dependency.
2. **Feature-First Modular Structure**: Code inside `app/lib/` is organized by domain feature so UI, state, and storage boundaries stay decoupled and testable.
3. **Structured Content Over Raw Blobs**: Note content is modeled as ordered, typed blocks serialized cleanly, enabling outline extraction, task aggregation, and rule-based nudges without fragile regex parsing over raw HTML.
4. **Cross-Platform Ready, Android-First**: Business logic and storage layers use pure Dart / multi-platform Flutter packages, with platform-specific integrations isolated behind clean interfaces.

---

## 2. Planned Flutter Directory Layout (`app/lib/`)

```text
app/lib/
├── main.dart
├── app.dart                         # Root MaterialApp.router, theme, providers
├── core/
│   ├── constants/                   # App-wide constants & defaults
│   ├── database/                    # Drift database definition, migrations, FTS5 tables
│   ├── router/                      # GoRouter configuration & route definitions
│   ├── theme/                       # Material 3 light/dark themes, typography, color tokens
│   └── utils/                       # UUIDs, date formatters, debouncers
└── features/
    ├── organization/                # Spaces, Classes/Projects, Topics, Labels, Inbox
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── notes/                       # Note list, pinning, metadata, backlinks
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── editor/                      # Block-based editor, slash commands, outline drawer
    │   ├── domain/                  # Block models (Paragraph, Heading, Checklist, Callout, etc.)
    │   └── presentation/
    ├── flows/                       # Guided Flows & contextual Nudge Engine
    │   ├── domain/                  # Flow definitions, pure-Dart nudge rules & cooldowns
    │   └── presentation/            # Flow picker, non-intrusive nudge banner/chips
    ├── search/                      # FTS5 full-text search + multi-facet filter UI
    └── settings/                    # Nudge intensity, theme, backup/export preferences
```

---

## 3. Core Technology Choices

- **UI Framework**: Flutter (Material 3) with responsive breakpoints (`< 600dp` phone, `600–840dp` foldable/tablet, `> 840dp` desktop/web rail).
- **State Management**: `flutter_riverpod` (`AsyncNotifier` / `Notifier` providers) for reactive DB streams, testability via `ProviderContainer` overrides, and clean separation from widgets.
- **Local Persistence**: `drift` (type-safe SQLite wrapper) with **FTS5** virtual tables for sub-50ms offline search across titles, blocks, topics, and labels.
- **Routing**: `go_router` for declarative deep-linkable routes (`/spaces/:spaceId`, `/collections/:collectionId`, `/notes/:noteId`).

---

## 4. Relational Data Model (Draft)

```text
spaces (id, name, icon, sort_order, created_at, updated_at, deleted_at)
  └── collections [classes/projects] (id, space_id, name, kind, color_hex, sort_order, archived, ...)
        └── topics (id, collection_id, name, sort_order, ...)
              └── notes (id, space_id, collection_id, topic_id, title, flow_id, is_pinned, created_at, updated_at, deleted_at)
                    ├── note_blocks (id, note_id, type, position, content_json, updated_at)
                    ├── note_labels (note_id, label_id) -> labels (id, name, color_hex)
                    └── note_links (source_note_id, target_note_id)
```

### Design Notes
- **UUIDv4 / ULID primary keys** and `updated_at` / `deleted_at` (soft-delete) columns keep the schema ready for future multi-device sync without breaking local-first operation.
- **`note_blocks` + JSON payload**: Each block row stores a `type` (`heading`, `paragraph`, `checklist`, `callout`, `code`, `math`, `toggle`, `table`, `image`), an integer/fractional `position` for cheap reordering, and type-specific attributes in `content_json`.
- **FTS5 index**: A dedicated FTS5 table mirrors note titles, extracted plain text from blocks, and label names via triggers or transactional repository updates.

---

## 5. Logical Flows & Nudge Engine Architecture

The **Nudge Engine** runs in pure Dart inside `features/flows/domain/` with zero UI coupling:

1. **Inputs**: Current `NoteSnapshot` (title, collection/topic/labels, list of `NoteBlock`s, active `FlowType`, time spent editing, user `NudgeIntensity`).
2. **Evaluators (Pure Rules)**: Independent rule classes (`MissingTakeawayRule`, `UncategorizedInboxRule`, `ActionVerbToChecklistRule`, `LongUnstructuredNoteRule`, `UnansweredQuestionsRule`, `RelatedNotesRule`).
3. **Cooldown & Dismissal Store**: Tracks dismissed/snoozed rules per note so the user is never nagged repeatedly by the same suggestion.
4. **Outputs**: Prioritized list of `NudgeSuggestion` objects containing a concise message, severity, and a structured `NudgeAction` (e.g., append a Summary callout block, convert paragraph lines to checklist blocks, open Topic picker).
5. **Testing**: Every nudge rule can be unit-tested deterministically in milliseconds without launching Flutter widget trees.
