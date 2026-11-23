import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/components.dart';

Widget _bar({String? note}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 300,
        child: ShineBar(
          value: 0.7,
          color: Colors.orange,
          track: Colors.grey,
          height: 16,
          note: note,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a note shows in the empty part of the bar', (tester) async {
    await tester.pumpWidget(_bar(note: '2 to go'));
    await tester.pumpAndSettle();
    expect(find.text('2 to go'), findsOneWidget);

    await tester.pumpWidget(_bar());
    await tester.pumpAndSettle();
    expect(find.text('2 to go'), findsNothing);
  });
}
