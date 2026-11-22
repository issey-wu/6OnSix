import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/ace.dart';
import 'package:six_on_six/core/ui/ace_lines.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = true,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Every image Ace is drawn from right now.
List<String> _assets(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((i) => (i.image as AssetImage).assetName)
    .toList();

/// The beak Ace is showing.
String _beak(WidgetTester tester) =>
    _assets(tester).firstWhere((name) => name.contains('beak'));

void main() {
  testWidgets('with Reduce Motion, Ace holds one still pose', (tester) async {
    await _show(tester, const Ace(action: AceAction.cheer));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Ace the eagle'), findsOneWidget);
    // Both wings up, and a laugh.
    expect(_assets(tester).where((a) => a.endsWith('/wing.png')), hasLength(2));
    expect(_beak(tester), contains('beak_open'));
  });

  testWidgets('at rest, both wings hang by his sides', (tester) async {
    await _show(tester, const Ace());
    await tester.pumpAndSettle();
    expect(
      _assets(tester).where((a) => a.endsWith('/wing_rest.png')),
      hasLength(2),
    );
    expect(_beak(tester), contains('beak_closed'));
  });

  testWidgets('a cheeky fist pump shows the fist and one open eye', (
    tester,
  ) async {
    await _show(
      tester,
      const Ace(action: AceAction.fistPump, mood: AceMood.cheeky),
    );
    await tester.pumpAndSettle();
    final assets = _assets(tester);
    expect(assets.where((a) => a.endsWith('/wing_fist.png')), hasLength(1));
    // A wink: one eye drawn open, the other closed in a smile.
    expect(assets.where((a) => a.contains('/eye_')), hasLength(1));
  });

  testWidgets('with motion on, Ace cheers and then settles', (tester) async {
    await _show(
      tester,
      const Ace(action: AceAction.cheer),
      reduceMotion: false,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(_beak(tester), contains('beak_open'));
    await tester.pump(const Duration(seconds: 2));
    expect(_beak(tester), contains('beak_closed'));
    // Stop the idle loop before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a speech bubble is read out to screen readers', (tester) async {
    await _show(tester, const AceSays(text: 'Ready to serve?'));
    await tester.pumpAndSettle();
    expect(find.text('Ready to serve?'), findsOneWidget);
    expect(find.bySemanticsLabel('Ace says: Ready to serve?'), findsOneWidget);
  });

  testWidgets('a peek stays put with Reduce Motion', (tester) async {
    await _show(
      tester,
      const SizedBox(
        width: 360,
        height: 200,
        child: Align(
          alignment: Alignment.bottomRight,
          child: AcePeek(text: 'Shank happens. Next ball!'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shank happens. Next ball!'), findsOneWidget);
  });

  testWidgets('with motion on, a peek leaves after a few seconds', (
    tester,
  ) async {
    await _show(
      tester,
      const SizedBox(
        width: 360,
        height: 200,
        child: Align(
          alignment: Alignment.bottomRight,
          child: AcePeek(text: 'Shank happens. Next ball!'),
        ),
      ),
      reduceMotion: false,
    );
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Shank happens. Next ball!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Shank happens. Next ball!'), findsNothing);
    expect(find.byType(Ace), findsNothing);
  });

  group('lines', () {
    final random = Random(1);

    test('cheers at 3, 5 and every 4 from 8 in a row', () {
      expect(aceCombo(random, 2), isNull);
      expect(aceCombo(random, 3), isNotNull);
      expect(aceCombo(random, 4), isNull);
      expect(aceCombo(random, 5), isNotNull);
      expect(aceCombo(random, 8), contains('8'));
      expect(aceCombo(random, 9), isNull);
      expect(aceCombo(random, 12), contains('12'));
    });

    test('the lesson complete line puts the streak first', () {
      String done({
        bool perfect = false,
        int streak = 3,
        bool grew = false,
        bool milestone = false,
      }) => aceLessonDone(
        random,
        perfect: perfect,
        review: false,
        streak: streak,
        streakGrew: grew,
        milestone: milestone,
      );
      expect(done(streak: 7, grew: true, milestone: true), contains('7 days'));
      expect(done(streak: 1, grew: true), startsWith('Day one'));
      expect(done(perfect: true, grew: true), contains('3'));
      expect([
        'Perfect! Not a single ball dropped.',
        'Flawless. Should I be worried about my job?',
        'Zero mistakes. Show-off.',
      ], contains(done(perfect: true)));
    });

    test('on the path, a lost streak comes before everything else', () {
      final line = aceOnPath(
        random,
        streak: 0,
        practisedToday: true,
        goalMet: true,
        lostStreak: true,
      );
      expect(line, anyOf(contains('streak'), contains('New streak')));
    });

    test('no line uses an em dash', () {
      final lines = [
        aceHello,
        aceGoalQuestion,
        for (var i = 0; i < 40; i++) ...[
          ?aceCombo(random, const [3, 5, 8][i % 3]),
          aceFirstMistake(random),
          aceToughRally(random),
          aceLastOne(random),
        ],
        aceLeague(promoted: true, demoted: false),
        aceLeague(promoted: false, demoted: true),
        aceLeague(promoted: false, demoted: false),
      ];
      for (final line in lines) {
        expect(line, isNot(contains('—')));
      }
    });
  });
}
