import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/domain/user_state.dart';

import '../support/pump_app.dart';

Future<void> _gotIt(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('tips-ok')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('after the first lesson and goal, the Learn tab gives a short '
      'tour', (tester) async {
    final container = await pumpWholeApp(
      tester,
      state: const StoredState(
        settings: AppSettings(welcomeSeen: true),
        progress: Progress(completed: {'u1.l1'}, xp: 10),
        motivation: MotivationState(goalChosen: true),
      ),
    );
    expect(find.textContaining('This is your next lesson'), findsOneWidget);
    await _gotIt(tester);
    expect(find.textContaining('Your streak!'), findsOneWidget);
    await _gotIt(tester);
    expect(find.textContaining('Your daily goal'), findsOneWidget);
    await _gotIt(tester);
    expect(find.textContaining('live down here'), findsOneWidget);
    await _gotIt(tester);
    expect(find.byKey(const ValueKey('tips-ok')), findsNothing);
    expect(
      container.read(settingsProvider).tipsSeen,
      containsAll([Tips.path, Tips.streak, Tips.goal, Tips.tabs]),
    );
  });

  testWidgets('a brand new learner gets no Learn tab tour yet', (tester) async {
    await pumpWholeApp(
      tester,
      state: const StoredState(settings: AppSettings(welcomeSeen: true)),
    );
    expect(find.byKey(const ValueKey('tips-ok')), findsNothing);
  });

  testWidgets('the League tab explains the ladder once', (tester) async {
    final container = await pumpWholeApp(
      tester,
      state: const StoredState(
        settings: AppSettings(welcomeSeen: true, tipsSeen: {Tips.path}),
      ),
      location: '/league',
    );
    expect(find.textContaining('Tap a badge to peek'), findsWidgets);
    await _gotIt(tester);
    expect(container.read(settingsProvider).tipsSeen, contains(Tips.league));
  });

  testWidgets('the Glossary tab points at search once', (tester) async {
    await pumpWholeApp(
      tester,
      state: const StoredState(settings: AppSettings(welcomeSeen: true)),
      location: '/glossary',
    );
    expect(find.textContaining('Look up any volleyball term'), findsOneWidget);
  });
}
