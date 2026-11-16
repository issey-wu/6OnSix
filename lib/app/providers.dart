import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/logger.dart';
import 'package:six_on_six/core/data/asset_content_repository.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/avatar.dart';
import 'package:six_on_six/core/domain/clock.dart';
import 'package:six_on_six/core/domain/content_repository.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/game_rules.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/progress_repository.dart';
import 'package:six_on_six/core/domain/user_state.dart';

const _logger = AppLogger('providers');

/// How far the developer menu has moved the app's clock forward. Always
/// zero unless someone uses the developer menu.
final clockShiftProvider = NotifierProvider<ClockShiftController, Duration>(
  ClockShiftController.new,
);

class ClockShiftController extends Notifier<Duration> {
  @override
  Duration build() => Duration.zero;

  /// Moves the app's clock forward, for testing streaks.
  void addDays(int days) => state += Duration(days: days);

  void reset() => state = Duration.zero;
}

/// The time source for all app logic. Override in tests to control time.
final clockProvider = Provider<Clock>((ref) {
  final shift = ref.watch(clockShiftProvider);
  return shift == Duration.zero
      ? const SystemClock()
      : ShiftedClock(const SystemClock(), shift);
});

/// Game-rule parameters. Override to change rules (e.g. for user testing).
final gameRulesProvider = Provider<GameRules>((ref) => const GameRules());

/// Where learning content comes from.
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => AssetContentRepository(),
);

/// The bundled course, loaded once.
final courseProvider = FutureProvider<Course>(
  (ref) => ref.watch(contentRepositoryProvider).loadCourse(),
);

/// Where progress and settings are saved. bootstrap() overrides this with
/// the on-device database; tests use the in-memory default.
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => InMemoryProgressRepository(),
);

/// The saved state read at start-up. bootstrap() overrides this.
final initialStateProvider = Provider<StoredState>(
  (ref) => const StoredState(),
);

/// Saves in the background and logs failures, so a storage problem never
/// blocks the learner.
void _save(Future<void> future, String what) {
  unawaited(
    future.catchError((Object error, StackTrace stack) {
      _logger.error('Could not save $what', error: error, stackTrace: stack);
    }),
  );
}

final progressProvider = NotifierProvider<ProgressController, Progress>(
  ProgressController.new,
);

/// What a finished lesson earned, for the lesson complete screen.
class LessonOutcome {
  const new({
    required this.xp,
    required this.boosted,
    required this.todayXp,
    required this.goal,
    required this.goalJustMet,
    required this.questsJustDone,
    this.milestone,
  });

  final int xp;

  /// True when a double-XP boost doubled [xp].
  final bool boosted;

  /// XP earned so far today, including this lesson.
  final int todayXp;
  final DailyGoal goal;

  /// True when this lesson took today's XP past the daily goal.
  final bool goalJustMet;

  /// Today's quests that this lesson finished.
  final List<Quest> questsJustDone;

  /// The streak milestone reached by this lesson (7, 30, 100 or 365 days),
  /// if any. Each one gives a free streak freeze.
  final int? milestone;
}

class ProgressController extends Notifier<Progress> {
  @override
  Progress build() => ref.read(initialStateProvider).progress;

  DateTime get _now => ref.read(clockProvider).now();

  /// Covers missed days with streak freezes, if any are held. Runs when the
  /// app opens and before every completion.
  int checkStreakFreezes() {
    final motivation = ref.read(motivationProvider.notifier);
    final result = applyStreakFreezes(
      state,
      ref.read(motivationProvider),
      _now.toLocal(),
    );
    if (result.used == 0) return 0;
    state = result.progress;
    motivation.replace(result.motivation);
    _save(ref.read(progressRepositoryProvider).saveProgress(state), 'freeze');
    return result.used;
  }

  /// Records a finished lesson, review or practice and returns what it
  /// earned. XP doubles while a chest's XP boost is active.
  LessonOutcome complete({
    required String nodeId,
    required bool isReview,
    required bool perfect,
    List<AnswerAttempt> answers = const [],
    int bestCombo = 0,
    int courtCorrect = 0,
    int dragFirstTry = 0,
    bool isWeakSpots = false,
  }) {
    checkStreakFreezes();
    final now = _now;
    final local = now.toLocal();
    final motivation = ref.read(motivationProvider);
    final boosted = motivation.boostActive(now);
    final baseXp = ref
        .read(gameRulesProvider)
        .xpFor(isReview: isReview, perfect: perfect);
    final xp = boosted ? baseXp * 2 : baseXp;
    state = state.complete(nodeId: nodeId, xpEarned: xp, localNow: local);
    ref.read(answerStatsProvider.notifier).record(answers);
    _save(
      ref
          .read(progressRepositoryProvider)
          .recordCompletion(
            nodeId: nodeId,
            perfect: perfect,
            xpEarned: xp,
            answers: answers,
            updated: state,
          ),
      'lesson completion',
    );
    return ref
        .read(motivationProvider.notifier)
        .recordLesson(
          LessonResult(
            xp: xp,
            perfect: perfect,
            isReview: isReview,
            bestCombo: bestCombo,
            courtCorrect: courtCorrect,
            dragFirstTry: dragFirstTry,
            isWeakSpots: isWeakSpots,
          ),
          boosted: boosted,
          streakNow: state.streakOn(local),
        );
  }

  /// Adds bonus XP from a chest.
  void addBonusXp(int xp) {
    state = state.withBonusXp(xp);
    _save(ref.read(progressRepositoryProvider).saveProgress(state), 'bonus');
  }

  /// Clears XP, streak and completed lessons.
  void reset() {
    state = const Progress();
    ref.read(answerStatsProvider.notifier).clear();
    ref.read(motivationProvider.notifier).resetStats();
    _save(ref.read(progressRepositoryProvider).resetProgress(), 'reset');
  }
}

/// Daily goal, quests, chests, streak freezes and the XP boost.
final motivationProvider =
    NotifierProvider<MotivationController, MotivationState>(
      MotivationController.new,
    );

class MotivationController extends Notifier<MotivationState> {
  @override
  MotivationState build() => ref.read(initialStateProvider).motivation;

  DateTime get _now => ref.read(clockProvider).now();

  void _set(MotivationState next) {
    state = next;
    _save(
      ref.read(progressRepositoryProvider).saveMotivation(next),
      'motivation',
    );
  }

  /// Replaces the whole state. Used by streak freezes.
  void replace(MotivationState next) => _set(next);

  /// Today's quests, easy to hard.
  List<Quest> get todaysQuests => dailyQuests(_now.toLocal());

  void chooseGoal(DailyGoal goal, {int? streakGoal}) => _set(
    state.copyWith(
      goal: goal,
      goalChosen: true,
      streakGoal: streakGoal,
      clearStreakGoal: streakGoal == null,
    ),
  );

  LessonOutcome recordLesson(
    LessonResult result, {
    required bool boosted,
    required int streakNow,
  }) {
    final local = _now.toLocal();
    final before = state.statsOn(local);
    var next = state.recordLesson(result, local: local, streakNow: streakNow);
    final after = next.statsOn(local);
    final milestone =
        streakMilestones.contains(streakNow) &&
            !state.milestones.contains(streakNow)
        ? streakNow
        : null;
    if (milestone != null) {
      next = next.copyWith(
        milestones: {...next.milestones, milestone},
        freezes: min(next.freezes + 1, maxStreakFreezes),
      );
    }
    _set(next);
    return LessonOutcome(
      xp: result.xp,
      boosted: boosted,
      todayXp: after.xp,
      goal: state.goal,
      goalJustMet: before.xp < state.goal.xp && after.xp >= state.goal.xp,
      questsJustDone: [
        for (final quest in dailyQuests(local))
          if (!quest.doneIn(before) && quest.doneIn(after)) quest,
      ],
      milestone: milestone,
    );
  }

  void recordGlossaryView(String termId) =>
      _set(state.recordGlossaryView(termId, _now.toLocal()));

  /// Opens the chest of today's quest at [index] and returns its reward.
  /// Returns null if that quest isn't finished or the chest is already open.
  ChestReward? openChest(int index) {
    final now = _now;
    final local = now.toLocal();
    final quests = dailyQuests(local);
    if (index >= quests.length) return null;
    if (!quests[index].doneIn(state.statsOn(local))) return null;
    if (state.chestOpened(local, index)) return null;
    final reward = chestRewardFor(dayKey(local), index, freezes: state.freezes);
    _set(state.openChest(index, reward, now));
    if (reward is BonusXpReward) {
      ref.read(progressProvider.notifier).addBonusXp(reward.xp);
    }
    return reward;
  }

  /// Developer menu: adds a streak freeze, up to the maximum.
  void giveFreeze() =>
      _set(state.copyWith(freezes: min(state.freezes + 1, maxStreakFreezes)));

  void resetStats() => _set(state.resetStats());
}

/// Right and wrong counts per question, kept in step with the answer log.
final answerStatsProvider =
    NotifierProvider<AnswerStatsController, AnswerStats>(
      AnswerStatsController.new,
    );

class AnswerStatsController extends Notifier<AnswerStats> {
  @override
  AnswerStats build() => ref.read(initialStateProvider).answerStats;

  void record(List<AnswerAttempt> answers) =>
      state = state.withAttempts(answers);

  void clear() => state = const AnswerStats();
}

final avatarProvider = NotifierProvider<AvatarController, Avatar?>(
  AvatarController.new,
);

/// The learner's player avatar, or null before they make one.
class AvatarController extends Notifier<Avatar?> {
  @override
  Avatar? build() => ref.read(initialStateProvider).avatar;

  void set(Avatar? avatar) {
    state = avatar;
    _save(ref.read(progressRepositoryProvider).saveAvatar(avatar), 'avatar');
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialStateProvider).settings;

  void update(AppSettings settings) {
    state = settings;
    _save(
      ref.read(progressRepositoryProvider).saveSettings(settings),
      'settings',
    );
  }
}

final nameProvider = NotifierProvider<NameController, String?>(
  NameController.new,
);

class NameController extends Notifier<String?> {
  @override
  String? build() => ref.read(initialStateProvider).name;

  void set(String? name) {
    final trimmed = name?.trim();
    state = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    _save(ref.read(progressRepositoryProvider).saveName(state), 'name');
  }
}
