import 'package:six_on_six/core/domain/avatar.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/user_state.dart';

/// Where the learner's progress and settings are saved. Screens never touch
/// the database directly; they go through this interface.
abstract interface class ProgressRepository {
  /// Loads saved state, creating the anonymous local user on first launch.
  Future<StoredState> load();

  /// Saves a finished lesson or review: the completion event, every answer
  /// given, and the updated totals, all in one transaction.
  Future<void> recordCompletion({
    required String nodeId,
    required bool perfect,
    required int xpEarned,
    required List<AnswerAttempt> answers,
    required Progress updated,
  });

  Future<void> saveSettings(AppSettings settings);

  /// Saves the running totals on their own, such as after chest bonus XP or
  /// a streak freeze.
  Future<void> saveProgress(Progress progress);

  /// Saves the motivation layer: goal, quests, freezes and stats.
  Future<void> saveMotivation(MotivationState motivation);

  Future<void> saveName(String? name);

  /// Saves the player avatar. Null clears it.
  Future<void> saveAvatar(Avatar? avatar);

  /// Clears progress (completions, answers, XP, streak). Settings and the
  /// name are kept.
  Future<void> resetProgress();
}
