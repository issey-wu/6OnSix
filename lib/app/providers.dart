import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/logger.dart';
import 'package:six_on_six/core/data/asset_content_repository.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/clock.dart';
import 'package:six_on_six/core/domain/content_repository.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/game_rules.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/progress_repository.dart';
import 'package:six_on_six/core/domain/user_state.dart';

const _logger = AppLogger('providers');

/// The time source for all app logic. Override in tests to control time.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

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

class ProgressController extends Notifier<Progress> {
  @override
  Progress build() => ref.read(initialStateProvider).progress;

  /// Records a finished lesson or review and returns the XP earned.
  int complete({
    required String nodeId,
    required bool isReview,
    required bool perfect,
    List<AnswerAttempt> answers = const [],
  }) {
    final xp = ref
        .read(gameRulesProvider)
        .xpFor(isReview: isReview, perfect: perfect);
    state = state.complete(
      nodeId: nodeId,
      xpEarned: xp,
      localNow: ref.read(clockProvider).now().toLocal(),
    );
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
    return xp;
  }

  /// Clears XP, streak and completed lessons.
  void reset() {
    state = const Progress();
    _save(ref.read(progressRepositoryProvider).resetProgress(), 'reset');
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
