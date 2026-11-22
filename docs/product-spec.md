# Scatter Notes — Product Specification

## 1. Vision & Goals

**Scatter Notes** is an offline-first, fast note-taking application built for **students** and **makers** managing both **school coursework** and **personal projects**.

Most note-taking apps fall into two extremes: blank text boxes that turn messy over time, or heavyweight databases that slow down quick capture. Scatter Notes bridges the gap with:
1. **Multi-dimensional organization** (Spaces, Classes/Projects, Topics, and Labels).
2. **Logical note-taking flows and non-intrusive nudges** that guide clearer thinking while writing.
3. **Structured block-based content** that keeps notes scannable, modular, and actionable.

### Target Platforms
- **Phase 1–3 (Primary):** Android mobile (phones & tablets).
- **Phase 4+ (Expansion):** iOS, Desktop (Windows, macOS, Linux), and Web from the same Flutter codebase.

---

## 2. Core Feature Areas

### 2.1 Organization System
Users should be able to file notes cleanly without friction and find anything in seconds:

- **Spaces**: Top-level contexts to keep school and personal life cleanly separated (default: `School`, `Personal Projects`, plus custom spaces).
- **Classes / Projects (Collections)**:
  - In *School*, collections represent courses (e.g., `CS 301 — Databases`, `MATH 210`). Optionally store metadata like semester, instructor, or schedule color.
  - In *Personal Projects*, collections represent projects (e.g., `Scatter Notes`, `Home Lab`, `Portfolio`).
- **Topics**: Ordered, structured subject folders/groups inside a Class or Project (e.g., *Week 3: B-Trees*, *Midterm Prep*, *Architecture*). A note belongs to zero or one Topic (with a smart Inbox for quick capture).
- **Labels**: Flexible cross-cutting tags (`#exam-prep`, `#todo`, `#idea`, `#bug`, `#formula`, `#reference`) that work across Spaces and Classes.
- **Pinning & Favorites**: Pin high-frequency notes (e.g., syllabus, sprint backlog) to the top of a Class/Project or Home view.
- **Combined Search & Filtering**: Instant offline full-text search paired with multi-facet filters (`Space`, `Class/Project`, `Topic`, `Label`, `Has open tasks`, `Flow type`).

### 2.2 Logical Flows & Contextual Nudges
The signature differentiator of Scatter Notes is helping users capture **better** notes, not just more text.

#### Guided Note-Taking Flows (Intentional Templates)
When creating a note, users can start with a **Quick Blank Note** or pick a **Logical Flow** that scaffolds structured sections and activates flow-aware nudges:

1. **Lecture / Cornell Flow** *(School)*
   - Sections: *Metadata (Class / Date / Topic)* -> *Cue Questions* -> *Lecture Notes* -> *Key Takeaways Summary*.
2. **Concept -> Example -> Self-Check Flow** *(STEM / Study)*
   - Sections: *Core Definition* -> *Intuition / Why It Matters* -> *Worked Example* -> *Self-Test Questions*.
3. **Project Spec -> Decisions -> Next Actions Flow** *(Personal Projects)*
   - Sections: *Goal / Problem* -> *Options & Trade-offs* -> *Decision Log* -> *Action Checklist*.
4. **Reading / Research Synthesis Flow** *(Papers, Videos, Docs)*
   - Sections: *Source & Context* -> *Main Claims* -> *Quotes / Evidence* -> *Open Questions & Connections*.

Users can also create and save custom flows.

#### Non-Intrusive Contextual Nudges
As the user writes or pauses, a lightweight, rule-based **Nudge Engine** offers subtle, dismissible chips/prompts (never blocking the keyboard):

- **Structure & Synthesis Nudges**:
  - *"Long note without headings — add section breaks or generate an outline?"*
  - *"Ready to wrap up? Add a 1–2 sentence Key Takeaway at the bottom."* (especially in Lecture/Reading flows).
- **Actionability Nudges**:
  - *"Detected action verbs ('TODO', 'need to', 'check') — convert into checklist items?"*
  - *"3 unanswered questions marked with `?` — review or group into a Questions block?"*
- **Organization Nudges**:
  - *"Note is still in Inbox — assign to a Class/Project or Topic?"*
  - *"Similar notes found in `CS 301` — add an internal `[[link]]`?"*
- **Study Nudges**:
  - *"No Self-Check questions yet — add 1–2 recall prompts for exam review?"*

#### User Control & Quiet Focus
- **Nudge Intensity Setting**:
  - `Quiet` — only shown on explicit review/close or via a subtle indicator dot.
  - `Balanced` (default) — gentle inline/footer chips at natural pauses (e.g., on idle or note exit).
  - `Active` — proactive flow prompts as you transition between sections.
- Every nudge supports one-tap **Apply**, **Snooze**, or **Dismiss** (with per-note and global cooldowns).

### 2.3 Rich Content & Organization Inside Notes
Notes are stored as structured blocks rather than flat strings, making content easy to rearrange and extend:

- **Block Types**:
  - Rich text paragraphs (bold, italic, inline code, highlight, links)
  - Headings (`H1`, `H2`, `H3`) — automatically populate a **Note Outline Drawer** for instant jumping
  - Interactive **Checklists / Tasks** (with progress counter)
  - **Callout Blocks** (*Definition*, *Formula*, *Important*, *Tip*, *Warning*)
  - **Code Blocks** with language tag & syntax highlighting
  - **Math / LaTeX Blocks** for equations
  - **Collapsible Toggle Blocks** (great for active recall Q&A or hiding dense details)
  - **Tables** (lightweight structured rows/columns)
  - **Media & Attachments** (images, camera capture of whiteboards/slides, sketches/handwriting)
  - **Internal Note Links** (`[[Note Title]]`) with backlinks panel
- **In-Note Manipulation**:
  - Slash command menu (`/`) for fast block insertion on mobile and keyboard
  - Quick mobile formatting & block-type toolbar above the keyboard
  - Drag-and-drop block reordering and section collapse/expand

---

## 3. Phased Roadmap

| Phase | Milestone | Scope |
| :--- | :--- | :--- |
| **Phase 0** | **Repo, Docs & Security Setup** | GitHub repo, branch protection, secret scanning, CI hygiene, architecture & product specs |
| **Phase 1** | **Flutter Scaffold & Core Data Layer** | `flutter create`, Riverpod + GoRouter setup, Drift SQLite schema + FTS5, repository tests |
| **Phase 2** | **Organization & Block Editor MVP** | Spaces, Classes/Projects, Topics, Labels, Inbox, core block editor, outline drawer, search |
| **Phase 3** | **Logical Flows & Nudge Engine** | Built-in flows, rule-based nudge engine, intensity settings, backlinks, active-recall toggles |
| **Phase 4** | **Android Polish & Multi-Platform** | Attachments/camera scan, Android release signing pipeline, adaptive tablet/desktop/iOS layouts |
