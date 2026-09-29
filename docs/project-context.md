# 6 On Six: Project Context

This file consolidates the context from Capstone I (the 4TR1 final report, April 2025), the Capstone II project plan (Sept 18, 2026), and the planning discussions held since. When anything here conflicts with `docs/reference/`, this file wins.

## Problem and audience

Players at every level have gaps in their conceptual volleyball knowledge. Rotations are the biggest gap. The causes are:
- Positional bias: players learn only their own position.
- Being rushed up skill levels.
- Avoiding tactical material because it seems complex.

Existing resources don't close this gap:
- YouTube (Elevate Yourself) is passive video.
- learnvolley.com has no progression, tracking, testing, or offline mode.
- Pro analysis tools cost too much for most players.

6 On Six applies Duolingo's gamified microlearning model to volleyball. That model includes short lessons, instant feedback, progression, streaks, and spaced review.

The target users are new and intermediate players who are joining beginner or semi-competitive teams. The app must work offline because gyms often have unreliable connectivity.

## Team and roles

- Issey Wu is the lead developer. He owns architecture, all app code, the build, and release.
- Yash Dubey owns content authoring, requirements, user testing, and documentation.
  - Yash is newer to volleyball, which makes him a good pre/post-test subject. His results are evidence that the app meets its learning objective.
- The course is PROCTECH 4TR3, section C01. Professor Tom W has confirmed that the 4TR1 report is not binding. Changes to technology, scope, and cost are fine as long as the core concept is demonstrated.

## Units (4 committed, 3 lessons each, about 20 questions per unit)

1. Foundations: court layout and zones, the six positions, player roles, basic rules and scoring, service order.
2. Execution: core terminology, communication calls, contact responsibilities, attack and set terminology, common faults.
3. Systems and Strategy: rotational fundamentals, overlap rules, serve receive responsibilities, setter release paths, the transition from offence to defence.
4. Game Mastery: the 5-1 system, scenario-based position switching, reading opponent formations, tactical adjustment by rotation.

Units 5 and 6 are conditional on a clean release candidate by Nov 21:
- Unit 5: the 6-2 system.
- Unit 6: serve receive and defensive formations.

Content is scoped to concepts that the four question types can assess. Physical technique is out of scope.

## Timeline

### Schedule 1: committed, fully offline

| Date | Milestone | Lead |
|---|---|---|
| Sept 22 | Architecture and feature list final; scope lock | Issey / both |
| Sept 24 | Shared repo and conventions | Issey |
| Sept 26 | Content spec: question types, concept tagging, unit outline | Yash |
| Sept 29 | Authoring pipeline: spreadsheet to JSON with schema validation | Issey |
| Oct 1 | App shell (navigation, learning path, local storage); UI/UX direction | Issey; Yash |
| Oct 6 | Unit 1 content; lesson player and question engine; Apple Developer enrolment | Yash; Issey |
| Oct 10 | Court renderer, drag-and-drop rotation questions, haptic snap | Issey |
| Oct 14 | Progress tracking, streaks, unit unlock logic | Issey |
| Oct 15 | Unit 2 content | Yash |
| Oct 16 | Searchable glossary | Issey |
| Oct 18 | Offline verification on a physical device | Yash |
| Oct 20 | Prototype freeze: question types frozen, demo-ready build | Issey |
| Oct 23 | MIDTERM REPORT AND PRESENTATION | Both |
| Oct 31 | Unit 3 content | Yash |
| Nov 7 | User testing sessions; Unit 4 content; audio/haptic pass with toggles | Yash; Issey |
| Nov 10 | Feedback triage; Units 3 and 4 loaded and verified | Yash; Issey |
| Nov 14 | End-of-unit review lessons built from concept tags | Issey |
| Nov 21 | Revisions from testing; conditional Units 5 and 6 | Issey; Yash |
| Nov 24 | Release candidate: feature-frozen offline build | Issey |
| Nov 28 | Final docs, demo recording, presentation prep | Yash |
| Dec 1 | PROJECT COMPLETE | Both |

### Schedule 2: conditional, online features and publication

- Go/no-go checkpoint on Oct 26.
- If any task slips more than 5 days, Schedule 2 stops and the offline app becomes the final deliverable.

The planned Schedule 2 work:
- backend and schema
- accounts and auth
- in-app account deletion (an App Store requirement)
- progress sync
- leaderboards
- asynchronous duels
- TestFlight beta
- privacy policy and App Store assets
- App Store submission on Nov 20
- public release on Nov 30

Publication is iOS only. Google Play requires a 14-day closed test with at least 12 continuous testers before a personal account can publish to production, and that doesn't fit the timeline.

## Key decisions and rationale

- Flutter is kept. Issey owns an M3 Pro MacBook, which removed the main argument for Expo.
- Firebase and PostgreSQL are dropped. The 4TR1 report listed both, which was redundant, and phase one needs no backend at all.
- The app is local-first. Content is bundled at install time, and user data lives in SQLite.
- Online sync must be a retrofit, not a rewrite. That requirement drives these rules:
  - client-generated UUIDs
  - an anonymous local user from first launch
  - `updated_at` timestamps
  - an append-only answer log
  - a data-access layer abstraction
- Content cost is kept separate from engineering cost. Adding a unit costs only authoring time. Engineering cost scales with question types, which are frozen at four on Oct 20.
- Concept tags are independent of unit position. They drive the review lessons, which are how the app delivers the spaced repetition cited in Capstone I.
- The court renderer is the hardest piece of engineering. It is one reusable `CustomPainter` component with display, quiz, and animate modes. No custom illustration work is needed; Procreate is ruled out.
- Audio and haptics are software calls to Flutter's APIs, not hardware integration.
- Budget: $800 is allocated, and realistic spend is about $250 to $350 CAD. Anything over $800 comes out of pocket.

## Open items

- Which 4TR1 game rules survive? The report proposed:
  - 10 errors per 24 hours
  - premium bypass options
  - 100% required on review quizzes, with 2 attempts and a 1-hour wait
  - no exiting a lesson without losing progress

  A premium tier has no meaning offline, and the lockouts would hurt beginners and disrupt user-testing sessions. The suggested fallback is to make these rules configurable and turn them off for testing. This is not decided yet.
- The unit outline needs to be reconciled with Yash before Oct 6. His earlier outline leaned toward physical technique and implied 12 lessons per unit (48 total), while the plan has 12 total.
- A volleyball coach should review the answer key before content is built at scale.
- The 4TR1 report required at least 10 modules. The scope lock of 4 units and 12 lessons supersedes that, and the midterm report should say so explicitly.
- Yash is writing a design requirements doc. When it arrives, save it as `docs/requirements.md` and reconcile it with this file and with `CLAUDE.md`.
- Apple Developer enrolment is planned for Oct 6. It isn't needed for Schedule 1 (demo builds use free provisioning), so it could move to the Oct 26 checkpoint. This is not decided yet.
- User testing sessions (recruit by Oct 28, run by Nov 7) happen in person on the team's own devices. They do not need App Store distribution.
