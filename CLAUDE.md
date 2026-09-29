# 6 On Six

A Duolingo-style Flutter app that teaches volleyball fundamentals: court positions, roles, terminology, rotations, and the 5-1 system. McMaster PROCTECH 4TR3 capstone.

- Team: Issey Wu (lead developer: architecture and all app code) and Yash Dubey (content authoring, requirements, user testing, documentation).
- Hard deadline: Dec 1, 2026. Midterm demo: Oct 23, 2026.
- Read `docs/project-context.md` before any planning or scoping work. It holds the background, the timeline, and the open questions.
- Record every decision in `docs/decisions.md`.
- The PDFs in `docs/reference/` are history. They are not a spec: they mention Firebase, PostgreSQL, and a 10-module minimum, and all of that has been superseded.

## Current phase: fully offline app (Schedule 1)

- Do not add network code, backend SDKs, accounts, auth, sync, analytics, or network permissions.
- Online features (Schedule 2) only happen if the Oct 26 checkpoint passes. They are added as a retrofit, so the data rules below exist to keep that retrofit cheap.
- Distribution: there is no App Store or TestFlight in this phase.
  - Demo builds install from Xcode onto a physical iPhone using free provisioning.
  - Android builds install as a sideloaded APK.
- Collect no personal data. The local user is anonymous.

## Environments

- The project is developed on both macOS and Windows.
- All scripts and tooling must be cross-platform. Prefer Dart scripts, and add no bash-only tooling.
- iOS builds and device testing happen only on the Mac.
- Both machines and CI use the same pinned Flutter version, which is recorded in the Commands section below.
- Line endings are LF, enforced by `.gitattributes`.

## Stack

- Flutter targets iOS (primary) and Android. Android builds must keep working.
- State management and dependency injection use Riverpod. Navigation uses go_router. Local SQLite access uses drift.
- Content is bundled JSON in `assets/content/`. It is generated from the authoring spreadsheets by a validated Dart export script.
  - Never hand-edit the generated JSON.
- Add a new dependency only when it is needed. Say why you added it, and log it in `docs/decisions.md`.

## Architecture

Layers, with dependencies pointing inward only:
1. `presentation`: widgets and screens. No business logic.
2. `application`: Riverpod notifiers and controllers that coordinate use cases.
3. `domain`: pure Dart models and rules, such as scoring, unlocking, and streaks. No Flutter, drift, or IO imports.
4. `data`: repositories, the drift database, and the content loader. Implements interfaces defined in `domain`.

Rules:
- Features and UI never touch SQLite or asset files directly. They go through repository interfaces, which are injected with Riverpod providers.
  - This is what lets tests use fakes, and what lets Schedule 2 add a remote implementation later without touching the UI.
- Do not use global singletons or service locators other than Riverpod.
- Domain models are immutable and use value equality.
- Each kind of data has a single source of truth:
  - Bundled JSON is read-only content. Load it once and cache it in memory.
  - SQLite holds all user state.
- Do not create abstractions for features that don't exist yet.

## Data rules (these keep online sync a retrofit; do not break them)

- Every user-data record gets a client-generated UUID.
- An anonymous local user is created on first launch.
- Every mutable record has an `updated_at` timestamp.
- Every answer attempt goes into an append-only answer log. Entries are never updated or deleted.
- Derived state, such as lesson progress and streaks, is written in the same transaction as the log entry that caused it.
- Store timestamps in UTC. Convert to local time only for calendar logic, such as streak day boundaries.
  - Inject a `Clock` so tests can control time.
- Database changes happen only through versioned drift migrations. Never edit a migration after it has been merged.
- Content IDs are stable strings, such as `u1.l2.q05`, and are never regenerated.
- The content JSON has a top-level `schemaVersion`.

## Content model

- The hierarchy is unit → lesson → question. The scope lock is:
  - 4 units of 3 lessons each (12 lessons in total).
  - 80 questions.
  - 50 glossary terms.
  - Units 5 and 6 are conditional.
- Question types are frozen at four:
  - multiple choice
  - fill-in-the-blank
  - terminology matching
  - drag-and-drop court placement

  Ask before adding a type.
- Every question has one or more concept tags (slugs). Tags are independent of unit position, because review lessons are built from them.
- The court is one reusable `CustomPainter` component with three modes: display, quiz, and animate.
  - Content expresses positions as court zones 1 to 6 plus role tokens (S, OH1, OH2, MB1, MB2, OPP).
  - Content never contains pixel coordinates.
- Game-rule parameters (pass threshold, error cap, retry cooldown) live in one config object.
  - Lockouts are off by default until the team decides otherwise.
- Ask before changing the content schema, because Yash authors against it.

## Reliability

- Validate content in CI with the export script. The app must fail the build rather than ship bad content.
- At runtime, parse content defensively.
  - In debug builds, fail loudly on bad content.
  - In release builds, show an error state rather than crashing.
- Repositories return typed failures. Uncaught exceptions must never reach the UI.
- Log through the project's logger wrapper, never with `print`.
- Include a debug-only developer menu with these actions:
  - reset progress
  - unlock all units
  - jump to any lesson
  - seed sample progress

  The demo and user testing depend on this menu.

## Requirements

- 100% of learning content works offline. Verify this in airplane mode on a physical device.
- The installed size stays under 200 MB. Check the release build size before the release candidate.
- Every answer gets instant feedback. When the answer is wrong, show the correct one.
- The glossary is searchable and alphabetical.
- Audio and haptic feedback have independent settings toggles.
- The court and question UI must meet basic accessibility:
  - semantic labels on elements
  - support for text scaling
  - color is never the only signal of correct or incorrect
- The demo target is a complete loop in airplane mode:
  1. learning path
  2. lesson
  3. court drag-and-drop question
  4. feedback
  5. glossary lookup
  6. progress that persists across app restarts

## Testing

- New logic ships with tests:
  - Domain rules (scoring, unlocking, streaks, review selection) get unit tests.
  - Repositories are tested against an in-memory SQLite database.
  - Each question type gets a widget test.
- The demo loop gets one integration test.
- Before proposing any commit, run `dart format .`, `flutter analyze`, and `flutter test`. All three must be clean.

## Repo layout

```
lib/
  app/            # bootstrap, router, theme, config, logger
  core/           # shared domain models, repository interfaces, data implementations
  features/       # learning_path, lesson, glossary, progress, settings, dev_menu
assets/content/   # generated JSON (never hand-edited)
content/          # authoring source + Dart export/validation script
docs/             # project-context.md, decisions.md, reference/
```

## Commands

```
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
# Pinned Flutter version: record here during scaffolding
# Content export + validation: record here once the script exists
```

## Git workflow

- Branches:
  - `main` always builds and passes CI.
  - Work happens on short-lived branches such as `feat/court-renderer` or `fix/streak-reset`.
  - Merge through PRs.
- Commit messages use Conventional Commits prefixes: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`.
- Keep commits small and focused.
- Versioning:
  - The semantic version lives in `pubspec.yaml`.
  - Tag milestones: `v0.1.0` for the midterm, `v1.0.0` for the final.
  - Record notable changes in `CHANGELOG.md`.
- Never commit secrets, build output, or `CLAUDE.local.md`.

## Working with Issey

- Explain choices in plain language.
- Push back when a request conflicts with the rules above or with the timeline. Do not just comply.
- Prefer boring, well-maintained solutions. This is roughly a ten-week build by one developer.
