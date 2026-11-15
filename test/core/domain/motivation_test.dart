import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/progress.dart';

final _local = DateTime(2026, 11, 14, 12);

void main() {
  test('daily goals match Duolingo: minutes on screen, XP behind it', () {
    expect([for (final g in DailyGoal.values) g.minutes], [5, 10, 15, 20]);
    expect([for (final g in DailyGoal.values) g.xp], [10, 20, 30, 50]);
    expect(const MotivationState().goal, DailyGoal.regular);
  });

  test('a finished lesson adds to today and to the totals', () {
    final state = const MotivationState()
        .recordLesson(
          const LessonResult(
            xp: 15,
            perfect: true,
            isReview: false,
            bestCombo: 4,
            courtCorrect: 2,
            dragFirstTry: 1,
          ),
          local: _local,
          streakNow: 3,
        )
        .recordLesson(
          const LessonResult(
            xp: 20,
            perfect: false,
            isReview: true,
            bestCombo: 2,
            isWeakSpots: true,
          ),
          local: _local,
          streakNow: 3,
        );
    final today = state.statsOn(_local);
    expect(today.xp, 35);
    expect(today.lessons, 2);
    expect(today.perfectLessons, 1);
    expect(today.bestCombo, 4);
    expect(today.courtCorrect, 2);
    expect(today.reviews, 1);
    expect(state.totals.perfectLessons, 1);
    expect(state.totals.dragFirstTry, 1);
    expect(state.totals.weakPractices, 1);
    expect(state.totals.longestStreak, 3);
    expect(state.totals.bestDayXp, 35);
    expect(state.statsOn(DateTime(2026, 11, 15)).xp, 0);
  });

  test('the same day always has the same three quests', () {
    final quests = dailyQuests(_local);
    expect(quests, hasLength(3));
    expect(dailyQuests(DateTime(2026, 11, 14, 23)).map((q) => q.id), [
      for (final q in quests) q.id,
    ]);
    expect(quests.map((q) => q.id).toSet(), hasLength(3));
  });

  test('quest progress is measured against the day, capped at the target', () {
    const quest = Quest(
      id: 'q',
      title: 'Finish 2 lessons',
      metric: QuestMetric.lessons,
      target: 2,
    );
    expect(quest.doneIn(const DayStats(lessons: 1)), isFalse);
    expect(quest.progressIn(const DayStats(lessons: 5)), 2);
    expect(quest.doneIn(const DayStats(lessons: 2)), isTrue);
  });

  test('the third chest is always the XP boost; no freeze when full', () {
    for (var d = 1; d <= 28; d++) {
      final day = dayKey(DateTime(2026, 11, d));
      expect(chestRewardFor(day, 2, freezes: 0), isA<XpBoostReward>());
      for (final index in [0, 1]) {
        expect(
          chestRewardFor(day, index, freezes: maxStreakFreezes),
          isA<BonusXpReward>(),
        );
      }
    }
  });

  test('opening chests counts quests, caps freezes and stacks boosts', () {
    final now = DateTime.utc(2026, 11, 14, 17);
    var state = const MotivationState(freezes: 1)
        .openChest(0, const StreakFreezeReward(), now)
        .openChest(1, const StreakFreezeReward(), now);
    expect(state.freezes, maxStreakFreezes);
    expect(state.chestOpened(now.toLocal(), 0), isTrue);
    expect(state.questsByMonth[monthKey(now.toLocal())], 2);
    expect(state.totals.questsDone, 2);

    state = state.openChest(2, const XpBoostReward(), now);
    expect(state.boostActive(now.add(const Duration(minutes: 14))), isTrue);
    expect(state.boostActive(now.add(const Duration(minutes: 16))), isFalse);

    state = state.openChest(0, const BonusXpReward(15), now);
    expect(state.statsOn(now.toLocal()).xp, 15);
  });

  group('streak freezes', () {
    final progress = const Progress().complete(
      nodeId: 'a',
      xpEarned: 10,
      localNow: DateTime(2026, 11, 10, 18),
    );

    test('cover a missed day automatically and keep the streak', () {
      final result = applyStreakFreezes(
        progress,
        const MotivationState(freezes: 1),
        DateTime(2026, 11, 12, 9),
      );
      expect(result.used, 1);
      expect(result.motivation.freezes, 0);
      expect(result.motivation.freezeDays, {'2026-11-11'});
      expect(result.progress.streakOn(DateTime(2026, 11, 12, 9)), 1);
    });

    test('are not spent when there are too few to save the streak', () {
      final result = applyStreakFreezes(
        progress,
        const MotivationState(freezes: 1),
        DateTime(2026, 11, 13, 9),
      );
      expect(result.used, 0);
      expect(result.motivation.freezes, 1);
    });

    test('are not needed when no day was missed', () {
      final result = applyStreakFreezes(
        progress,
        const MotivationState(freezes: 2),
        DateTime(2026, 11, 11, 9),
      );
      expect(result.used, 0);
    });
  });

  test('saved state survives a round trip through JSON', () {
    final state =
        const MotivationState(
              freezes: 1,
              goalChosen: true,
              streakGoal: 14,
              goal: DailyGoal.serious,
            )
            .recordLesson(
              const LessonResult(xp: 10, perfect: true, isReview: false),
              local: _local,
              streakNow: 2,
            )
            .recordGlossaryView('libero', _local)
            .openChest(
              2,
              const XpBoostReward(),
              DateTime.utc(2026, 11, 14, 17),
            );
    final json = state.toJson();
    final back = motivationFromJson(
      jsonDecode(jsonEncode(json)) as Map<String, Object?>,
    );
    expect(back.toJson(), json);
    expect(motivationFromJson(const {}).goal, DailyGoal.regular);
  });
}
