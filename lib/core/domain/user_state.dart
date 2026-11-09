import 'package:meta/meta.dart';
import 'package:six_on_six/core/domain/progress.dart';

enum ThemePreference { system, light, dark }

/// The learner's app settings.
@immutable
class AppSettings {
  const new({
    this.theme = ThemePreference.system,
    this.soundOn = true,
    this.hapticsOn = true,
    this.welcomeSeen = false,
  });

  final ThemePreference theme;
  final bool soundOn;
  final bool hapticsOn;

  /// False until the learner taps Get started on the welcome screen.
  final bool welcomeSeen;

  AppSettings copyWith({
    ThemePreference? theme,
    bool? soundOn,
    bool? hapticsOn,
    bool? welcomeSeen,
  }) => AppSettings(
    theme: theme ?? this.theme,
    soundOn: soundOn ?? this.soundOn,
    hapticsOn: hapticsOn ?? this.hapticsOn,
    welcomeSeen: welcomeSeen ?? this.welcomeSeen,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.soundOn == soundOn &&
      other.hapticsOn == hapticsOn &&
      other.welcomeSeen == welcomeSeen;

  @override
  int get hashCode => Object.hash(theme, soundOn, hapticsOn, welcomeSeen);
}

/// One answer given during a lesson, kept for the answer log.
@immutable
class AnswerAttempt {
  const new({
    required this.questionId,
    required this.correct,
    required this.answeredAt,
  });

  final String questionId;
  final bool correct;

  /// UTC.
  final DateTime answeredAt;
}

/// How often each question has been answered right and wrong, worked out
/// from the answer log. Used to find weak spots to practise.
@immutable
class AnswerStats {
  const new([this._tallies = const {}]);

  final Map<String, (int right, int wrong)> _tallies;

  bool get isEmpty => _tallies.isEmpty;

  /// Times [questionId] was answered right and wrong.
  (int right, int wrong) tally(String questionId) =>
      _tallies[questionId] ?? (0, 0);

  /// Adds (question id, correct) results.
  AnswerStats withResults(Iterable<(String, bool)> results) {
    final next = {..._tallies};
    for (final (id, correct) in results) {
      final (right, wrong) = next[id] ?? (0, 0);
      next[id] = correct ? (right + 1, wrong) : (right, wrong + 1);
    }
    return AnswerStats(next);
  }

  AnswerStats withAttempts(Iterable<AnswerAttempt> attempts) =>
      withResults([for (final a in attempts) (a.questionId, a.correct)]);

  /// Questions that still count as weak, weakest first, at most [limit].
  ///
  /// A miss counts double. Each miss in a lesson is followed by a right
  /// answer before the lesson ends, so a question stops being weak once it
  /// has been answered right one more time per miss.
  List<String> weakest({int limit = 8}) {
    int score((int, int) t) => 2 * t.$2 - t.$1;
    final weak =
        [
          for (final MapEntry(key: id, value: t) in _tallies.entries)
            if (score(t) > 0) (id, score(t)),
        ]..sort((a, b) {
          final byScore = b.$2.compareTo(a.$2);
          return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
        });
    return [for (final (id, _) in weak.take(limit)) id];
  }
}

/// Everything saved on the device, loaded once at start-up.
@immutable
class StoredState {
  const new({
    this.progress = const Progress(),
    this.settings = const AppSettings(),
    this.name,
    this.answerStats = const AnswerStats(),
  });

  final Progress progress;
  final AppSettings settings;

  /// Right and wrong counts per question, from the answer log.
  final AnswerStats answerStats;

  /// Optional display name. Null means "Player".
  final String? name;
}
