# Technical Choices

A short list of the current stack and architecture choices. Update an entry when it changes.

## Platform and stack

- **Flutter, iOS first, Android-compatible.** One codebase for both platforms. iOS builds happen on the Mac.
- **Riverpod** for state and dependency injection. It lets tests swap in fakes.
- **go_router** for navigation.
- **drift (SQLite)** for user data: progress, the answer log, XP, and streaks. It gives typed queries and versioned migrations.
- **very_good_analysis** for lints, with `public_member_api_docs` turned off. It also enforces the no-`print` rule.
- **meta** for `@immutable` in domain code, which can't import Flutter.
- **Flutter 3.47.6 (Dart 3.13.5)**, pinned on both machines and in CI.

## Offline-first

- The app has no backend. Content is bundled at install time, and user data stays on the device.
- **Data rules:** client-generated UUIDs, `updated_at` timestamps, an append-only answer log, and a repository layer. These keep a future online sync from requiring a rewrite.

## Content

- Content is authored in a spreadsheet, then exported to JSON and validated by a Dart script. The app never hard-codes content or content counts.
- **Rules baseline:** the FIVB 2025-2028 rules, with `ruleRef` on rules-based questions and a `leagueNote` where local leagues commonly differ.
- **Question types:** multiple choice, true/false, matching, tap the zone, and drag-and-drop.
- **Court:** zones 1 to 6 in FIVB numbering, and distinct tokens (S, OH1, OH2, MB1, MB2, OPP, L), with exact-placement grading. Display and animate modes may use normalized coordinates.

## Game rules

- **Lessons are complete-until-correct:** wrong answers are re-queued, nobody fails, and there are no lockouts.
- **XP and streak values** live in one config object in `domain`. Streaks use the injected `Clock` and the device-local date.

## Tooling

- **GitHub Actions CI** on pushes and PRs to `main`. One job runs format, analyze, and test. A second job builds a debug APK, because the Mac has no Android SDK.
- **Claude Code attribution is turned off** in `.claude/settings.json`.
