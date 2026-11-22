# GitHub Security & Development Configuration

This document records all security and developer-workflow settings configured on the `scatter-notes` GitHub repository, why each setting is enabled, and how to update them as the project grows.

Automated setup script: [`scripts/configure-github-repo.ps1`](../scripts/configure-github-repo.ps1)

---

## 1. Repository & Merge Settings

| Setting | Value | Rationale |
| :--- | :--- | :--- |
| **Visibility** | Public | Open-source repository; unlocks GitHub's free branch protection and security scanning features |
| **Squash Merging** | Enabled (`allow_squash_merge: true`) | Keeps `main` history clean and linear (one meaningful commit per PR) |
| **Merge Commits / Rebase Merge** | Disabled | Prevents noisy merge commits and inconsistent commit styles |
| **Auto-delete Head Branches** | Enabled (`delete_branch_on_merge: true`) | Automatically cleans up merged feature branches |
| **Allow Update Branch** | Enabled (`allow_update_branch: true`) | Lets contributors update PR branches directly from the GitHub UI |
| **Issues & Projects** | Enabled | Track bugs, feature requests, and milestone boards |
| **Wiki** | Disabled | Documentation lives versioned in `docs/` alongside code |

---

## 2. Branch Protection (`main`)

| Rule | Setting | Rationale |
| :--- | :--- | :--- |
| **Require Pull Request before merging** | Enabled | Prevents accidental direct pushes to `main` |
| **Required approving reviews** | `0` *(solo-dev baseline)* | GitHub forbids approving your own PR; raise to `1`+ when collaborators join |
| **Dismiss stale reviews on new commits** | Enabled | Ensures new commits are re-reviewed once reviewers are active |
| **Require status checks to pass** | `repo-hygiene / check`, `flutter-format / check`, `flutter-analyze / check`, `flutter-test / check` (`strict: true`) | Guarantees PRs are up to date with `main` and pass hygiene, formatting, static analysis, and tests before merge |
| **Require conversation resolution** | Enabled | Ensures all PR review comments are addressed before merging |
| **Enforce admins** | `false` *(solo-dev baseline)* | Allows repository owner emergency bypass when working solo; enable (`true`) for teams |
| **Allow force pushes / deletions** | Disabled | Protects `main` commit history from accidental rewriting or deletion |

---

## 3. Security & Supply-Chain Protections

| Feature | Status | Purpose |
| :--- | :--- | :--- |
| **Secret Scanning** | Enabled | Scans commits for leaked tokens, API keys, and credentials |
| **Secret Scanning Push Protection** | Enabled | Blocks `git push` before known secret patterns ever reach GitHub |
| **Dependabot Vulnerability Alerts** | Enabled | Alerts maintainers when dependencies have known CVEs |
| **Dependabot Security Updates** | Enabled | Automatically opens PRs to patch vulnerable dependencies |
| **Dependabot Version Updates** | Configured (`.github/dependabot.yml`) | Weekly PRs for `github-actions` (and `pub` once `app/pubspec.yaml` exists) |
| **Private Vulnerability Reporting** | Enabled | Allows external reporters to submit security reports privately via Advisories |

---

## 4. GitHub Actions Hardening

- **Workflow `GITHUB_TOKEN` default permissions**: Set to **read-only** (`default_workflow_permissions: "read"`). Workflows needing write access must request minimal scopes explicitly per job.
- **Prevent Actions from approving PRs**: `can_approve_pull_request_reviews: false`.
- **Least-privilege CI/CD orchestrators**:
  - `.github/workflows/ci.yml` orchestrates modular `ci-*.yml` reusable task workflows (`ci-repo-hygiene.yml`, `ci-flutter-format.yml`, `ci-flutter-analyze.yml`, `ci-flutter-test.yml`, `ci-flutter-build-android.yml`) with top-level `permissions: contents: read` and PR `concurrency` cancellation.
  - `.github/workflows/cd.yml` orchestrates modular `cd-*.yml` reusable task workflows (`cd-android-build.yml`, `cd-github-release.yml`) with top-level `permissions: contents: read`, elevating `contents: write` strictly on the `github-release` job.
  - Shared Flutter toolchain setup lives in `.github/actions/setup-flutter/action.yml`.

---

## 5. Future Checklist (As Project Grows)

1. **After Phase 1 PR merges to `main`**:
   - Re-run `.\scripts\configure-github-repo.ps1 -Repo scatter-notes` so `main` branch protection enforces all 4 modular CI checks (`repo-hygiene / check`, `flutter-format / check`, `flutter-analyze / check`, `flutter-test / check`).
2. **When releasing Android builds to Play Store / APK distribution**:
   - Create a protected GitHub Environment (`android-release`) with **Required Reviewers** and **Deployment Branches (`main` or `v*` tags only)** — already referenced by `cd-android-build.yml`.
   - Store `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD` exclusively in that Environment's encrypted secrets—never in the repository.
3. **When adding collaborators**:
   - Update `required_approving_review_count` to `1` (or `2`), enable `require_code_owner_reviews: true`, and set `enforce_admins: true`.
