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

- **Saved progress:** drift tables for the local user, an append-only answer log, append-only completions, a progress summary (XP, streak, last active day) and settings. Completed lessons are derived from the completions. The summary is updated in the same transaction as each completion. If the database cannot open, the app falls back to in-memory storage instead of failing to start.
- **uuid** for record IDs created on the device.
- **audioplayers** for sound effects, set to ambient audio so it respects the silent switch. Sounds are skipped in widget tests.

## Content

- Content is authored in a spreadsheet, then exported to JSON and validated by a Dart script. The app never hard-codes content or content counts.
- **Rules baseline:** the FIVB 2025-2028 rules, with `ruleRef` on rules-based questions and a `leagueNote` where local leagues commonly differ.
- **Question types:** multiple choice, true/false, matching, tap the zone, and drag-and-drop.
- **Court:** zones 1 to 6 in FIVB numbering, and distinct tokens (S, OH1, OH2, MB1, MB2, OPP, L), with exact-placement grading. Display and animate modes may use normalized coordinates.

## Game rules

- **Lessons are complete-until-correct:** wrong answers are re-queued, nobody fails, and there are no lockouts.
- **XP and streak values** live in one config object in `domain`. Streaks use the injected `Clock` and the device-local date.

- **Glossary:** authored in `content/source/glossary.csv` and exported into `course.json` (schema version 2), sorted A to Z.
- **Drag-and-drop:** tokens in the options column, placements such as `S=1|OPP=4` in the answer column. The exporter checks every token is placed once, zones are unique, and the libero is in the back row.

## Sound

- Correct, incorrect and lesson-complete sounds are made in-house in Duolingo's style: a short rising chime, a soft falling tone and a quick rising jingle. The matching pop and token snap come from Kenney's Interface Sounds (CC0, public domain).

## Tooling

- **`dart run tool/check.dart`** runs every check (packages, database code generation, content export, format, analyze, test) and writes `build/check.log`. Add `--screens` to render screenshots to `build/screens/`.

- **GitHub Actions CI** on pushes and PRs to `main`. One job runs format, analyze, and test. A second job builds a debug APK, because the Mac has no Android SDK.
- **Claude Code attribution is turned off** in `.claude/settings.json`.

## Team workflow

- **Yash leads UI and UX.** He owns the look and behaviour of screens: `lib/core/ui/`, `lib/app/theme.dart` and `lib/features/*/presentation/`. Issey owns logic, data, content, tests and tooling. Either can change the other's area for the demo, and design changes are reconciled in rounds.
- **Always branch from the latest `main`** and keep branches short, so work merges cleanly.
- **Co-author credit:** any commit that includes Yash's code, design, or changes made from his review feedback ends with `Co-authored-by: Yash Dubey <dubeyy@mcmaster.ca>`, so GitHub credits both of us. Commits he had no part in don't get the line, so the history stays accurate.
- **Reconciling `yash/screens` (Nov 2026):** the demo build stayed the base. Yash's developer menu, drag-and-drop interaction, player token design, correct-arrangement court, tests, 2 new questions and 9 new glossary terms were ported into it, credited to him. His duplicate rotation question and the glossary terms that matched existing ones were left out.
