import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/core/data/asset_content_repository.dart';
import 'package:six_on_six/core/domain/clock.dart';
import 'package:six_on_six/core/domain/content_repository.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/game_rules.dart';
import 'package:six_on_six/core/domain/glossary.dart';
import 'package:six_on_six/core/domain/preferences.dart';
import 'package:six_on_six/core/domain/progress.dart';

/// How far the developer menu has moved the clock forward. Zero outside of
/// testing.
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

/// The bundled glossary, loaded once.
final glossaryProvider = FutureProvider<Glossary>(
  (ref) => ref.watch(contentRepositoryProvider).loadGlossary(),
);

/// The learner's progress. Held in memory for now; saving to the on-device
/// database (drift) is the next step.
final progressProvider = NotifierProvider<ProgressController, Progress>(
  ProgressController.new,
);

class ProgressController extends Notifier<Progress> {
  @override
  Progress build() => const Progress();

  /// Records a finished lesson or review and returns the XP earned.
  int complete({
    required String nodeId,
    required bool isReview,
    required bool perfect,
  }) {
    final xp = ref
        .read(gameRulesProvider)
        .xpFor(isReview: isReview, perfect: perfect);
    state = state.complete(
      nodeId: nodeId,
      xpEarned: xp,
      localNow: ref.read(clockProvider).now().toLocal(),
    );
    return xp;
  }

  /// Clears XP, the streak and completed lessons (Settings > Reset).
  void reset() => state = const Progress();
}

/// The learner's name and settings. Held in memory for now, like progress.
final preferencesProvider =
    NotifierProvider<PreferencesController, Preferences>(
      PreferencesController.new,
    );

class PreferencesController extends Notifier<Preferences> {
  @override
  Preferences build() => const Preferences();

  void rename(String name) => state = state.copyWith(name: name.trim());

  void chooseTheme(ThemeChoice theme) => state = state.copyWith(theme: theme);

  void toggleSound({required bool on}) => state = state.copyWith(sound: on);

  void toggleHaptics({required bool on}) => state = state.copyWith(haptics: on);

  void markWelcomeSeen() => state = state.copyWith(welcomeSeen: true);
}
