import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:six_on_six/features/glossary/presentation/glossary_text.dart';

import '../../support/pump_app.dart';

const _course = Course(
  schemaVersion: 1,
  units: [
    Unit(id: 'u1', title: 'One', description: '', lessons: []),
    Unit(id: 'u2', title: 'Two', description: '', lessons: []),
  ],
  glossary: [
    GlossaryTerm(
      id: 'side-out',
      term: 'Side-out',
      definition: 'Winning a rally while the other team served.',
      unitId: 'u1',
    ),
    GlossaryTerm(
      id: 'kill',
      term: 'Kill',
      definition: 'An attack that ends the rally.',
      unitId: 'u2',
    ),
    GlossaryTerm(
      id: 'court',
      term: 'Court',
      definition: 'The playing area.',
      unitId: 'u1',
    ),
  ],
);

Future<void> _show(WidgetTester tester, String text, int unit) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [courseProvider.overrideWithValue(const AsyncData(_course))],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: GlossaryText(text, unitIndex: unit)),
        ),
      ),
    );

bool _linked(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text)).textSpan != null;

void main() {
  testWidgets('a term taught so far is a link to its meaning', (tester) async {
    await _show(tester, 'After a side out, the team rotates.', 0);
    await tester.tapOnText(find.textRange.ofSubstring('side out'));
    await tester.pumpAndSettle();
    expect(find.text('Side-out'), findsOneWidget);
    expect(
      find.text('Winning a rally while the other team served.'),
      findsOneWidget,
    );
  });

  testWidgets('a term from a later unit stays plain', (tester) async {
    await _show(tester, 'A kill ends the rally.', 0);
    expect(_linked(tester), isFalse);
    await _show(tester, 'A kill ends the rally.', 1);
    expect(_linked(tester), isTrue);
  });

  testWidgets('everyday words such as court are not links', (tester) async {
    await _show(tester, 'The court is 18 m long.', 1);
    expect(_linked(tester), isFalse);
  });

  testWidgets('a lesson card links its words', (tester) async {
    await pumpWholeApp(
      tester,
      state: const StoredState(
        settings: AppSettings(welcomeSeen: true, tipsSeen: Tips.all),
      ),
      location: '/lesson/u1.l3',
    );
    expect(find.text('Rotating'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tapOnText(find.textRange.ofSubstring('side out'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('term-ok')), findsOneWidget);
  });
}
