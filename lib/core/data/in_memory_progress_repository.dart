import 'package:six_on_six/core/domain/avatar.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/progress_repository.dart';
import 'package:six_on_six/core/domain/user_state.dart';

/// Keeps everything in memory. Used in widget tests, and as a fallback if
/// the device database cannot be opened, so the app still works.
class InMemoryProgressRepository implements ProgressRepository {
  new([this._state = const StoredState()]);

  StoredState _state;
  final List<AnswerAttempt> answers = [];

  StoredState _copy({
    Progress? progress,
    AppSettings? settings,
    String? name,
    bool clearName = false,
    AnswerStats? answerStats,
    MotivationState? motivation,
    Avatar? avatar,
    bool clearAvatar = false,
  }) => StoredState(
    progress: progress ?? _state.progress,
    settings: settings ?? _state.settings,
    name: clearName ? null : (name ?? _state.name),
    answerStats: answerStats ?? _state.answerStats,
    motivation: motivation ?? _state.motivation,
    avatar: clearAvatar ? null : (avatar ?? _state.avatar),
  );

  @override
  Future<StoredState> load() async => _state;

  @override
  Future<void> recordCompletion({
    required String nodeId,
    required bool perfect,
    required int xpEarned,
    required List<AnswerAttempt> answers,
    required Progress updated,
  }) async {
    this.answers.addAll(answers);
    _state = _copy(
      progress: updated,
      answerStats: _state.answerStats.withAttempts(answers),
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _state = _copy(settings: settings);
  }

  @override
  Future<void> saveName(String? name) async {
    _state = _copy(name: name, clearName: name == null);
  }

  @override
  Future<void> saveAvatar(Avatar? avatar) async {
    _state = _copy(avatar: avatar, clearAvatar: avatar == null);
  }

  @override
  Future<void> saveProgress(Progress progress) async {
    _state = _copy(progress: progress);
  }

  @override
  Future<void> saveMotivation(MotivationState motivation) async {
    _state = _copy(motivation: motivation);
  }

  @override
  Future<void> resetProgress() async {
    answers.clear();
    _state = StoredState(
      settings: _state.settings,
      name: _state.name,
      motivation: _state.motivation.resetStats(),
      avatar: _state.avatar,
    );
  }
}
