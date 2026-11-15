import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/router.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/user_state.dart';

import '../../support/fake_clock.dart';

final _clock = FakeClock(DateTime(2026, 11, 14, 12));

Future<ProviderContainer> _pump(WidgetTester tester, StoredState state) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  // A tall screen, so every quest card is built without scrolling.
  tester.view.physicalSize = const Size(2400, 6000);
  addTearDown(tester.view.resetPhysicalSize);
  final container = ProviderContainer(
    overrides: [
      initialStateProvider.overrideWithValue(state),
      progressRepositoryProvider.overrideWithValue(
        InMemoryProgressRepository(state),
      ),
      clockProvider.overrideWithValue(_clock),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SixOnSixApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a finished quest opens a chest with a reward', (tester) async {
    final local = _clock.now().toLocal();
    // Enough activity today to finish every possible quest.
    final busyDay = MotivationState(
      goalChosen: true,
      days: {
        dayKey(local): const DayStats(
          xp: 100,
          lessons: 5,
          perfectLessons: 2,
          bestCombo: 10,
          glossaryViews: 5,
          courtCorrect: 5,
          reviews: 2,
        ),
      },
    );
    final container = await _pump(
      tester,
      StoredState(
        settings: const AppSettings(welcomeSeen: true),
        progress: const Progress(xp: 100),
        motivation: busyDay,
      ),
    );
    container.read(routerProvider).go('/quests');
    await tester.pumpAndSettle();
    expect(find.text('Daily goal met!'), findsOneWidget);
    expect(find.text('Open'), findsNWidgets(3));

    // The third chest always holds the XP boost.
    await _tap(tester, find.text('Open').last);
    expect(find.text('Chest opened!'), findsOneWidget);
    expect(find.text('Double XP'), findsOneWidget);
    await _tap(tester, find.text('Nice!'));

    expect(find.text('Open'), findsNWidgets(2));
    final motivation = container.read(motivationProvider);
    expect(motivation.boostActive(_clock.now()), isTrue);
    expect(find.textContaining('Double XP until'), findsOneWidget);
    expect(container.read(motivationProvider).totals.questsDone, 1);
  });

  testWidgets('a locked chest cannot be opened', (tester) async {
    await _pump(
      tester,
      const StoredState(
        settings: AppSettings(welcomeSeen: true),
        motivation: MotivationState(goalChosen: true),
      ),
    );
    await _tap(tester, find.text('Quests'));
    expect(find.text('Open'), findsNothing);
    expect(find.textContaining('Daily goal: 0 of 20 XP'), findsOneWidget);
  });

  testWidgets('the goal screen saves the goal and the streak commitment', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      const StoredState(settings: AppSettings(welcomeSeen: true)),
    );
    container.read(routerProvider).go('/goal');
    await tester.pumpAndSettle();
    expect(find.text('How much time a day?'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('goal-serious')));
    await _tap(tester, find.text('30 days'));
    await _tap(tester, find.byKey(const ValueKey('save-goal')));

    final motivation = container.read(motivationProvider);
    expect(motivation.goal, DailyGoal.serious);
    expect(motivation.streakGoal, 30);
    expect(motivation.goalChosen, isTrue);
    expect(find.text('6 On Six'), findsOneWidget);
  });

  test('reaching a 7-day streak gives a freeze and a celebration', () {
    final day6 = DateTime(2026, 11, 13, 18);
    var progress = const Progress();
    for (var i = 5; i >= 0; i--) {
      progress = progress.complete(
        nodeId: 'n$i',
        xpEarned: 10,
        localNow: day6.subtract(Duration(days: i)),
      );
    }
    expect(progress.streak, 6);
    final container = ProviderContainer.test(
      overrides: [
        initialStateProvider.overrideWithValue(StoredState(progress: progress)),
        clockProvider.overrideWithValue(_clock),
      ],
    );
    final outcome = container
        .read(progressProvider.notifier)
        .complete(nodeId: 'u1.l1', isReview: false, perfect: true);
    expect(outcome.milestone, 7);
    expect(container.read(motivationProvider).freezes, 1);
    expect(outcome.xp, 15);
    expect(outcome.goalJustMet, isFalse);
  });
}
