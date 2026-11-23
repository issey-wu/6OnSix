# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/). Milestone tags: `v0.1.0` (midterm),
`v1.0.0` (final).

## [Unreleased]

### Changed (Round 7: design polish, Nov 23)
- The lesson bar starts with a small head start instead of empty, and shows
  "2 to go" and "1 to go" over the last stretch.
- Light haptic taps on every tab, button, row, answer choice and court
  zone, and when picking up a player; main buttons tap a little firmer.
  The Haptics setting turns them all off.
- All icons use one rounded style that matches the app's font.
- Softer diagrams: rounded court corners, lighter lines, the net as a
  rounded band, and highlights as rounded tiles. The serve card has a new,
  friendlier server in the team's colours, and the centre line card shows
  shoes instead of plain shapes.
- Matching tiles have the same raised edge as the other answer choices.
- Settings: "Reset progress" moved to the bottom, on its own, in red.
- Tutorial highlight rings have corners that follow what they surround.

### Changed (Round 6: feedback from testing, Nov 23)
- Clearer lesson order: rotating comes before the starting lineup, "side
  out" is taught with rotating, and "set" (the touch) and "set" (the game)
  are both explained in Unit 1.
- Shorter, plainer card text, with a short check question after each card.
  Questions straight after a card no longer repeat its example (zone 4
  instead of zone 2, for instance).
- New diagrams: the net between the antennae, the centre line and foot
  faults, back-row attackers behind the attack line, and the server behind
  the end line. The court diagram now uses drawing-style dimension lines.
- Words on cards and in Show me how are tappable and open their meaning.
  Only words from the current unit or earlier are linked or listed.
- "Skip tutorial" is now its own button in a corner of every tip.
- The quest chest reward is a themed sheet with Ace instead of a plain
  dialog.

### Added (Round 5: first-run guide and polish)
- A first-run guide. Ace darkens the screen around one part at a time and
  explains it: where to answer, Check, Show me how, what happens after a
  mistake, the hint, then the path, streak, daily goal and tabs, the league
  ladder, quests and glossary search. Tapping the lit-up part uses it, so the
  guide never costs an extra tap. Each tip shows once.
- "Skip tutorial", on every tip and on the welcome screen for returning
  players, with a confirmation. Settings can replay the tutorial.
- Lessons now alternate: a card, then the questions it sets up, then the
  next card. A new learner reaches the first question in two taps.
- League peek: tap any badge on the ladder to see that league's name, who
  moves up and down, typical XP and the top of a typical week.
- Developer menu: a styled sheet for jumping to any lesson, and streak
  freezes can be taken back as well as given.

### Added (Round 4: Ace the mascot)
- Ace, an eagle mascot drawn by Yash Dubey, with both wings and three wing
  shapes. He blinks, breathes and glances around, and waves, cheers, pumps
  a fist, hops, shrugs or sighs depending on what the learner does. His
  face changes too: smiling eyes and a grin, a wink, big surprised eyes, or
  worried brows and a tear. His speech bubbles are short and a bit cheeky.
- The welcome screen: Ace waves and says hello.
- Lessons: Ace leans in from the edge of the screen at milestones only (a
  run of right answers, the first mistake, a second miss in a row, and the
  last question), then slides back out of sight.
- Lesson complete: Ace cheers, with a line about the streak or a perfect
  lesson.
- The Learn tab: Ace stands beside the next lesson. Tap him for a line about
  your day.
- Ace asks the daily goal question, looks sad (with a tear) on the quit and
  reset sheets, and reacts to league results.
- With Reduce Motion on, Ace holds still.

### Added (Round 3: demo community)
- A League tab. Earning XP joins this week's league with 29 simulated
  players, Monday to Monday. The top players move up a division and the
  bottom ones move down, across seven divisions from Rec to Olympic. A
  results sheet shows how the week ended.
- Six simulated friends, with avatars, streaks and weekly XP, and a profile
  page each with their recent lessons.
- Everything here is labelled "Demo community" and runs offline.
- Developer menu: "End this league week now", to show a promotion in a demo.

### Changed (from user testing, Nov 15)
- Teaching cards now show diagrams: the whole court with its measurements,
  the six numbered zones, the starting lineup with each role, the libero,
  and the clockwise rotation.
- The first lesson works like a tutorial: seven short cards, one idea each,
  then the easiest questions first.
- The hint on a tap the zone question numbers one other zone, two along
  from the answer, so the learner counts round to it.
- Help fades as the course goes on: Unit 1 teaches with diagrams on every
  card; later units teach in words, so answers are less obvious.
- "Show me how" adds a picture when the question is about a place on the
  court (size, lines, zones, lineup, rotation), including an animation of
  the team rotating. Rules and terms are explained in words alone.
- Each unit header has its own badge (zones, whistle, rotation, team), and
  the final review shows the app logo.
- Five more avatar hairstyles (spiky, mohawk, bob, pigtails, braids), and
  the buzz cut now follows the shape of the head.
- Confirmations (quit a lesson, reset progress) and the name box are now
  sheets in the app's own style.
- The developer menu is in every build, release included, for demos.

### Added (polish round)
- Avatar builder on the Profile tab: pick one of 50 ready-made players, or
  build your own from skin tone, hair, hair colour, jersey colour and
  number, and a headband. Saved on the device (database schema version 3).
- New sounds for answers, matched pairs, placed players, lesson complete,
  and two new moments: chest opened and streak extended.
- Motion throughout: screens rise and fade in, the path drops in, the next
  lesson floats, questions slide, the answer panel springs up, XP counts up,
  confetti on lesson complete, and ready chests wiggle. All of it follows
  the phone's Reduce Motion setting.

### Changed (polish round)
- New Flame Court look, built from the app icon's colours, with the Nunito
  font and chunky buttons and cards that press down.
- The welcome screen shows the app icon artwork instead of a generic ball.

### Added (Round 2a: motivation, following Duolingo's mechanics)
- Daily goal: Casual, Regular, Serious or Intense (5, 10, 15 or 20 minutes,
  backed by 10, 20, 30 or 50 XP). Asked once after the first lesson, with a
  7, 14 or 30-day streak commitment; changeable in Settings and Quests.
- Goal ring on the Learn tab and a daily goal bar on the lesson complete
  screen.
- Quests tab: 3 daily quests from easy to hard, each with a chest. Chests
  give bonus XP, a streak freeze, or (the third chest) 15 minutes of double
  XP. Monthly challenge: 20 quests in a month.
- Streak freezes: hold up to 2; they cover missed days automatically when
  the app opens or a lesson finishes.
- Streak milestones at 7, 30, 100 and 365 days, each with a celebration and
  a free streak freeze.
- Developer menu: give a streak freeze; start over as a new learner.
- Saved on the device in a new table (database schema version 2), with a
  migration that keeps existing progress.

### Changed
- New app icon: a volleyball in flames on dark red, designed by Yash Dubey.
  The original logo and the 1024 px master are in `docs/branding/`.

### Added (Round 1: learning upgrades)
- Hint button (lightbulb) on every question. The hint fits the question
  type: removes a wrong option, explains a key term, highlights the right
  row, places one player, or matches one pair. A hint only removes the
  perfect-lesson bonus.
- "Show me how" after every answer: the explanation as numbered steps, an
  animated court for drag-and-drop, the zone for tap the zone, the rule
  reference and words to know from the glossary.
- Final review after the last unit, drawing 12 questions from every unit.
  It can be replayed any time.
- "Practice weak spots" on the Learn tab once 3 or more questions count as
  weak, based on the answer log.
- The lesson progress bar now fills to the end before the complete screen.

### Added (earlier)
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
