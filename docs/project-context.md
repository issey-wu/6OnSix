# Project Context

## What I'm building

6 On Six is a mobile app that teaches volleyball the way Duolingo teaches languages: short lessons, instant feedback, a learning path that unlocks as you go, XP, and daily streaks. It's my capstone project for PROCTECH 4TR3 at McMaster, and it continues the concept from Capstone I (4TR1).

The app is for new and intermediate players joining beginner or semi-competitive teams. A lot of players at that level don't know the rules, positions, terminology, or rotations, and teams end up spending practice time explaining them. The app works fully offline, since gyms often have poor Wi-Fi.

## Team

- **Me (Issey Wu):** lead developer. I handle the architecture and app code, and I have the final say on design and content decisions. I've played volleyball at the collegiate level.
- **Yash Dubey:** content authoring, the design spec, user testing, and documentation. Yash is newer to volleyball, which makes him a good test user for the app.
- **Professor:** Tom W. The 4TR1 report isn't binding, so the technology and scope can change as long as the core concept is demonstrated.

## Scope

- Version 1 is fully offline. All content ships with the app, and progress is stored on the device.
- The core content is 4 units of 3 lessons each, about 80 questions, and about 50 glossary terms. Units 5 and 6 are possible later additions.
- The content focuses on the rules and on legality, based on the FIVB 2025-2028 rulebook. Physical technique isn't covered.
- Online features (accounts, sync, leaderboards, duel mode, App Store release) are a possible second phase, decided at the Oct 26 checkpoint.
- If the app is ever published, it will be iOS only.

## Units

1. Court, zones, positions, and roles
2. Rules and terminology
3. Rotations, overlap, and serve receive
4. The 5-1 system

## Key dates

- **Oct 23:** midterm report and presentation, with a working demo.
- **Oct 26:** checkpoint for online features.
- **Dec 1:** project complete.

## Demo

The demo is a complete loop in airplane mode:
1. Open the learning path.
2. Finish a lesson that includes a court question.
3. Look up a term in the glossary.
4. Close and reopen the app, and show that progress was saved.

## Background from Capstone I

- **What players get wrong:** the biggest gap we found was rotations. Players tend to learn only their own position, they get moved up skill levels quickly, and they avoid tactical material because it looks complicated.
- **Existing resources:** YouTube videos are passive, sites like learnvolley.com have no progression or offline mode, and professional analysis tools are too expensive for most players.
- **The approach:** a gamified, bite-sized format with built-in review, similar to Duolingo.

## Reference material

- `docs/design.md`: Yash's design spec, reconciled with my decisions.
- `docs/reference/`: the FIVB rules, the 4TR1 final report, and the 4TR3 project plan.
- The Duolingo Handbook and the FIVB Event Regulations are kept outside the repo.
