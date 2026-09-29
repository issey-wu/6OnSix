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
