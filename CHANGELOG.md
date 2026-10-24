# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/). Milestone tags: `v0.1.0` (midterm),
`v1.0.0` (final).

## [Unreleased]

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
