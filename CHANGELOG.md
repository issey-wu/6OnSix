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
