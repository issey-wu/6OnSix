import 'dart:math';

// What Ace says. He is playful and a bit cheeky, talks volleyball, and
// keeps it short enough to read at a glance. Each moment has a few lines,
// picked at random so he doesn't repeat himself every time.

String _pick(Random random, List<String> lines) =>
    lines[random.nextInt(lines.length)];

/// On the welcome screen, the first time the app opens.
const aceHello = "Hey! I'm Ace. Let's get you game-ready.";

/// On the daily goal screen.
const aceGoalQuestion = 'How much time can you give me each day?';

/// After [count] right answers in a row during a lesson, or null when that
/// count isn't worth a cheer.
String? aceCombo(Random random, int count) => switch (count) {
  3 => _pick(random, const [
    '3 in a row! Okay, show-off.',
    '3 in a row! Somebody call the scouts.',
    'Three straight. Are you reading my notes?',
  ]),
  5 => _pick(random, const [
    '5 in a row! I need to sit down.',
    "Five straight! You're on a heater.",
    '5 in a row. Leave some points for the rest of us.',
  ]),
  >= 8 when count % 4 == 0 => _pick(random, [
    '$count in a row?! Who taught you? Oh right, me.',
    '$count straight. The other team wants a timeout.',
  ]),
  _ => null,
};

/// After the first wrong answer in a lesson.
String aceFirstMistake(Random random) => _pick(random, const [
  'Shank happens. Next ball!',
  "Oops. We'll call that a practice swing.",
  'That one comes back at the end. Revenge time.',
  'Shake it off. Even pros miss serves.',
]);

/// After two wrong answers in a row.
String aceToughRally(Random random) => _pick(random, const [
  "Tough rally. You've got this.",
  'Deep breath. Read it one more time.',
  'The net is not your friend today. Next ball!',
]);

/// When only one question is left.
String aceLastOne(Random random) => _pick(random, const [
  'Match point! Bring it home.',
  'Last one. No pressure. Okay, a little pressure.',
]);

/// On the lesson complete screen.
String aceLessonDone(
  Random random, {
  required bool perfect,
  required bool review,
  required int streak,
  required bool streakGrew,
  required bool milestone,
}) {
  if (milestone) return '$streak days?! Legend status.';
  if (streakGrew && streak == 1) {
    return "Day one! Come back tomorrow. I'll be waiting. Watching.";
  }
  if (streakGrew) {
    return _pick(random, [
      "Day $streak! I'm not crying, you're crying.",
      "$streak days in a row. Don't you dare stop now.",
      "Streak's at $streak. I'm so proud I could molt.",
    ]);
  }
  if (perfect) {
    return _pick(random, const [
      'Perfect! Not a single ball dropped.',
      'Flawless. Should I be worried about my job?',
      'Zero mistakes. Show-off.',
    ]);
  }
  if (review) {
    return _pick(random, const [
      'Review done. Your brain says thanks.',
      "All warmed up. That stuff's sticking now.",
    ]);
  }
  return _pick(random, const [
    'Lesson done! Look at you go.',
    "That's game! Nice work.",
    'Done and dusted. Same time tomorrow?',
  ]);
}

/// When the learner taps Ace on the Learn tab.
String aceOnPath(
  Random random, {
  required int streak,
  required bool practisedToday,
  required bool goalMet,
  required bool lostStreak,
}) {
  if (lostStreak) {
    return _pick(random, const [
      "Our streak... it's gone. I'm fine. Totally fine.",
      "New streak starts today. I'm not asking, I'm telling.",
    ]);
  }
  if (goalMet) {
    return _pick(random, const [
      'Goal done for today. Look at you!',
      "You hit your goal. One more? I won't stop you.",
    ]);
  }
  if (streak > 0 && !practisedToday) {
    return _pick(random, [
      'Your $streak-day streak is waiting. Just saying.',
      'One lesson keeps the streak alive. Tick tock.',
    ]);
  }
  return _pick(random, const [
    'Ready to serve?',
    'Tap the glowing lesson. I believe in you.',
    "Fun fact: I can't actually play. No hands.",
    'Eagles make terrible liberos. Too much flapping.',
    'Bump, set, learn!',
  ]);
}

/// On the league results sheet.
String aceLeague({required bool promoted, required bool demoted}) => promoted
    ? 'Moving up! Pack your bags.'
    : demoted
    ? "We'll climb back. Together. Starting now."
    : 'Held your spot. Next week we climb.';
