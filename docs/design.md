# 6 On Six: Design Document

Written by Yash Dubey, reconciled with Issey Wu. This is the UI and game-rule spec for the fully offline app (Schedule 1). Online features (accounts, sync, leaderboards, duel mode, App Store release) are out of scope here and will get their own section if Schedule 2 goes ahead. The screen mockups are in the original PDF.

## 1. Product summary

6 On Six is a mobile app that teaches volleyball concepts using a Duolingo-style learning model: short lessons, instant feedback, a learning path that unlocks as you go, XP, and daily streaks.

**The problem:** new and intermediate players joining beginner or semi-competitive teams often don't know the rules, positions, terminology, and rotations, and teams lose practice time explaining them.

**The solution:** bite-sized, gamified lessons players can do on their own time, anywhere, including in gyms with bad Wi-Fi.

**Platform:** Flutter mobile app (iOS primary for demos, Android-compatible).

**Core principle:** fully offline. All content is bundled with the app at install time. Progress is stored on the device.

### Target users

- **Primary:** new players joining a team, who need the fundamentals fast.
- **Secondary:** intermediate players with gaps in their knowledge (for example, a player who has only ever played one position and doesn't understand the rest of the court).

Design implications: assume no prior knowledge, never punish mistakes harshly, and keep sessions short (a lesson should take about 2 to 4 minutes).

### Design principles (carried over from Duolingo)

- **Teach first, then assess.** Every lesson opens with a short teaching card.
- **One linear path.** No choosing between branches, and no choice paralysis. The app always makes the next step obvious.

### Scope

- Welcome and first-launch flow
- Learning path with 4 units, 3 lessons per unit, and an end-of-unit review per unit
- Teaching cards at the start of every lesson
- Lesson player with five question types
- Instant feedback with explanations
- XP, daily streaks, and unlock progression
- Searchable glossary
- Profile and progress screen
- Settings: theme, sound, haptics, reset progress
- Light mode (Rally) and dark mode (Night)
- Audio and haptic feedback with independent toggles

### Content targets

4 units, 12 lessons, about 80 questions, and about 50 glossary terms. These numbers will grow later, so nothing in the app should assume them. The app displays whatever the content files contain.

### Demo target

A complete loop in airplane mode:
1. Open the learning path.
2. Finish a lesson that includes a court question.
3. Look up a term in the glossary.
4. Close and reopen the app, and confirm progress is still there.

### Out of scope

Accounts and login, cloud sync, leaderboards, asynchronous duel mode, certificates, hearts or lives, streak freezes, placement tests, onboarding questionnaires, push notifications, paywalls or in-app purchases, and mascot animations.

## 2. Game rules

### Learning path and unlocking

- The path is a single vertical sequence. Each unit contains: Lesson 1 → Lesson 2 → Lesson 3 → Unit review.
- Only the first lesson of Unit 1 is unlocked on first launch.
- Completing a node unlocks the next node. Completing a unit review unlocks the first lesson of the next unit.
- Completed nodes can be replayed at any time.
- Locked nodes show a lock icon. Tapping one shows a short message: "Finish the lesson before this to unlock it."

### Inside a lesson: complete until correct

- A lesson opens with 1 to 2 teaching cards, followed by roughly 6 to 7 questions.
- The user answers one question at a time and taps **Check**.
- **Correct:** positive feedback, then the next question.
- **Incorrect:** the correct answer and a one-sentence explanation are shown. That question moves to the end of the lesson queue and is asked again.
- The lesson is complete when every question has been answered correctly once. Nobody can fail a lesson.
- The progress bar at the top fills based on how many questions have been answered correctly, so it never moves backward.
- The user can quit mid-lesson with the X button, after a confirmation: "Quit this lesson? Your progress in this lesson won't be saved." Quitting awards no progress or XP for that lesson.

### XP

| Event | XP |
|---|---|
| Complete a lesson | +10 |
| Perfect lesson (no mistakes) | +5 bonus |
| Complete a unit review | +20 |
| Perfect unit review | +5 bonus |

- Replaying a completed lesson earns XP the same way.
- XP is a running total shown on the home screen and the profile. It has no other function.

### Streaks

- The streak is the number of consecutive calendar days (device local date) on which the user completed at least one lesson or review.
- Completing more lessons on the same day doesn't add more.
- If a full calendar day passes with no completed lesson, the streak resets to 0.
- The streak only increases when a lesson is completed, not started.
- Streak logic must use the app's clock abstraction rather than reading the system time directly, so it can be tested with simulated days.
- When a lesson completion extends the streak, the lesson complete screen shows a short streak celebration.

### Unit review

- Uses the same lesson player and the same complete-until-correct rule.
- Pulls about 8 questions from the unit's three lessons using their concept tags, shuffled.
- Shown on the path as a trophy node.

## 3. App structure and navigation

**First launch:** Splash → Welcome → Lesson 1.1 (teaching card, then questions) → Lesson complete → Home

**Main app (bottom navigation bar, 3 tabs):**

```
├── Learn (home / learning path) → Lesson player → Lesson complete
├── Glossary (search + list) → Term detail
└── Profile (stats) → Settings
```

- The bottom navigation bar is hidden inside the lesson player.
- The app always reopens on the Learn tab.

## 4. Screen specifications

### Splash

App logo centered on the background color. Shown only while the app loads; no button.

### Welcome (first launch only)

- Large "6 On Six" wordmark in the heading font.
- Tagline: "Learn the game. Own the court." (placeholder)
- A short line explaining the app: "Quick lessons on rules, positions, and rotations. Works offline."
- Primary button: **Get started**.

### First lesson (first launch only)

- Get started opens Lesson 1.1 directly. Nothing is asked about the user first (no name, experience level, or goals).
- After the first lesson completes, the user lands on Home with Lesson 1.2 as the current node.
- The user's name is optional and can be added later in Profile. Until then, the app uses "Player".

### Home / Learning path (Learn tab)

**Top bar:**
- **Left:** streak (flame icon and number). Shown grayed out when the streak is 0.
- **Right:** total XP.

**Body:**
- A greeting line: "Hey, {name}" (small), or "Hey there" if no name is set.
- The path scrolls vertically. Each unit starts with a unit header card (brand red background) showing the unit number, the unit title, and a one-line description.
- Lesson nodes are large circles (about 64 px) arranged in a gentle zigzag.
- Node states:
  - **Completed:** yellow fill, check icon.
  - **Current (next to do):** orange fill, play icon, slightly larger, with a subtle pulse. Only one node is current at a time.
  - **Locked:** neutral fill, lock icon.
  - **Review:** trophy icon, using the same state colors.
- Tapping the current node or a completed node opens a small popup card showing:
  - the lesson title
  - the number of questions
  - a **Start** button (or **Practice again** for a completed lesson)
- On open, the path auto-scrolls so the current node is visible.

### Lesson player

A lesson has two stages: teaching, then questions.

**Stage 1: teaching cards**
- Every lesson opens with 1 to 2 short teaching cards that introduce what the questions will cover.
- Each card has a short title, 2 to 4 sentences of plain-language explanation, and an optional image or court diagram.
- A **Continue** button moves to the next card. After the last card, it moves to the first question.
- On replays of a completed lesson, a **Skip** text button lets the user go straight to the questions.
- The progress bar tracks questions only, so it starts filling once the questions begin.

**Stage 2: questions.** The layout, from top to bottom:
1. **Top bar:** X (quit) on the left, with the progress bar filling the rest.
2. **Instruction line:** small text describing the task, such as "Select the correct answer", "True or false?", "Match the pairs", "Tap the correct zone", or "Drag players into position".
3. **Prompt:** the question text, large and readable, with an optional image or court diagram below it.
4. **Answer area:** depends on the question type (see Section 5).
5. **Check button:** pinned to the bottom, full width. It looks disabled until the user has given an answer.

After Check, a feedback panel slides up from the bottom:
- **Correct:** success color, check icon, a short random praise line ("Nice!", "Clean pass!", "Ace!"), and a **Continue** button.
- **Incorrect:** error color, X icon, "Correct answer:" followed by the answer, then the one-sentence explanation, then the league note if the question has one, and a **Continue** button.
- Sound and haptic feedback fire when the panel appears, if enabled.

### Lesson complete

- A big heading: "Lesson complete!" (or "Perfect lesson!" if there were no mistakes).
- Stat cards:
  - XP earned
  - accuracy (first-try correct ÷ total questions)
  - the streak
- If the streak increased today, the flame animates and shows the new number.
- **Continue** returns to the path, where the next node becomes current with a short unlock animation.

### Glossary tab

- A search bar at the top filters as the user types. It matches both the term name and the definition text.
- Below it is an alphabetical list, grouped by first letter. Each row shows the term name and the first line of the definition.
- When a search finds nothing, show: "No terms match "{query}". Try a different word."
- All glossary terms are available from the start, regardless of progress.

### Term detail

Shows:
- the term name (as the heading)
- the full definition
- an optional diagram
- an example of use in a sentence
- "Related terms" as tappable chips

### Profile tab

- The user's name (tap to add or edit; shows "Player" until set). A settings gear icon sits in the top right.
- Stat cards: current streak, total XP, lessons completed (for example, 5 / 12), and units completed.
- A simple list of units, each with a progress bar.

### Settings

- **Appearance:** System (default), Light, Dark.
- **Sound effects:** on/off (default on).
- **Haptics:** on/off (default on).
- **Reset progress:** a red text button with a confirmation dialog: "This clears your XP, streak, and completed lessons. This can't be undone."
- **About:** app version, team names, course name.

## 5. Question types

Every question has:
- a prompt
- a correct answer
- a one-sentence explanation
- one or more concept tags
- an optional league note

There are five types: multiple choice, true or false, matching, tap the zone, and drag-and-drop.

### 5.1 Multiple choice

- 2 to 4 answer options, shown as large, full-width tappable cards.
- Single select. Tapping an option selects it (highlighted border); tapping another option changes the selection.
- Options are shuffled each time the question appears.

### 5.2 True or false

- The prompt is a statement.
- Two large side-by-side buttons: **True** and **False**.

### 5.3 Matching

- 3 to 5 pairs in two columns (for example, terms on the left and definitions on the right). Both columns are shuffled.
- The user taps an item on the left, then its match on the right.
- **Correct pair:** both items turn the success color, then fade to a matched state and become untappable.
- **Wrong pair:** both items shake briefly in the error color, then deselect.
- There is no Check button. The question ends automatically when all pairs are matched.
- A wrong pairing removes the perfect-lesson bonus. The question itself counts as completed and does not come back.

### 5.4 Tap the zone

- Shows the court diagram (see Section 6).
- The prompt asks the user to tap a zone, for example: "Where does the setter start in this rotation?"
- Tapping a zone highlights it. Then the user taps Check.

### 5.5 Drag-and-drop rotation

- Shows the court diagram, with a tray of player tokens below it.
- The user drags tokens onto zones. A token snaps into a zone when released near it, with a light haptic "snap".
- Tokens can be moved again or dragged back to the tray.
- Check becomes active once every token in the tray is placed.
- The answer is correct only if every token is in its correct zone. When incorrect, the feedback panel shows the correct arrangement.

### Court question grading

Both court question types are graded on exact placement only, with no partial credit. This keeps answer keys unambiguous and grading predictable.

## 6. Court

- **Orientation:** the court is shown from the user's team's side, with the net at the top of the diagram.
- **Zones** follow FIVB numbering:

  |  | Left | Middle | Right |
  |---|---|---|---|
  | Front row | 4 | 3 | 2 |
  | Back row | 5 | 6 | 1 |

- **Tokens:** S (setter), OH1 and OH2 (outside hitters), MB1 and MB2 (middle blockers), OPP (opposite), and L (libero).
  - Each token has a distinct label, so exact-placement answers are unambiguous.
- **Token set per question:** each drag-and-drop question defines which tokens appear in its tray.
  - When the libero is in play, L replaces the back-row middle blocker, and that MB token is left out of the tray.
  - Under FIVB rules, the libero may only occupy a back-row zone (5, 6, or 1).
- **Accessibility:** each zone has a screen-reader label, such as "Zone 4, front left".

## 7. Content

### Units

The units are rules- and legality-focused. Physical technique is out of scope. Lesson titles live in the content spreadsheet.

| Unit | Focus |
|---|---|
| 1 | Court, zones, positions, and roles |
| 2 | Rules and terminology: scoring, legal contacts, faults, common calls |
| 3 | Rotations: rotation order, overlap (receiving team), serve receive, libero rules |
| 4 | The 5-1 system: base positions, switching, setter in the front and back row |

### What each content item needs

Content is authored in a spreadsheet and exported to JSON files bundled with the app.

- **Unit:**
  - id
  - order
  - title
  - one-line description
- **Lesson:**
  - id
  - unit id
  - order
  - title
  - 1 to 2 teaching cards, each with a title, text, and an optional image or court diagram
- **Question:**
  - id
  - lesson id
  - type
  - prompt
  - answer data: options and the correct option, a true/false value, pairs, a zone, or token placements
  - token set (drag-and-drop only)
  - one-sentence explanation
  - concept tags
  - optional image
  - FIVB rule reference (rules-based questions)
  - optional league note
  - phase: serving or receiving (rotation questions)
- **Glossary term:**
  - id
  - term
  - definition
  - optional example sentence
  - optional related term ids
  - optional unit id

The authoring pipeline validates the spreadsheet before export, so broken or incomplete content is caught before it reaches the app. The app never hard-codes content. Adding a lesson or question only requires editing the spreadsheet and re-exporting.

### Rules baseline

- All answer keys follow the FIVB 2025-2028 rules, so there is a single standard to resolve disagreements between authors.
- Where local or recreational league play commonly differs from FIVB, the question includes a short league note, shown in the feedback panel under the explanation (for example, "Some recreational leagues allow...").
- Glossary definitions follow the same baseline.

## 8. Visual design

### Themes

- **Light mode, Rally:** bold and energetic, carried over from the Capstone I presentation.
- **Dark mode, Night:** a dark background with the same brand colors as light mode, so the brand looks the same in both.
- The app follows the phone's setting by default, with a manual override in Settings.

### Color tokens

All colors come from these named tokens. Screens never hard-code colors.

| Token | Light (Rally) | Dark (Night) | Used for |
|---|---|---|---|
| background | #FBFAF5 | #121318 | Screen background |
| surface | #FFFFFF | #1E2030 | Cards, panels, popups |
| surfaceMuted | #E8E4DA | #2A2C3A | Locked nodes, empty progress |
| textPrimary | #2A1A10 | #F2F2F5 | Main text |
| textSecondary | #7A746A | #A9ADC9 | Supporting text, locked icons |
| brandRed | #E03A1E | #E03A1E | Unit headers, accents |
| buttonRed | #C9341A | #C9341A | Primary buttons (meets 4.5:1 with onBrandRed) |
| onBrandRed | #FFF6EE | #FFF6EE | Text on brand red and button red |
| brandOrange | #F7941D | #F7941D | Current node, highlights |
| brandYellow | #F2F55C | #F2F55C | Completed nodes, XP accents |
| onYellowOrange | #3A1C00 | #3A1C00 | Text and icons on yellow or orange |
| success | #2FA84F | #3DC463 | Correct feedback |
| error | #C2185B | #E04882 | Incorrect feedback |
| selectedBg | #FEF1E2 | #3A2A18 | Background of a selected answer (border uses brandOrange) |
| successBg | #E3F5E8 | #16301F | Correct feedback panel, matched pairs |
| onSuccess | #1E6B33 | #9BE8B0 | Text on successBg |
| errorBg | #FBE3EC | #3A1626 | Incorrect feedback panel, wrong selection |
| onError | #8E1145 | #F4B3CB | Text on errorBg |
| buttonEdge | #A82A14 | #A82A14 | Darker bottom edge under primary buttons |

- **Incorrect uses raspberry pink.** Because the brand color is red, "incorrect" uses raspberry pink instead of red, so mistakes aren't confused with normal buttons.
- **Never color alone.** Feedback always includes an icon and text too.
- **Yellow is for fills only.** Never use yellow text on a light background.

### Typography

- **Headings, numbers, wordmark:** Unbounded.
- **Body text, buttons, questions:** Work Sans.
- Both fonts are bundled with the app. There are no runtime font downloads.
- The app supports the phone's text size setting. At the default size, question text is never smaller than 18 px.

### Shapes and layout

- **Corner radii:** cards about 16 px, buttons about 14 px. Nodes are fully circular.
- **Primary buttons:** full width, button red, about 56 px tall, with a slightly darker bottom edge so they look pressable.
- **Tap targets:** at least 48 × 48 px.
- **Spacing:** generous, with one main action per screen.

### Motion

Short and snappy, about 150 to 300 ms. Nothing should delay the user from continuing. The key moments are:
- the feedback panel sliding up
- matching pairs locking in
- a node unlocking on the path
- the streak flame on the complete screen

### Tone of voice

Like a friendly, encouraging coach. Short sentences, with volleyball flavor in praise lines ("Ace!", "Clean pass!", "Kill!"). Never sarcastic or shaming about mistakes.

## 9. Sound and haptics

Sound and haptics have separate on/off toggles. Sound respects the phone's silent mode.

| Moment | Sound | Haptic |
|---|---|---|
| Correct answer | Short bright chime | Light success tap |
| Incorrect answer | Soft low tone | Medium tap |
| Matching pair locked | Small pop | Light tap |
| Token snaps to zone | Click | Light "snap" tap |
| Lesson complete | Short celebration jingle | Success pattern |
| Regular button taps | None | None |

## 10. Accessibility

- Never communicate with color alone; pair it with icons and text.
- Text meets readable contrast in both themes.
- Layouts stay usable with large system text sizes, with nothing cut off or overlapping.
- Tap targets are at least 48 × 48 px.
- Buttons and nodes have screen-reader labels, for example "Lesson 2, Basic rules, locked".
- Each court zone has a screen-reader label, for example "Zone 4, front left".
- Animations stay short, and nothing flashes.

## 11. Still to decide

- Final lesson titles and content.
- Logo and app icon.
- Whether to have a mascot.
- Final feedback colors (success and error).
