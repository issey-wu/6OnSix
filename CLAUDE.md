# 6 On Six

6 On Six is a Duolingo-style Flutter app that teaches volleyball fundamentals: the court, positions, rules and terminology, rotations, and the 5-1 system. It is a McMaster PROCTECH 4TR3 capstone.

## Team and key dates

- Issey Wu is the lead developer. He owns architecture and app code, and has the final say on design and content.
- Yash Dubey owns content authoring, the design spec, user testing, and documentation.
- The midterm demo is on Oct 23, 2026. The project is complete on Dec 1, 2026.

## Docs to read

- `docs/project-context.md` gives the background. Read it before any planning work.
- `docs/design.md` is the UI and game-rule spec. Follow it for all screens, flows, question behaviour, XP, streaks, colours, and typography. Where it conflicts with this file, this file wins.
- `docs/decisions.md` is a short list of the current technical choices.
- `docs/reference/` holds the FIVB Official Volleyball Rules 2025-2028, which are the source of truth for rules content. It also holds the 4TR1 report and the 4TR3 plan; those are history, not a spec.

## Current phase: fully offline app (Schedule 1)

- No network code, backend SDKs, accounts, auth, sync, analytics, notifications, or network permissions.
- Demo builds install from Xcode onto a physical iPhone (free provisioning) and as a sideloaded APK on Android. There is no App Store or TestFlight in this phase.
- No user data leaves the device. The local user is anonymous; the optional display name is stored on the device only.

## Environments

- The project is developed on both macOS and Windows.
- All scripts and tooling must be cross-platform. Prefer Dart scripts and avoid bash-only tooling.
- iOS builds and device testing happen only on the Mac. Xcode 27 uses Device Hub instead of Simulator.app.
- Both machines and CI use the same pinned Flutter version, shown under Commands.
- Line endings are LF, enforced by `.gitattributes`.

## Stack

- Flutter targets iOS (primary) and Android. Android builds must keep working.
- **State and dependency injection:** Riverpod.
- **Navigation:** go_router.
- **Local SQLite:** drift.
- **Lints:** very_good_analysis.
- **Content:** bundled JSON in `assets/content/`, generated from the authoring spreadsheet by a validated Dart export script. Never hand-edit the generated JSON.
- **Fonts:** Unbounded and Work Sans, bundled as assets.
- Only add dependencies when they are needed, and say why when you add one.

## Architecture

There are four layers, and dependencies point inward only:
1. `presentation`: widgets and screens. No business logic.
2. `application`: Riverpod notifiers and controllers.
3. `domain`: pure Dart models and rules (lesson queue, XP, unlocking, streaks, review selection). No Flutter, drift, or IO imports.
4. `data`: repositories, the drift database, and the content loader. These implement interfaces defined in `domain`.

Rules:
- Features never touch SQLite or asset files directly. They go through repository interfaces, provided by Riverpod.
- No global singletons or service locators other than Riverpod.
- Domain models are immutable and have value equality.
- Bundled JSON is read-only content, loaded once and cached. SQLite holds all user state.
- Don't create abstractions for features that don't exist yet.

## Data rules

These keep a future online sync cheap to add.
- Every user-data record gets a client-generated UUID, and every mutable record gets an `updated_at`.
- An anonymous local user is created on first launch.
- Every answer attempt goes into an append-only answer log.
- Derived state (lesson progress, XP, streak) is written in the same transaction as the event that caused it.
- Timestamps are stored in UTC. Local time is used only for calendar logic, such as the device-local date for streaks. Always go through the injected `Clock`.
- Schema changes happen only through versioned drift migrations. Never edit a migration after it is merged.
- Content IDs are stable strings, such as `u1.l2.q05`. The content JSON has a top-level `schemaVersion`.

## Game rules (details in docs/design.md)

- **Linear path:** each unit is Lesson 1 → Lesson 2 → Lesson 3 → Unit review. Completed nodes can be replayed.
- **Complete until correct:**
  - A wrong answer shows the correct answer and its explanation, then moves the question to the end of the queue.
  - Nobody can fail a lesson.
  - The progress bar never moves backward.
  - Quitting mid-lesson awards no progress or XP.
- **Matching:** a wrong pairing only removes the perfect bonus. The question is not re-queued.
- **XP and streak values:** they live in one config object in `domain`. There are no lockouts, hearts, or error caps.
- **No hard-coded counts:** the app must not assume unit, lesson, or question counts. It shows whatever the content contains.

## Content model

- The hierarchy is unit → lesson → question. Each lesson opens with 1 to 2 teaching cards, which can be skipped on replays.
- There are five question types: multiple choice, true/false, matching, tap the zone, and drag-and-drop. Ask before adding a type.
- Every question has a prompt, the answer data, a one-sentence explanation, and one or more concept tags. Unit reviews are built from the concept tags.
- Rules-based questions cite their FIVB rule (`ruleRef`). Where common league rules differ, the question carries a `leagueNote`, shown in feedback.
- Rotation and overlap questions state `phase` (serving or receiving). Under FIVB 7.4, only the receiving team must be in rotational order at the serve, so frame overlap questions from the receiving side by default.
- The content focuses on rules and legality. Physical technique is out of scope.
- Ask before changing the content schema, because Yash authors against it.

## Court

- There is one reusable `CustomPainter` court component, with display, quiz, and animate modes.
- The net is at the top. Zones follow FIVB numbering: 4-3-2 across the front row and 5-6-1 across the back row.
- Tokens are S, OH1, OH2, MB1, MB2, OPP, and L. Each drag-and-drop question defines its own token set.
  - When L is in play, it replaces the back-row MB.
  - L may only occupy zones 5, 6, or 1.
- Court questions are graded on exact placement only.
- Display and animate modes may use normalized court coordinates (0 to 1) to draw real formations. Content never contains pixel positions.

## Design principles

- One control per action. For example, never show a Back button and an X button that do the same thing.
- No tutorials or pop-over hints. The welcome screen leads straight into Lesson 1.1, and every interaction must be self-explanatory.
- All colours come from the theme tokens in `docs/design.md`. Never hard-code colours.
- Light (Rally) and dark (Night) themes. The app follows the system setting by default.

## Reliability and accessibility

- Content is validated in CI by the export script. Bad content fails the build.
- At runtime, content is parsed defensively. In debug builds, fail loudly on bad content. In release builds, show an error state instead.
- Repositories return typed failures. Uncaught exceptions never reach the UI.
- Log through the project's logger wrapper, never `print`.
- There is a debug-only developer menu with these actions:
  - reset progress
  - unlock all units
  - jump to any lesson
  - simulate days, for testing streaks
- Accessibility requirements:
  - Never use colour alone to convey meaning.
  - Support text scaling.
  - Every node and every court zone has a screen-reader label.
  - Tap targets are at least 48 × 48 px.
- 100% of learning content works offline. Verify this in airplane mode on a physical device.

## Testing

- New logic ships with tests:
  - unit tests for domain rules
  - repository tests against an in-memory SQLite database
  - a widget test for each question type
- One integration test covers the demo loop.
- Before proposing a commit, `dart format .`, `flutter analyze`, and `flutter test` must all be clean.

## Repo layout

```
lib/
  app/            # bootstrap, router, theme, providers, logger
  core/           # shared domain models, repository interfaces, data implementations
  features/       # learning_path, lesson, glossary, profile, settings, dev_menu
assets/content/   # generated JSON (never hand-edited)
assets/fonts/     # Unbounded, Work Sans
content/          # authoring source + Dart export/validation script
docs/             # project-context.md, design.md, decisions.md, reference/
```

## Commands

```
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
open -b com.apple.dt.Devices   # open Device Hub (macOS, Xcode 27)
# Pinned Flutter version: 3.47.6 (Dart 3.13.5)
# Content export + validation: record here once the script exists
```

## Git workflow

- `main` always builds and passes CI. Work happens on short-lived branches (`feat/...`, `fix/...`, `chore/...`) and merges through PRs.
- Use Conventional Commits prefixes: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`.
- Commit messages and PR descriptions can be as detailed as needed. Never include AI or tool authorship lines (no `Co-Authored-By: Claude`, "Generated with Claude Code", or session links). The same applies to code comments and docs.
- Issey makes the commits. Edit files and stop; don't commit or push unless asked.
- The semantic version lives in `pubspec.yaml`. Tag milestones: `v0.1.0` at the midterm, `v1.0.0` at the final.
- `CHANGELOG.md` holds brief, high-level milestone notes.
- `docs/decisions.md` gets a one- or two-line note only when the stack, architecture, or content schema changes. No dates and no progress or status commentary there.
- Never commit secrets, build output, or `CLAUDE.local.md`.

## Working with Issey

- Explain choices in plain language.
- Push back when a request conflicts with the rules above.
- Prefer boring, well-maintained solutions.
