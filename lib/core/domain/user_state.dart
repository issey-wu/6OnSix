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

/// Everything saved on the device, loaded once at start-up.
@immutable
class StoredState {
  const new({
    this.progress = const Progress(),
    this.settings = const AppSettings(),
    this.name,
  });

  final Progress progress;
  final AppSettings settings;

  /// Optional display name. Null means "Player".
  final String? name;
}
