# Decision Log

Record one entry per decision: the date, what was decided, the reason, and what it replaced or ruled out. Add new entries at the bottom. Never delete an entry; if a decision changes, add a new entry that supersedes the old one.

## 2026-09-10: Flutter as the framework
**Decision:** Build with Flutter, targeting iOS and Android from one codebase.
**Why:** Issey owns an M3 Pro MacBook, which removed the main argument for Expo. Flutter was also already chosen in 4TR1.

## 2026-09-10: Drop Firebase and PostgreSQL; build local-first
**Decision:** Bundle the content with the app and store user data in on-device SQLite. There is no backend in Schedule 1.
**Why:** The offline MVP needs no server. The 4TR1 report listed Firebase and PostgreSQL together, which was redundant.

## 2026-09-10: Make the data model sync-ready from day one
**Decision:** Use client-generated UUIDs, an anonymous local user, `updated_at` timestamps, an append-only answer log, and a repository layer.
**Why:** These cost almost nothing now, and they turn Schedule 2 sync into a retrofit instead of a rewrite.

## 2026-09-22: Lock the scope
**Decision:** 4 units, 12 lessons, 80 questions, 50 glossary terms. Units 5 and 6 are conditional on a clean release candidate by Nov 21.
**Why:** This is achievable in the shortened term. It supersedes the 4TR1 minimum of 10 modules.

## 2026-09-22: Freeze question types at four by Oct 20
**Decision:** The types are multiple choice, fill-in-the-blank, terminology matching, and drag-and-drop court placement.
**Why:** Engineering cost scales with the number of question types, not the number of units. After the freeze, the remaining work is content.

## 2026-09-22: Author content as data
**Decision:** Author content in a spreadsheet and export it to JSON, with schema validation. Tag every question with concept tags that are independent of its unit.
**Why:** Adding a unit then costs authoring time only. The concept tags drive the review lessons, which provide spaced repetition.

## 2026-09-22: Publish on iOS only
**Decision:** If the app is published (Schedule 2), publish on iOS only.
**Why:** Google Play requires a 14-day closed test with 12 testers before a personal account can publish, and that doesn't fit the timeline.

## 2026-09-22: Two-schedule plan
**Decision:** Schedule 1 (the offline app) is committed. Schedule 2 (online features and publication) is gated at Oct 26, and it stops if any task slips more than 5 days.

## 2026-09-29: Riverpod, go_router, drift
**Decision:** Use Riverpod for state management and dependency injection, go_router for navigation, and drift for SQLite.
**Why:** All three are mainstream and well documented. Riverpod providers make repositories swappable for tests and for a future remote implementation. drift gives typed queries and versioned migrations, which the concept-tag queries need.

## 2026-09-29: No store distribution in Schedule 1
**Decision:** Demo builds install through Xcode free provisioning on iPhone and as a sideloaded APK on Android. User testing happens in person on the team's devices.
**Why:** The goal is a working demo, and none of this requires the App Store.

## 2026-09-29: GitHub as the only sync; two development machines
**Decision:** Keep the repo out of OneDrive and iCloud. Develop on macOS and Windows with a pinned Flutter version, LF line endings, and cross-platform Dart scripts.
**Why:** Cloud-drive sync corrupts `.git` folders and churns through build output.

## 2026-10-05: Pin Flutter 3.47.6
**Decision:** Both development machines and CI use Flutter 3.47.6 (Dart 3.13.5), stable channel. The version is recorded in `CLAUDE.md`, `README.md`, and `.github/workflows/ci.yml`.
**Why:** Formatter and lint output differ between Flutter versions. One pinned version keeps macOS, Windows, and CI in agreement.

## 2026-10-05: very_good_analysis for lints
**Decision:** Use `very_good_analysis` instead of the template's `flutter_lints`, with one rule disabled: `public_member_api_docs`.
**Why:** It is strict (strict-casts, strict-inference, strict-raw-types, and about 200 rules) and actively maintained by Very Good Ventures. It includes `avoid_print`, which enforces the logger rule. `flutter_lints` is too lenient, and the `lint` package is less actively maintained. `public_member_api_docs` is meant for published packages; in an app it would force a doc comment on every public widget.
**Replaced:** `flutter_lints`.

## 2026-10-05: CI on GitHub Actions
**Decision:** One workflow runs on push and pull request to `main`. Job `check` runs `flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze`, and `flutter test`. Job `android` runs in parallel and builds a debug APK with JDK 17. Both pin Flutter 3.47.6 via `subosito/flutter-action`.
**Why:** `main` must always build and pass. The Mac has no Android SDK, so without the APK job, Android breakage would go unnoticed until someone builds on Windows. There is no iOS build in CI; macOS runners are slow and costly, and iOS is verified on the Mac.

## 2026-10-05: Clock and GameRules as hand-written domain types
**Decision:** `Clock` (with `SystemClock`, which returns UTC) and `GameRules` live in `lib/core/domain/` as plain Dart. Their Riverpod providers live in `lib/app/providers.dart`. `GameRules` defaults: pass threshold 0.8, error cap 10 per 24 hours, retry cooldown 1 hour, and **lockouts off**. These are placeholders until the 4TR1 game-rules open item is decided. The logger is a thin wrapper over `debugPrint` with no package.
**Why:** Domain rules (scoring, unlocking, streaks) will consume both types, and domain can't import outward or depend on Riverpod. `package:clock`, `package:logging`, and freezed/equatable aren't needed for this little code.
**Dependency added:** `meta`, for `@immutable` on domain models. It is pure Dart, maintained by the Dart team, and already in the Flutter SDK's dependency tree; domain code can't use Flutter's re-export.
