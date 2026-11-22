import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/router.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/league.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/domain/user_state.dart';

import '../../support/fake_clock.dart';

// Wednesday evening.
final _clock = FakeClock(DateTime(2026, 11, 18, 20));

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  LeagueState league = const LeagueState(),
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = const Size(2400, 7200);
  addTearDown(tester.view.resetPhysicalSize);
  final state = StoredState(
    settings: const AppSettings(welcomeSeen: true, tipsSeen: Tips.all),
    league: league,
  );
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
  container.read(routerProvider).go('/league');
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('before any XP this week, the League tab invites a lesson', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Rec League'), findsOneWidget);
    expect(find.text('Demo community'), findsOneWidget);
    expect(find.text("Join this week's league"), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
  });

  testWidgets('once joined, the table shows 30 players and the zones', (
    tester,
  ) async {
    final league = const LeagueState().addXp(60, _clock.now());
    await _pump(tester, league: league);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('60 XP'), findsWidgets);
    expect(find.text('PROMOTION ZONE'), findsOneWidget);
    // Rec has no demotion zone.
    expect(find.text('DEMOTION ZONE'), findsNothing);
    expect(find.textContaining('Ends in 4 days'), findsOneWidget);
  });

  testWidgets('a lesson earns league XP', (tester) async {
    final container = await _pump(tester);
    container.read(progressProvider.notifier).addBonusXp(15);
    await tester.pumpAndSettle();
    expect(container.read(leagueProvider).xp, 15);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('a finished week shows its results once', (tester) async {
    final league = const LeagueState()
        .addXp(900, _clock.now())
        .settle(_clock.now(), force: true);
    final container = await _pump(tester, league: league);
    expect(find.text('Promoted!'), findsOneWidget);
    expect(find.textContaining('moved up to House League'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('league-result-ok')));
    await tester.pumpAndSettle();
    expect(find.text('House League'), findsWidgets);
    expect(container.read(leagueProvider).lastResult!.seen, isTrue);
  });

  testWidgets('the developer menu can end the week early', (tester) async {
    final league = const LeagueState().addXp(900, _clock.now());
    final container = await _pump(tester, league: league);
    container.read(leagueProvider.notifier).endWeekNow();
    final after = container.read(leagueProvider);
    expect(after.joined, isFalse);
    expect(after.division, Division.house);
    expect(after.lastResult!.rank, 1);
  });

  testWidgets('tapping a friend opens their profile', (tester) async {
    await _pump(tester);
    final friend = demoFriends.first;
    await tester.ensureVisible(find.byKey(ValueKey(friend.id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(friend.id)));
    await tester.pumpAndSettle();
    expect(find.text('Demo community player'), findsOneWidget);
    expect(find.text('Recent lessons'), findsOneWidget);
    expect(find.text(friend.division.label), findsOneWidget);
  });

  testWidgets('tapping a badge gives a sneak peek at that league', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Tap a badge to peek at a league'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('peek-olympic')));
    await tester.pumpAndSettle();
    expect(find.text('Olympic League'), findsOneWidget);
    expect(find.textContaining('Locked'), findsOneWidget);
    expect(find.text('The top league. Nowhere left to climb.'), findsOneWidget);
    expect(
      find.text('Move up 6 leagues from Rec League to get here.'),
      findsOneWidget,
    );
    expect(find.text('Top of a typical week'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('peek-house')));
    await tester.pumpAndSettle();
    expect(
      find.text('Finish in the top 10 of Rec League to get here.'),
      findsOneWidget,
    );
  });
}
