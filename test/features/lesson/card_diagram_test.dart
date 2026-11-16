import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/features/lesson/presentation/card_diagram.dart';

void main() {
  testWidgets('every diagram the content can ask for draws', (tester) async {
    for (final MapEntry(key: kind, value: highlights) in cardDiagrams.entries) {
      for (final highlight in highlights) {
        final spec = highlight.isEmpty ? kind : '$kind:$highlight';
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: CardDiagram(spec: spec)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: spec);
        expect(
          find.byType(CustomPaint),
          findsWidgets,
          reason: '$spec draws something',
        );
      }
    }
  });

  testWidgets('an unknown diagram draws nothing instead of failing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CardDiagram(spec: 'blimp')),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
