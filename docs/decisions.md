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
- **Hints:** one per question, worked out from the question itself so no extra content is needed. Using a hint is never a wrong answer; it only removes the perfect-lesson bonus.
- **Final review:** one node after the last unit, 12 questions drawn across every unit so each concept is covered where possible. Earns review XP and can be replayed.
- **Weak spots:** a question is weak while `2 x misses - right answers > 0` in the answer log. Because every miss in a lesson is followed by a right answer, one more right answer per miss clears it. Practice appears once 3 questions are weak and asks up to 8.

- **Glossary:** authored in `content/source/glossary.csv` and exported into `course.json` (schema version 2), sorted A to Z.
- **Drag-and-drop:** tokens in the options column, placements such as `S=1|OPP=4` in the answer column. The exporter checks every token is placed once, zones are unique, and the libero is in the back row.

## Sound

- **All sounds are made in-house** by `tool/sounds/synth.py` (numpy only, no samples, nothing to license). The set mixes two of its styles, picked by the team: "bright chime" (marimba and bells) for answers, pairs, placed players and chests, and "arcade" for lesson complete and streak extended.

## Tooling

- **`dart run tool/check.dart`** runs every check (packages, database code generation, content export, format, analyze, test) and writes `build/check.log`. Add `--screens` to render screenshots to `build/screens/`.

- **GitHub Actions CI** on pushes and PRs to `main`. One job runs format, analyze, and test. A second job builds a debug APK, because the Mac has no Android SDK.
- **Claude Code attribution is turned off** in `.claude/settings.json`.

## Motivation layer (Round 2)

- **Follows Duolingo's mechanics** as closely as an offline app allows (research and sources in the roadmap doc). Changes are only where we have no shop, accounts or internet: chests give bonus XP or streak freezes instead of gems.
- **Daily goal:** four levels shown as minutes (5, 10, 15, 20) with XP targets (10, 20, 30, 50). Asked after the first lesson, keeping our "no questionnaire before the first lesson" rule.
- **Streak freezes:** at most 2 held, applied automatically, and only when there are enough to cover every missed day.
- **Quests:** 3 a day, one easy, one medium, one hard, chosen from the date so they stay the same all day. The third chest is always a 15-minute double-XP boost.
- **Storage:** the motivation state is one JSON document in a new `user_extras` table (schema version 2). It holds derived and preference data only; the append-only answer log and completions remain the source of truth for learning history.

## Team workflow

- **Yash leads UI and UX.** He owns the look and behaviour of screens: `lib/core/ui/`, `lib/app/theme.dart` and `lib/features/*/presentation/`. Issey owns logic, data, content, tests and tooling. Either can change the other's area for the demo, and design changes are reconciled in rounds.
- **Always branch from the latest `main`** and keep branches short, so work merges cleanly.
- **Co-author credit:** from Nov 8, 2026, Yash collaborates on every feature, so every commit ends with `Co-authored-by: Yash Dubey <dubeyy@mcmaster.ca>` and Yash is added as reviewer on each pull request.
- **Reconciling `yash/screens` (Nov 2026):** the demo build stayed the base. Yash's developer menu, drag-and-drop interaction, player token design, correct-arrangement court, tests, 2 new questions and 9 new glossary terms were ported into it, credited to him. His duplicate rotation question and the glossary terms that matched existing ones were left out.

## Look and avatars (polish round)

- **Flame Court theme:** colours from the app icon, Nunito bundled as the only font (replaces the planned Unbounded and Work Sans, which were never bundled), and chunky pressable shapes. Animation helpers live in `lib/core/ui/motion.dart` and all respect Reduce Motion. No new packages.
- **Avatars:** a player drawn with a `CustomPainter` from a few options (skin tone, hair, hair colour, jersey colour and number, headband), plus 50 fixed ready-made combinations. Saved as JSON in a new `user_extras.avatar_json` column (schema version 3).
- **Diagrams on teaching cards (user testing, Nov 15):** a `diagram` column in `content/source/cards.csv` (such as `court:net` or `zones:1`), drawn in `card_diagram.dart` and checked by the exporter. These are part of the lesson, not pop-over tutorials.
- **Guidance fades as units progress** (the "fading" principle from worked-example research): Unit 1 cards carry diagrams; later units teach in text so questions are less obvious. Visual help stays available after answering, in "Show me how", where `howToDiagram` adds a diagram or animation only for questions about a place on the court. Zone numbers are never drawn on a question up front (that made the first questions too easy in testing); the hint numbers one other zone so the learner still has to count.
- **Developer menu in release builds:** the app has no public users, and demos run the release build, so the menu ships in every build (Nov 16).

## Demo community (Round 3)

- **Simulated, offline, labelled.** The League and friends use made-up players generated on the device from a seed, so the same week always looks the same and nothing needs a server. Every screen with them says "Demo community". Real online play stays out of scope.
- **League model:** 30 players per league, Monday to Monday in local time, joined by earning XP. Seven divisions (Rec, House League, Club, Varsity, Provincial, National, Olympic); top 10 move up from Rec, top 7 elsewhere; bottom 5 move down except in Rec. Each simulated player has XP for each day and a usual practice time, so their totals grow through the week. Higher divisions have stronger players.
- **Storage:** `user_extras.league_json` (schema version 4). Friends need no storage: their streaks and XP are worked out from the date.

## Ace the mascot (Round 4)

- **Artwork:** Yash Dubey's eagle, in separate parts under `assets/images/ace/`: three wing shapes (resting, open hand, fist), body, head, eyes, brows and two beaks, plus a side view of him leaning in from an edge. The parts were taken from his SVG animations and sprite sheet, so the app moves each part itself with plain Flutter transforms. No animation package (Rive, Lottie) is needed. The second wing is the first one mirrored.
- **Moves:** idle (breathing, blinking, glancing aside, a slow sway), wave, cheer (both wings up), fist pump, hop, shrug and sad (wings droop, a sigh and a tear). He can turn his face a little towards his speech bubble.
- **Faces:** happy (a smile), joyful (smiling eyes, a grin, rosy cheeks), cheeky (a wink and one brow up), surprised (big eyes) and sad (worried brows and a tear). The smiling eyes, blush and tear are drawn in code, in colours taken from the artwork. His beak opens and shuts while a speech bubble is up. With Reduce Motion on he holds one still pose, and nothing loops.
- **Mid-lesson pop-ups** use the side view, sliding in from the right edge; a sad moment uses the full front view so his face can show it.
- **Where, following Duolingo:** waving hello on the welcome screen; asking the daily goal question; beside the next lesson on the Learn tab (tap him for a line about the learner's day); popping up mid-lesson only at milestones (3, 5, then every 4 right in a row, the first mistake, a second miss in a row, and one question to go); sad on the quit and reset sheets; cheering on lesson complete with a streak line; and reacting to league results.
- **Voice:** playful and a bit cheeky, volleyball talk, short enough to read at a glance. The lines live in `lib/core/ui/ace_lines.dart`. His pop-up lines never give instructions; the first-run tips (Round 5) are where he explains things.

## First-run guide and polish (Round 5)

- **Guide (user feedback, Nov 22):** coach marks in `lib/core/ui/coach_mark.dart`, driven from `lib/app/tips.dart`. Each darkens the screen around one part and Ace explains it. Taps in the lit-up part go through to that part and close the tip, so tips never add taps; taps elsewhere do nothing. Tip ids live in `lib/core/domain/tips.dart`; the ones seen are saved in the settings table (`tips_seen`, schema version 5). This replaces the earlier "no tutorials" rule in CLAUDE.md.
- **Skipping:** "Skip tutorial" on every tip, and "I've played before" on the welcome screen, both ask for confirmation. Settings has "Replay the tutorial".
- **Alternating lessons:** `cards.csv` has a `check` column naming the questions asked straight after each card. `Lesson.interleaved()` builds the order; cards with no checks show with the next card, so content without checks behaves as before. A new learner now reaches the first question in two taps: Get started, then Continue.
- **League peek:** the ladder badges open a sheet about that league. Its "top of a typical week" uses the same made-up players a league there would start with.

## Feedback round (Round 6)

- **Lesson order (tester feedback, Nov 23):** Unit 1 lesson 3 teaches rotating first, then who serves, then the lineup, so "the order never changes" makes sense. "Side out" is taught with rotating. Both meanings of "set" (the touch and the game to 25) are in Unit 1.
- **Check questions:** a question asked straight after a card must not repeat the card's example; it uses a different zone or case.
- **Diagrams:** shared drawing helpers in `diagram_paint.dart` (dimension lines with arrowheads and a label gap, stick figures, tick and cross icons). Rule diagrams live in `rule_diagrams.dart`: `net`, `centre`, `backrow`, `serve`.
- **Gatekeeping:** tappable words (`GlossaryText`) and Show me how's "Words to know" only use glossary terms from the current unit or earlier. Single everyday words (court, net, pass) are not linked; at most 4 links per text.
- **Skip tutorial:** a separate pill button, top-right (bottom-right when the lit-up part is near the top), not part of Ace's card.
- **Reward popups:** sheets in the app's style with Ace, not plain Material dialogs.
