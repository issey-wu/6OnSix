import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/achievements.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/progress.dart';

Lesson _lesson(String id) =>
    Lesson(id: id, title: id, cards: const [], questions: const []);

final _course = Course(
  schemaVersion: 1,
  units: [
    for (var u = 1; u <= 4; u++)
      Unit(
        id: 'u$u',
        title: 'Unit $u',
        description: '',
        lessons: [for (var l = 1; l <= 3; l++) _lesson('u$u.l$l')],
      ),
  ],
);

Achievement _badge(AchievementKind kind) =>
    achievementsFor(_course).firstWhere((a) => a.kind == kind);

void main() {
  test('every badge has four rising levels', () {
    for (final a in achievementsFor(_course)) {
      expect(a.levels, hasLength(4), reason: a.title);
      for (var i = 1; i < 4; i++) {
        expect(a.levels[i], greaterThan(a.levels[i - 1]), reason: a.title);
      }
    }
  });

  test('the lesson and unit badges top out at the whole course', () {
    expect(_badge(AchievementKind.lessons).levels.last, 12);
    expect(_badge(AchievementKind.units).levels.last, 4);
  });

  test('a level is reached at its total, not before', () {
    final streak = _badge(AchievementKind.streak);
    expect(streak.levelFor(2), 0);
    expect(streak.levelFor(3), 1);
    expect(streak.levelFor(29), 3);
    expect(streak.levelFor(400), 4);
    expect(streak.goalFor(2), 'Reach a 7 day streak');
  });

  test('stats come from saved progress, with the best streak kept', () {
    final stats = AchievementStats.from(
      progress: const Progress(
        completed: {'u1.l1', 'u1.l2', 'u1.l3', 'u1.review'},
        xp: 320,
        streak: 2,
      ),
      motivation: const MotivationState(
        glossaryViewed: {'a', 'b', 'c', 'd', 'e'},
        totals: MotivationTotals(
          perfectLessons: 3,
          longestStreak: 8,
          questsDone: 4,
        ),
      ),
      course: _course,
    );
    expect(stats.countOf(AchievementKind.streak), 8);
    expect(stats.countOf(AchievementKind.lessons), 3);
    expect(stats.countOf(AchievementKind.units), 1);
    expect(stats.levelOf(_badge(AchievementKind.xp)), 2);
    expect(stats.levelOf(_badge(AchievementKind.words)), 1);
    expect(stats.levelOf(_badge(AchievementKind.weak)), 0);
  });

  test('only badges that went up a level count as earned', () {
    const before = AchievementStats({
      AchievementKind.xp: 90,
      AchievementKind.lessons: 1,
    });
    const after = AchievementStats({
      AchievementKind.xp: 110,
      AchievementKind.lessons: 2,
    });
    final earned = badgesEarned(achievementsFor(_course), before, after);
    expect(earned, hasLength(1));
    expect(earned.single.achievement.kind, AchievementKind.xp);
    expect(earned.single.level, 1);
  });
}
