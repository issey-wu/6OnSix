import 'dart:math';

import 'package:meta/meta.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/progress.dart';

// Achievement badges, in the style of Duolingo's: each badge has four
// levels, and the next level is always in sight. Everything is worked out
// from progress the app already keeps, so no new data is stored.

/// What a badge counts.
enum AchievementKind {
  streak,
  xp,
  lessons,
  perfect,
  units,
  quests,
  words,
  weak,
}

/// One badge and the totals it takes to reach each of its levels.
@immutable
class Achievement {
  const new({
    required this.kind,
    required this.title,
    required this.levels,
    required this.goal,
  });

  final AchievementKind kind;
  final String title;

  /// The total needed for level 1, 2, 3 and 4, smallest first.
  final List<int> levels;

  /// What to do for a level, with `{n}` for the total, such as
  /// "Reach a {n} day streak".
  final String goal;

  /// The level reached with [count]: 0 before the first, up to
  /// [levels].length.
  int levelFor(int count) => levels.where((n) => count >= n).length;

  /// The goal for [level] (counting from 1), written out.
  String goalFor(int level) =>
      goal.replaceAll('{n}', '${levels[min(level, levels.length) - 1]}');
}

/// The badges, in the order they're shown. The lesson and unit badges top
/// out at the whole course, so finishing everything earns their last level.
List<Achievement> achievementsFor(Course course) {
  final lessons = course.units.fold(0, (n, u) => n + u.lessons.length);
  final units = course.units.length;
  return [
    const Achievement(
      kind: AchievementKind.streak,
      title: 'On fire',
      levels: [3, 7, 14, 30],
      goal: 'Reach a {n} day streak',
    ),
    const Achievement(
      kind: AchievementKind.xp,
      title: 'Point scorer',
      levels: [100, 300, 600, 1000],
      goal: 'Earn {n} XP',
    ),
    Achievement(
      kind: AchievementKind.lessons,
      title: 'Student of the game',
      levels: _spread(lessons, const [1, 4, 8]),
      goal: 'Finish {n} lessons',
    ),
    const Achievement(
      kind: AchievementKind.perfect,
      title: 'Perfect set',
      levels: [1, 3, 6, 10],
      goal: 'Finish {n} lessons with no mistakes',
    ),
    Achievement(
      kind: AchievementKind.units,
      title: 'Court general',
      levels: _spread(units, const [1, 2, 3]),
      goal: 'Finish {n} units',
    ),
    const Achievement(
      kind: AchievementKind.quests,
      title: 'Quest hunter',
      levels: [3, 10, 25, 50],
      goal: 'Finish {n} daily quests',
    ),
    const Achievement(
      kind: AchievementKind.words,
      title: 'Word collector',
      levels: [5, 15, 30, 60],
      goal: 'Look up {n} glossary words',
    ),
    const Achievement(
      kind: AchievementKind.weak,
      title: 'Comeback kid',
      levels: [1, 3, 6, 10],
      goal: 'Practise your weak spots {n} times',
    ),
  ];
}

/// [first] levels, then [total], each a different total. A small course
/// fills the gaps from the top down; one with fewer than 4 lessons or
/// units gets fewer levels rather than two levels at the same total.
List<int> _spread(int total, List<int> first) {
  final levels = {
    for (final n in first)
      if (n < total) n,
    total,
  }.toList();
  for (var n = total - 1; levels.length < 4 && n >= 1; n--) {
    if (!levels.contains(n)) levels.add(n);
  }
  return levels..sort();
}

/// The totals the badges count, from the learner's saved progress.
@immutable
class AchievementStats {
  const new(this.counts);

  factory from({
    required Progress progress,
    required MotivationState motivation,
    required Course course,
  }) {
    final totals = motivation.totals;
    return AchievementStats({
      AchievementKind.streak: max(totals.longestStreak, progress.streak),
      AchievementKind.xp: progress.xp,
      AchievementKind.lessons: course.units
          .expand((u) => u.lessons)
          .where((l) => progress.completed.contains(l.id))
          .length,
      AchievementKind.perfect: totals.perfectLessons,
      AchievementKind.units: course.units
          .where((u) => progress.completed.contains(u.reviewId))
          .length,
      AchievementKind.quests: totals.questsDone,
      AchievementKind.words: motivation.glossaryViewed.length,
      AchievementKind.weak: totals.weakPractices,
    });
  }

  final Map<AchievementKind, int> counts;

  int countOf(AchievementKind kind) => counts[kind] ?? 0;

  /// The level [achievement] has reached.
  int levelOf(Achievement achievement) =>
      achievement.levelFor(countOf(achievement.kind));
}

/// A badge that went up a level, and the level it reached.
typedef BadgeUp = ({Achievement achievement, int level});

/// The badges that went up a level between [before] and [after].
List<BadgeUp> badgesEarned(
  List<Achievement> achievements,
  AchievementStats before,
  AchievementStats after,
) => [
  for (final a in achievements)
    if (after.levelOf(a) > before.levelOf(a))
      (achievement: a, level: after.levelOf(a)),
];
