import 'dart:math';

import 'package:meta/meta.dart';
import 'package:six_on_six/core/domain/progress.dart';

// The motivation layer: daily goal, streak freezes and milestones, daily
// quests with chests, and the XP boost. The rules follow Duolingo's own as
// closely as an offline app allows; see docs/decisions.md.

/// Daily goal levels, shown to learners as minutes a day.
enum DailyGoal { casual, regular, serious, intense }

extension DailyGoalInfo on DailyGoal {
  String get label => switch (this) {
    DailyGoal.casual => 'Casual',
    DailyGoal.regular => 'Regular',
    DailyGoal.serious => 'Serious',
    DailyGoal.intense => 'Intense',
  };

  /// Minutes a day, as shown on the goal screen.
  int get minutes => switch (this) {
    DailyGoal.casual => 5,
    DailyGoal.regular => 10,
    DailyGoal.serious => 15,
    DailyGoal.intense => 20,
  };

  /// The XP a day that counts as meeting the goal.
  int get xp => switch (this) {
    DailyGoal.casual => 10,
    DailyGoal.regular => 20,
    DailyGoal.serious => 30,
    DailyGoal.intense => 50,
  };
}

/// Streak lengths that get a celebration and a free streak freeze.
const streakMilestones = [7, 30, 100, 365];

/// The most streak freezes a learner can hold at once.
const maxStreakFreezes = 2;

/// Monthly challenge: this many quests in a month earns the month's badge.
const monthlyQuestTarget = 20;

/// How long a chest's XP boost lasts.
const xpBoostLength = Duration(minutes: 15);

/// A calendar day as "2026-11-14", from a device-local time.
String dayKey(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

/// A month as "2026-11", from a device-local time.
String monthKey(DateTime local) => dayKey(local).substring(0, 7);

/// What a learner did on one day. Quests and the daily goal are measured
/// against this.
@immutable
class DayStats {
  const new({
    this.xp = 0,
    this.lessons = 0,
    this.perfectLessons = 0,
    this.bestCombo = 0,
    this.glossaryViews = 0,
    this.courtCorrect = 0,
    this.reviews = 0,
  });

  /// XP earned today, including chest bonuses.
  final int xp;
  final int lessons;
  final int perfectLessons;

  /// Most answers right in a row in one lesson.
  final int bestCombo;
  final int glossaryViews;

  /// Tap-the-zone and drag-and-drop questions answered right first try.
  final int courtCorrect;

  /// Reviews and weak spots practices finished.
  final int reviews;

  DayStats copyWith({
    int? xp,
    int? lessons,
    int? perfectLessons,
    int? bestCombo,
    int? glossaryViews,
    int? courtCorrect,
    int? reviews,
  }) => DayStats(
    xp: xp ?? this.xp,
    lessons: lessons ?? this.lessons,
    perfectLessons: perfectLessons ?? this.perfectLessons,
    bestCombo: bestCombo ?? this.bestCombo,
    glossaryViews: glossaryViews ?? this.glossaryViews,
    courtCorrect: courtCorrect ?? this.courtCorrect,
    reviews: reviews ?? this.reviews,
  );

  Map<String, Object?> toJson() => {
    'xp': xp,
    'lessons': lessons,
    'perfectLessons': perfectLessons,
    'bestCombo': bestCombo,
    'glossaryViews': glossaryViews,
    'courtCorrect': courtCorrect,
    'reviews': reviews,
  };
}

DayStats _dayStatsFromJson(Map<String, Object?> json) => DayStats(
  xp: json['xp'] as int? ?? 0,
  lessons: json['lessons'] as int? ?? 0,
  perfectLessons: json['perfectLessons'] as int? ?? 0,
  bestCombo: json['bestCombo'] as int? ?? 0,
  glossaryViews: json['glossaryViews'] as int? ?? 0,
  courtCorrect: json['courtCorrect'] as int? ?? 0,
  reviews: json['reviews'] as int? ?? 0,
);

/// What one finished lesson, review or practice adds to the day.
@immutable
class LessonResult {
  const new({
    required this.xp,
    required this.perfect,
    required this.isReview,
    this.bestCombo = 0,
    this.courtCorrect = 0,
    this.dragFirstTry = 0,
    this.isWeakSpots = false,
  });

  final int xp;
  final bool perfect;

  /// A unit review, the final review or a weak spots practice.
  final bool isReview;
  final int bestCombo;
  final int courtCorrect;
  final int dragFirstTry;
  final bool isWeakSpots;
}

/// Running totals kept for achievements (Round 2b).
@immutable
class MotivationTotals {
  const new({
    this.perfectLessons = 0,
    this.dragFirstTry = 0,
    this.weakPractices = 0,
    this.questsDone = 0,
    this.longestStreak = 0,
    this.bestDayXp = 0,
  });

  final int perfectLessons;
  final int dragFirstTry;
  final int weakPractices;
  final int questsDone;
  final int longestStreak;
  final int bestDayXp;

  MotivationTotals copyWith({
    int? perfectLessons,
    int? dragFirstTry,
    int? weakPractices,
    int? questsDone,
    int? longestStreak,
    int? bestDayXp,
  }) => MotivationTotals(
    perfectLessons: perfectLessons ?? this.perfectLessons,
    dragFirstTry: dragFirstTry ?? this.dragFirstTry,
    weakPractices: weakPractices ?? this.weakPractices,
    questsDone: questsDone ?? this.questsDone,
    longestStreak: longestStreak ?? this.longestStreak,
    bestDayXp: bestDayXp ?? this.bestDayXp,
  );

  Map<String, Object?> toJson() => {
    'perfectLessons': perfectLessons,
    'dragFirstTry': dragFirstTry,
    'weakPractices': weakPractices,
    'questsDone': questsDone,
    'longestStreak': longestStreak,
    'bestDayXp': bestDayXp,
  };
}

MotivationTotals _totalsFromJson(Map<String, Object?> json) => MotivationTotals(
  perfectLessons: json['perfectLessons'] as int? ?? 0,
  dragFirstTry: json['dragFirstTry'] as int? ?? 0,
  weakPractices: json['weakPractices'] as int? ?? 0,
  questsDone: json['questsDone'] as int? ?? 0,
  longestStreak: json['longestStreak'] as int? ?? 0,
  bestDayXp: json['bestDayXp'] as int? ?? 0,
);

/// Everything the motivation layer remembers. Saved on the device as one
/// JSON document.
@immutable
class MotivationState {
  const new({
    this.goal = DailyGoal.regular,
    this.goalChosen = false,
    this.streakGoal,
    this.freezes = 0,
    this.freezeDays = const {},
    this.boostUntil,
    this.days = const {},
    this.chestsOpened = const {},
    this.questsByMonth = const {},
    this.milestones = const {},
    this.glossaryViewed = const {},
    this.totals = const MotivationTotals(),
  });

  final DailyGoal goal;

  /// False until the learner has picked a goal after their first lesson.
  final bool goalChosen;

  /// The streak the learner committed to: 7, 14 or 30 days, or none.
  final int? streakGoal;

  /// Streak freezes held, from 0 to [maxStreakFreezes].
  final int freezes;

  /// Days a freeze covered, as [dayKey]s.
  final Set<String> freezeDays;

  /// When the current double-XP boost ends (UTC), if one was opened.
  final DateTime? boostUntil;

  /// Stats per day, keyed by [dayKey]. Only recent days are kept.
  final Map<String, DayStats> days;

  /// Chests opened per day: the indexes of that day's quests.
  final Map<String, Set<int>> chestsOpened;

  /// Quests finished per month, keyed by [monthKey].
  final Map<String, int> questsByMonth;

  /// Streak milestones already celebrated.
  final Set<int> milestones;

  /// Glossary terms ever opened.
  final Set<String> glossaryViewed;
  final MotivationTotals totals;

  static const _keepDays = 60;

  DayStats statsOn(DateTime local) => days[dayKey(local)] ?? const DayStats();

  bool boostActive(DateTime now) {
    final until = boostUntil;
    return until != null && now.toUtc().isBefore(until);
  }

  MotivationState copyWith({
    DailyGoal? goal,
    bool? goalChosen,
    int? streakGoal,
    bool clearStreakGoal = false,
    int? freezes,
    Set<String>? freezeDays,
    DateTime? boostUntil,
    Map<String, DayStats>? days,
    Map<String, Set<int>>? chestsOpened,
    Map<String, int>? questsByMonth,
    Set<int>? milestones,
    Set<String>? glossaryViewed,
    MotivationTotals? totals,
  }) => MotivationState(
    goal: goal ?? this.goal,
    goalChosen: goalChosen ?? this.goalChosen,
    streakGoal: clearStreakGoal ? null : (streakGoal ?? this.streakGoal),
    freezes: freezes ?? this.freezes,
    freezeDays: freezeDays ?? this.freezeDays,
    boostUntil: boostUntil ?? this.boostUntil,
    days: days ?? this.days,
    chestsOpened: chestsOpened ?? this.chestsOpened,
    questsByMonth: questsByMonth ?? this.questsByMonth,
    milestones: milestones ?? this.milestones,
    glossaryViewed: glossaryViewed ?? this.glossaryViewed,
    totals: totals ?? this.totals,
  );

  /// Clears progress-related stats but keeps the learner's goal choices.
  MotivationState resetStats() => MotivationState(
    goal: goal,
    goalChosen: goalChosen,
    streakGoal: streakGoal,
  );

  MotivationState _withDay(DateTime local, DayStats stats) {
    final next = {...days, dayKey(local): stats};
    if (next.length > _keepDays) {
      final keys = next.keys.toList()..sort();
      keys.take(next.length - _keepDays).forEach(next.remove);
    }
    return copyWith(
      days: next,
      totals: totals.copyWith(bestDayXp: max(totals.bestDayXp, stats.xp)),
    );
  }

  /// Adds a finished lesson to today's stats and the running totals.
  MotivationState recordLesson(
    LessonResult result, {
    required DateTime local,
    required int streakNow,
  }) {
    final today = statsOn(local);
    final next = _withDay(
      local,
      today.copyWith(
        xp: today.xp + result.xp,
        lessons: today.lessons + 1,
        perfectLessons: today.perfectLessons + (result.perfect ? 1 : 0),
        bestCombo: max(today.bestCombo, result.bestCombo),
        courtCorrect: today.courtCorrect + result.courtCorrect,
        reviews: today.reviews + (result.isReview ? 1 : 0),
      ),
    );
    final t = next.totals;
    return next.copyWith(
      totals: t.copyWith(
        perfectLessons: t.perfectLessons + (result.perfect ? 1 : 0),
        dragFirstTry: t.dragFirstTry + result.dragFirstTry,
        weakPractices: t.weakPractices + (result.isWeakSpots ? 1 : 0),
        longestStreak: max(t.longestStreak, streakNow),
      ),
    );
  }

  /// Adds bonus XP from a chest to today's total.
  MotivationState addBonusXp(int xp, DateTime local) {
    final today = statsOn(local);
    return _withDay(local, today.copyWith(xp: today.xp + xp));
  }

  MotivationState recordGlossaryView(String termId, DateTime local) {
    final today = statsOn(local);
    return _withDay(
      local,
      today.copyWith(glossaryViews: today.glossaryViews + 1),
    ).copyWith(glossaryViewed: {...glossaryViewed, termId});
  }

  bool chestOpened(DateTime local, int index) =>
      chestsOpened[dayKey(local)]?.contains(index) ?? false;

  /// Marks a chest opened, counts its quest toward the monthly challenge,
  /// and applies a freeze or boost reward. Bonus XP is added by the caller,
  /// since it also changes the learner's total XP.
  MotivationState openChest(int index, ChestReward reward, DateTime now) {
    final local = now.toLocal();
    final key = dayKey(local);
    final month = monthKey(local);
    var next = copyWith(
      chestsOpened: {
        ...chestsOpened,
        key: {...?chestsOpened[key], index},
      },
      questsByMonth: {...questsByMonth, month: (questsByMonth[month] ?? 0) + 1},
      totals: totals.copyWith(questsDone: totals.questsDone + 1),
    );
    switch (reward) {
      case StreakFreezeReward():
        next = next.copyWith(freezes: min(maxStreakFreezes, freezes + 1));
      case XpBoostReward(:final length):
        final current = boostUntil;
        final from = current != null && now.toUtc().isBefore(current)
            ? current
            : now.toUtc();
        next = next.copyWith(boostUntil: from.add(length));
      case BonusXpReward(:final xp):
        next = next.addBonusXp(xp, local);
    }
    return next;
  }

  Map<String, Object?> toJson() => {
    'goal': goal.name,
    'goalChosen': goalChosen,
    'streakGoal': streakGoal,
    'freezes': freezes,
    'freezeDays': freezeDays.toList()..sort(),
    'boostUntil': boostUntil?.toUtc().toIso8601String(),
    'days': {for (final e in days.entries) e.key: e.value.toJson()},
    'chestsOpened': {
      for (final e in chestsOpened.entries) e.key: e.value.toList()..sort(),
    },
    'questsByMonth': questsByMonth,
    'milestones': milestones.toList()..sort(),
    'glossaryViewed': glossaryViewed.toList()..sort(),
    'totals': totals.toJson(),
  };
}

/// Reads a saved [MotivationState]. Missing fields fall back to defaults.
MotivationState motivationFromJson(Map<String, Object?> json) {
  Map<String, Object?> map(Object? value) =>
      (value as Map<String, Object?>?) ?? const {};
  List<Object?> list(Object? value) => (value as List<Object?>?) ?? const [];
  final boost = json['boostUntil'] as String?;
  return MotivationState(
    goal: DailyGoal.values.firstWhere(
      (g) => g.name == json['goal'],
      orElse: () => DailyGoal.regular,
    ),
    goalChosen: json['goalChosen'] as bool? ?? false,
    streakGoal: json['streakGoal'] as int?,
    freezes: json['freezes'] as int? ?? 0,
    freezeDays: {for (final d in list(json['freezeDays'])) d! as String},
    boostUntil: boost == null ? null : DateTime.parse(boost).toUtc(),
    days: {
      for (final e in map(json['days']).entries)
        e.key: _dayStatsFromJson(map(e.value)),
    },
    chestsOpened: {
      for (final e in map(json['chestsOpened']).entries)
        e.key: {for (final i in list(e.value)) i! as int},
    },
    questsByMonth: {
      for (final e in map(json['questsByMonth']).entries)
        e.key: e.value! as int,
    },
    milestones: {for (final m in list(json['milestones'])) m! as int},
    glossaryViewed: {
      for (final t in list(json['glossaryViewed'])) t! as String,
    },
    totals: _totalsFromJson(map(json['totals'])),
  );
}

/// What a chest gives.
sealed class ChestReward {
  const new();
}

final class BonusXpReward extends ChestReward {
  const new(this.xp);

  final int xp;
}

final class StreakFreezeReward extends ChestReward {
  const new();
}

final class XpBoostReward extends ChestReward {
  const new([this.length = xpBoostLength]);

  final Duration length;
}

/// The reward in chest [index] (0, 1 or 2) on [day]. The third, hardest
/// quest always gives the XP boost, like Duolingo's gold chest. The others
/// give bonus XP, or sometimes a streak freeze when there is room for one.
ChestReward chestRewardFor(String day, int index, {required int freezes}) {
  if (index >= 2) return const XpBoostReward();
  final random = Random(_seed(day) * 7 + index);
  if (freezes < maxStreakFreezes && random.nextInt(3) == 0) {
    return const StreakFreezeReward();
  }
  return BonusXpReward(random.nextBool() ? 10 : 15);
}

/// What today's quest measures.
enum QuestMetric {
  xp,
  lessons,
  perfectLessons,
  combo,
  glossaryViews,
  courtCorrect,
  reviews,
}

/// One daily quest, measured against [DayStats].
@immutable
class Quest {
  const new({
    required this.id,
    required this.title,
    required this.metric,
    required this.target,
  });

  final String id;
  final String title;
  final QuestMetric metric;
  final int target;

  int valueIn(DayStats stats) => switch (metric) {
    QuestMetric.xp => stats.xp,
    QuestMetric.lessons => stats.lessons,
    QuestMetric.perfectLessons => stats.perfectLessons,
    QuestMetric.combo => stats.bestCombo,
    QuestMetric.glossaryViews => stats.glossaryViews,
    QuestMetric.courtCorrect => stats.courtCorrect,
    QuestMetric.reviews => stats.reviews,
  };

  /// Progress toward [target], never above it.
  int progressIn(DayStats stats) => min(valueIn(stats), target);

  bool doneIn(DayStats stats) => valueIn(stats) >= target;
}

const _easyQuests = [
  Quest(id: 'xp10', title: 'Earn 10 XP', metric: QuestMetric.xp, target: 10),
  Quest(
    id: 'lesson1',
    title: 'Finish 1 lesson',
    metric: QuestMetric.lessons,
    target: 1,
  ),
  Quest(
    id: 'terms2',
    title: 'Look up 2 glossary terms',
    metric: QuestMetric.glossaryViews,
    target: 2,
  ),
  Quest(
    id: 'combo3',
    title: 'Get 3 answers right in a row',
    metric: QuestMetric.combo,
    target: 3,
  ),
];

const _mediumQuests = [
  Quest(id: 'xp30', title: 'Earn 30 XP', metric: QuestMetric.xp, target: 30),
  Quest(
    id: 'lesson2',
    title: 'Finish 2 lessons',
    metric: QuestMetric.lessons,
    target: 2,
  ),
  Quest(
    id: 'combo5',
    title: 'Get 5 answers right in a row',
    metric: QuestMetric.combo,
    target: 5,
  ),
  Quest(
    id: 'court3',
    title: 'Get 3 court questions right first try',
    metric: QuestMetric.courtCorrect,
    target: 3,
  ),
];

const _hardQuests = [
  Quest(
    id: 'perfect1',
    title: 'Finish a lesson with no mistakes',
    metric: QuestMetric.perfectLessons,
    target: 1,
  ),
  Quest(id: 'xp50', title: 'Earn 50 XP', metric: QuestMetric.xp, target: 50),
  Quest(
    id: 'combo8',
    title: 'Get 8 answers right in a row',
    metric: QuestMetric.combo,
    target: 8,
  ),
  Quest(
    id: 'review1',
    title: 'Finish a review or weak spots practice',
    metric: QuestMetric.reviews,
    target: 1,
  ),
];

int _seed(String day) =>
    day.codeUnits.fold(17, (hash, unit) => (hash * 31 + unit) & 0x7fffffff);

/// Today's three quests, easy to hard. The same day always gives the same
/// quests, so they don't change when the app restarts.
List<Quest> dailyQuests(DateTime local) {
  final random = Random(_seed(dayKey(local)));
  return [
    _easyQuests[random.nextInt(_easyQuests.length)],
    _mediumQuests[random.nextInt(_mediumQuests.length)],
    _hardQuests[random.nextInt(_hardQuests.length)],
  ];
}

/// The result of covering missed days with streak freezes.
typedef FreezeResult = ({
  Progress progress,
  MotivationState motivation,
  int used,
});

/// Covers days missed since the last lesson with streak freezes, so the
/// streak survives. Freezes apply automatically, like Duolingo's: only if
/// there are enough to cover every missed day; otherwise none are spent and
/// the streak is lost as usual.
FreezeResult applyStreakFreezes(
  Progress progress,
  MotivationState motivation,
  DateTime localNow,
) {
  final last = progress.lastActiveDay;
  final today = DateTime.utc(localNow.year, localNow.month, localNow.day);
  final unchanged = (progress: progress, motivation: motivation, used: 0);
  if (last == null || progress.streak == 0) return unchanged;
  final missed = today.difference(last).inDays - 1;
  if (missed <= 0 || motivation.freezes < missed) return unchanged;
  final covered = {
    for (var i = 1; i <= missed; i++) dayKey(last.add(Duration(days: i))),
  };
  return (
    progress: progress.withLastActiveDay(
      today.subtract(const Duration(days: 1)),
    ),
    motivation: motivation.copyWith(
      freezes: motivation.freezes - missed,
      freezeDays: {...motivation.freezeDays, ...covered},
    ),
    used: missed,
  );
}
