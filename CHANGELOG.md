# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/). Milestone tags: `v0.1.0` (midterm),
`v1.0.0` (final).

## [Unreleased]

### Added
- Saved progress on the device with drift: completions, answer log, XP,
  streak, name and settings survive a restart.
- First-launch welcome screen that opens Lesson 1.1 directly.
- Bottom navigation with Learn, Glossary and Profile tabs; lessons open
  full screen with the bar hidden.
- Learning path: greeting, lesson pop-up card (Start or Practice again),
  scroll to the current lesson, gentle pulse on the current node.
- Drag-and-drop court questions (drag or tap to place), with 8 new questions.
- Glossary: 106 draft terms, search by name or definition, A to Z groups,
  term pages with examples and related terms.
- Profile (name, streak, XP, lessons and units completed, unit progress) and
  Settings (theme, sound, haptics, reset progress, about).
- Sound effects and haptics for key moments, with separate toggles.
- Light and dark themes follow the Appearance setting.
- Shared UI components in `lib/core/ui/`.
- `tool/check.dart` to run all checks in one command.

### Added from Yash Dubey's `yash/screens` branch
- Developer menu in Settings (debug builds only): simulate the next day to
  test streaks, reset the clock, and jump to any lesson.
- Drag-and-drop improvements: dropping on a taken zone swaps the players,
  tapping a player on court with another picked swaps them, picking a placed
  player and tapping the tray takes it off, and the tray order is shuffled.
- Player token design (orange tokens, contrasting libero, lifted shadow while
  dragging) and full role names for screen readers.
- After a wrong drag-and-drop answer, the feedback panel shows a small court
  with the correct arrangement.
- 2 drag-and-drop questions (back row with the libero; placing partners) and
  9 glossary terms (Bump, Platform, Lift, Shank, Stuff block, Foot fault,
  Fault, Line judge, Topspin serve).
- Widget tests for drag-and-drop and tests for the developer clock.

## [0.1.0] - 2026-10-23

### Added
- Flutter project scaffold for iOS and Android (`ca.sixonsix`, `six_on_six`),
  pinned to Flutter 3.47.6.
- App shell: bootstrap with `ProviderScope` and error logging, a go_router
  router with a placeholder home screen, Material 3 theme, logger wrapper,
  `Clock` abstraction (UTC), and a `GameRules` config with lockouts off.
- Smoke widget test (app boots to home) and `Clock` unit tests.
- Strict lints via `very_good_analysis`.
- GitHub Actions CI: format, analyze, and test, plus an Android debug APK build.
- `.gitattributes` enforcing LF line endings, README, and this changelog.
- Content pipeline: CSV authoring files in `content/source/` and
  `content/export_content.dart`, which validates them and writes
  `assets/content/course.json`. CI fails if the JSON is out of date.
- Draft content for units 1 to 4: 12 lessons, 24 teaching cards, 60 questions
  with FIVB rule references (pending review).
- Learning path with unit headers, unlocking and replays.
- Lesson player: teaching cards, complete-until-correct queue, feedback panel,
  quit prompt, lesson complete screen. Question types: multiple choice,
  true/false, matching, tap the zone (court drawn with `CustomPainter`).
- Unit reviews built from concept tags; XP and daily streak (in memory for now).
- Rally colour tokens (`AppTokens`) and the accessible button red.
- Tests for the lesson queue, streaks, unlocking, XP and content parsing (19 total).
- `tool/screenshots/capture_test.dart` renders app screens to `build/screens/`.
