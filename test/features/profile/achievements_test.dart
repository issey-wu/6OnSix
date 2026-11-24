import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/domain/user_state.dart';

import '../../support/pump_app.dart';

const _state = StoredState(
  settings: AppSettings(welcomeSeen: true, tipsSeen: Tips.all),
  progress: Progress(xp: 320, streak: 1),
  motivation: MotivationState(
    goalChosen: true,
    totals: MotivationTotals(longestStreak: 4),
  ),
);

void main() {
  testWidgets('the profile shows badges, and a badge shows its next level', (
    tester,
  ) async {
    await pumpWholeApp(
      tester,
      state: _state,
      location: '/profile',
      size: const Size(1170, 6000),
    );
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('2 of 8 earned'), findsOneWidget);
    expect(find.bySemanticsLabel('Point scorer, level 2 of 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Comeback kid, not earned yet'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('badge-streak')));
    await tester.pumpAndSettle();
    expect(find.text('Next: Reach a 7 day streak.'), findsOneWidget);
    expect(find.text('4 of 7'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('badge-ok')));
    await tester.pumpAndSettle();
    expect(find.text('Next: Reach a 7 day streak.'), findsNothing);
  });
}
