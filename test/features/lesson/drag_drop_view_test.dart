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
  placements: {'S': 1, 'OH2': 5, 'L': 6},
  answer: 'L=6|OH2=5|S=1',
);

Finder _token(String token) => find.byKey(ValueKey('token-$token'));
Finder _zone(int zone) => find.byKey(ValueKey('zone-$zone'));

Future<List<String?>> _pump(WidgetTester tester) async {
  final reports = <String?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: DragDropView(
              question: _question,
              haptics: false,
              onChanged: reports.add,
            ),
          ),
        ),
      ),
    ),
  );
  return reports;
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

void main() {
  testWidgets('tap a player, then a zone, to place it', (tester) async {
    final reports = await _pump(tester);
    await _tapPlace(tester, 'S', 1);

    expect(_isIn('S', 1), isTrue);
    // Two players are still in the tray, so there is no answer yet.
    expect(reports.last, isNull);
  });

  testWidgets('reports the placement once every player is on the court', (
    tester,
  ) async {
    final reports = await _pump(tester);
    await _tapPlace(tester, 'S', 1);
    await _tapPlace(tester, 'OH2', 5);
    await _tapPlace(tester, 'L', 6);

    expect(reports.last, isNotNull);
    expect(_question.isCorrect(reports.last!), isTrue);
    expect(find.text('All players placed'), findsOneWidget);
  });

  testWidgets('a wrong arrangement is graded wrong', (tester) async {
    final reports = await _pump(tester);
    await _tapPlace(tester, 'S', 5);
    await _tapPlace(tester, 'OH2', 1);
    await _tapPlace(tester, 'L', 6);

    expect(_question.isCorrect(reports.last!), isFalse);
  });

  testWidgets('placing onto a taken zone swaps the two players', (
    tester,
  ) async {
    await _pump(tester);
    await _tapPlace(tester, 'S', 1);
    await _tapPlace(tester, 'OH2', 5);

    // Pick the setter, then tap the outside hitter's spot.
    await tester.tap(_token('S'));
    await tester.pump();
    await tester.tap(_token('OH2'));
    await tester.pump();

    expect(_isIn('S', 5), isTrue);
    expect(_isIn('OH2', 1), isTrue);
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

    await dragTo(_token('L'), find.byKey(const ValueKey('tray')));
    expect(_isIn('L', 6), isFalse);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tray')),
        matching: _token('L'),
      ),
      findsOneWidget,
    );
  });
}
