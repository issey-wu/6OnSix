import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/domain/user_state.dart';

import '../../support/pump_app.dart';

// Tall enough to show the whole settings list, developer menu included.
const _tall = Size(1170, 6000);

const _state = StoredState(
  settings: AppSettings(welcomeSeen: true, tipsSeen: Tips.all),
  motivation: MotivationState(goalChosen: true, freezes: 1),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('streak freezes can be given and taken back', (tester) async {
    final container = await pumpWholeApp(
      tester,
      state: _state,
      location: '/profile/settings',
      size: _tall,
    );
    expect(find.text('Holding 1 of $maxStreakFreezes'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('take-freeze')));
    expect(container.read(motivationProvider).freezes, 0);
    expect(find.text('Holding 0 of $maxStreakFreezes'), findsOneWidget);
    // Nothing left to take back.
    final take = tester.widget<IconButton>(
      find.byKey(const ValueKey('take-freeze')),
    );
    expect(take.onPressed, isNull);
    await _tap(tester, find.byKey(const ValueKey('give-freeze')));
    await _tap(tester, find.byKey(const ValueKey('give-freeze')));
    expect(container.read(motivationProvider).freezes, 2);
  });

  testWidgets('jump to any lesson lists every unit and opens a lesson', (
    tester,
  ) async {
    await pumpWholeApp(
      tester,
      state: _state,
      location: '/profile/settings',
      size: _tall,
    );
    await _tap(tester, find.text('Jump to any lesson'));
    expect(find.text('Jump to a lesson'), findsOneWidget);
    expect(find.text('UNIT 1'), findsOneWidget);
    expect(find.text('Lesson 1 · Up next'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('jump-u2.l1')));
    expect(find.text('Three contacts'), findsOneWidget);
  });

  testWidgets('Settings can replay the tutorial', (tester) async {
    final container = await pumpWholeApp(
      tester,
      state: _state,
      location: '/profile/settings',
      size: _tall,
    );
    await _tap(tester, find.byKey(const ValueKey('replay-tips')));
    expect(container.read(settingsProvider).tipsSeen, isEmpty);
  });
}
