import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/core/data/asset_content_repository.dart';
import 'package:six_on_six/core/domain/clock.dart';
import 'package:six_on_six/core/domain/content_repository.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/game_rules.dart';
import 'package:six_on_six/core/domain/progress.dart';

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
}
