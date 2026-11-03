// Adapted from Yash Dubey's tests on yash/screens.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/features/lesson/presentation/drag_drop_view.dart';

const _question = Question(
  id: 'd',
  type: QuestionType.dragDrop,
  prompt: 'Place the back row.',
  explanation: 'e',
  tokens: ['S', 'OH2', 'L'],
  answer: 'S=1|OH2=5|L=6',
);

Finder _token(String token) => find.byKey(ValueKey('token-$token'));
Finder _zone(int zone) => find.byKey(ValueKey('zone-$zone'));
final Finder _tray = find.byKey(const ValueKey('tray'));

class _Log {
  final reports = <String?>[];
  int snaps = 0;
}

Future<_Log> _pump(WidgetTester tester, {bool locked = false}) async {
  final log = _Log();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: DragDropView(
              question: _question,
              locked: locked,
              random: Random(1),
              onChanged: log.reports.add,
              onSnap: () => log.snaps++,
            ),
          ),
        ),
      ),
    ),
  );
  return log;
}

Future<void> _tapPlace(WidgetTester tester, String token, int zone) async {
  await tester.tap(_token(token));
  await tester.pump();
  await tester.tap(_zone(zone));
  await tester.pump();
}

bool _isIn(String token, int zone) => find
    .descendant(of: _zone(zone), matching: _token(token))
    .evaluate()
    .isNotEmpty;

bool _inTray(String token) =>
    find.descendant(of: _tray, matching: _token(token)).evaluate().isNotEmpty;

void main() {
  testWidgets('tap a player, then a zone, to place it', (tester) async {
    final log = await _pump(tester);
    await _tapPlace(tester, 'S', 1);

    expect(_isIn('S', 1), isTrue);
    expect(log.snaps, 1);
    // Two players are still in the tray, so there is no answer yet.
    expect(log.reports.last, isNull);
  });

  testWidgets('reports the placement once every player is on the court', (
    tester,
  ) async {
    final log = await _pump(tester);
    await _tapPlace(tester, 'L', 6);
    await _tapPlace(tester, 'S', 1);
    await _tapPlace(tester, 'OH2', 5);

    // Always in the question's token order, whatever order they were placed.
    expect(log.reports.last, 'S=1|OH2=5|L=6');
    expect(_question.isCorrect(log.reports.last!), isTrue);
    expect(find.text('All players placed'), findsOneWidget);
  });

  testWidgets('a wrong arrangement is graded wrong', (tester) async {
    final log = await _pump(tester);
    await _tapPlace(tester, 'S', 5);
    await _tapPlace(tester, 'OH2', 1);
    await _tapPlace(tester, 'L', 6);

    expect(_question.isCorrect(log.reports.last!), isFalse);
  });

  testWidgets('picking a player then tapping another on court swaps them', (
    tester,
  ) async {
    await _pump(tester);
    await _tapPlace(tester, 'S', 1);
    await _tapPlace(tester, 'OH2', 5);

    await tester.tap(_token('S'));
    await tester.pump();
    await tester.tap(_token('OH2'));
    await tester.pump();

    expect(_isIn('S', 5), isTrue);
    expect(_isIn('OH2', 1), isTrue);
  });

  testWidgets('placing from the tray onto a taken zone sends the other back', (
    tester,
  ) async {
    await _pump(tester);
    await _tapPlace(tester, 'S', 1);
    await _tapPlace(tester, 'L', 1);

    expect(_isIn('L', 1), isTrue);
    expect(_inTray('S'), isTrue);
  });

  testWidgets('pick a placed player and tap the tray to take it off', (
    tester,
  ) async {
    final log = await _pump(tester);
    await _tapPlace(tester, 'S', 1);
    await tester.tap(_token('S'));
    await tester.pump();
    // Tap the tray's edge, away from the players still in it.
    await tester.tapAt(tester.getTopLeft(_tray) + const Offset(8, 8));
    await tester.pump();

    expect(_isIn('S', 1), isFalse);
    expect(_inTray('S'), isTrue);
    expect(log.reports.last, isNull);
  });

  testWidgets('drag a player onto a zone and back to the tray', (tester) async {
    await _pump(tester);

    Future<void> dragTo(Finder from, Finder to) async {
      final gesture = await tester.startGesture(tester.getCenter(from));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(to));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await dragTo(_token('L'), _zone(6));
    expect(_isIn('L', 6), isTrue);

    await dragTo(_token('L'), _tray);
    expect(_isIn('L', 6), isFalse);
    expect(_inTray('L'), isTrue);
  });

  testWidgets('locked after Check: taps do nothing', (tester) async {
    final log = await _pump(tester, locked: true);
    await tester.tap(_zone(1));
    await tester.pump();
    expect(log.snaps, 0);
    expect(log.reports, isEmpty);
  });
}
