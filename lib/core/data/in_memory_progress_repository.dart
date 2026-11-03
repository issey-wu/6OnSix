import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/progress_repository.dart';
import 'package:six_on_six/core/domain/user_state.dart';

/// Keeps everything in memory. Used in widget tests, and as a fallback if
/// the device database cannot be opened, so the app still works.
class InMemoryProgressRepository implements ProgressRepository {
  new([this._state = const StoredState()]);

  StoredState _state;
  final List<AnswerAttempt> answers = [];

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
    _state = StoredState(
      progress: updated,
      settings: _state.settings,
      name: _state.name,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _state = StoredState(
      progress: _state.progress,
      settings: settings,
      name: _state.name,
    );
  }

  @override
  Future<void> saveName(String? name) async {
    _state = StoredState(
      progress: _state.progress,
      settings: _state.settings,
      name: name,
    );
  }

  @override
  Future<void> resetProgress() async {
    answers.clear();
    _state = StoredState(settings: _state.settings, name: _state.name);
  }
}
