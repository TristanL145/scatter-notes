# Scatter Notes

An offline-first, fast note-taking mobile app designed for **school** and **personal projects**. Scatter Notes combines structured multi-level organization with **logical note-taking flows**, **contextual nudges**, and **rich block-based content** to help you capture clearer, more actionable notes.

> **Platform Roadmap:** Android mobile first, built with **Flutter (Dart)** for fast native performance and future expansion to iOS, Desktop (Windows/macOS/Linux), and Web.

---

## Core Pillars

### 1. Multi-Dimensional Organization
- **Spaces**: Separate contexts cleanly (e.g., *School*, *Personal Projects*).
- **Classes & Projects**: Group notes by course (`CS 301`, `MATH 210`) or personal initiative.
- **Topics**: Structured sub-areas inside each class or project (e.g., *Midterm Review*, *Database Indexing*, *API Design*).
- **Labels**: Cross-cutting tags (`#exam-prep`, `#todo`, `#idea`, `#reference`) that work across all spaces.
- **Fast Search & Filtering**: Offline full-text search (SQLite FTS5) combined with Space / Class / Topic / Label filters and pinned notes.

### 2. Logical Flows & Contextual Nudges
- **Guided Flows**: Start notes with intentional structures tailored to how you think:
  - *Lecture / Cornell Flow* (Cues, Main Notes, Summary)
  - *Concept -> Example -> Self-Check Flow* (great for STEM & study)
  - *Project Spec -> Decisions -> Next Actions Flow*
  - *Reading / Research Synthesis Flow*
- **Smart, Non-Intrusive Nudges**: Gentle contextual prompts while writing—such as reminding you to write a 1–2 sentence takeaway on long notes, highlighting unanswered questions, converting action bullets into checkable tasks, assigning a Topic/Label to uncategorized notes, or linking related notes.
- **Configurable Intensity**: Switch between *Quiet*, *Balanced*, and *Active* nudge modes so prompts help without interrupting focus.

### 3. Structured Content Inside Notes
- **Block-Based Editor**: Headings (auto-building a navigable note outline), rich text, checklists, callouts (*Definition*, *Formula*, *Warning*, *Key Takeaway*), code blocks, math/LaTeX equations, collapsible toggle sections, tables, images/diagrams, and `[[internal note links]]`.
- **Fast Authoring**: Quick slash-command insertion (`/`), drag-and-drop block reordering, and an outline drawer for long notes.

---

## Tech Stack (Planned)

| Layer | Choice | Rationale |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart) | Native ARM AOT speed on Android, single codebase for iOS/Desktop/Web |
| **State Management** | Riverpod | Compile-safe reactive state and clean dependency injection |
| **Local Storage** | SQLite via Drift + FTS5 | Fast offline-first storage, relational organization, and instant full-text search |
| **Navigation** | GoRouter | Declarative routing and deep-link support |
| **UI System** | Material 3 | Native-feeling Android experience with adaptive layout support |

---

## Repository Structure

```text
scatter-notes/
├── .github/
│   ├── ISSUE_TEMPLATE/        # Structured bug report & feature request forms
│   ├── workflows/             # GitHub Actions CI & repo hygiene workflows
│   ├── CODEOWNERS             # Default code ownership
│   ├── dependabot.yml         # Automated dependency & action updates
│   └── pull_request_template.md
├── app/                       # Flutter application workspace (scaffolded in Phase 1)
├── docs/
│   ├── adr/                   # Architecture Decision Records
│   ├── architecture.md        # App architecture, data model & module boundaries
│   ├── github-security-and-settings.md
│   └── product-spec.md        # Detailed product specification & roadmap
├── scripts/
│   └── configure-github-repo.ps1  # Automated GitHub repo & security settings script
├── .editorconfig
├── .gitignore
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
└── SECURITY.md
```

---

## Documentation

- [Product Specification & Roadmap](docs/product-spec.md)
- [Technical Architecture](docs/architecture.md)
- [GitHub Security & Repository Settings](docs/github-security-and-settings.md)
- [ADR 0001: Framework Selection (Flutter)](docs/adr/0001-framework-selection.md)
- [ADR 0002: Local-First Storage (Drift / SQLite)](docs/adr/0002-local-first-storage.md)
- [App Workspace Guide](app/README.md)

---

## Getting Started

### Prerequisites (for upcoming Phase 1 app development)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio + Android SDK (for Android mobile builds & emulator)
- Git & [GitHub CLI (`gh`)](https://cli.github.com/)

### Contributing & Security
- Read [CONTRIBUTING.md](CONTRIBUTING.md) for branching, commit conventions, and PR checks.
- Read [SECURITY.md](SECURITY.md) for secret hygiene and how to report vulnerabilities privately.
