import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/content_repository.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/glossary.dart';
import 'package:six_on_six/features/glossary/presentation/glossary_screen.dart';

class _FakeContent implements ContentRepository {
  @override
  Future<Course> loadCourse() async =>
      const Course(schemaVersion: 1, units: []);

  @override
  Future<Glossary> loadGlossary() async => const Glossary(
    terms: [
      GlossaryTerm(
        id: 'rotation',
        term: 'Rotation',
        definition: 'Moving one zone clockwise.',
      ),
      GlossaryTerm(
        id: 'ace',
        term: 'Ace',
        definition: 'A serve that scores directly.',
      ),
      GlossaryTerm(
        id: 'antenna',
        term: 'Antenna',
        definition: 'The rod that marks the side of the crossing space.',
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [contentRepositoryProvider.overrideWithValue(_FakeContent())],
      child: MaterialApp(theme: AppTheme.light, home: const GlossaryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _search => find.byKey(const ValueKey('glossary-search'));

void main() {
  testWidgets('lists every term A to Z, grouped by letter', (tester) async {
    await _pump(tester);

    expect(find.text('Ace'), findsOneWidget);
    expect(find.text('Antenna'), findsOneWidget);
    expect(find.text('Rotation'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ace')).dy,
      lessThan(tester.getTopLeft(find.text('Rotation')).dy),
    );
  });

  testWidgets('filters by name as you type', (tester) async {
    await _pump(tester);
    await tester.enterText(_search, 'rot');
    await tester.pump();

    expect(find.text('Rotation'), findsOneWidget);
    expect(find.text('Ace'), findsNothing);
  });

  testWidgets('filters by definition text too', (tester) async {
    await _pump(tester);
    await tester.enterText(_search, 'crossing');
    await tester.pump();

    expect(find.text('Antenna'), findsOneWidget);
    expect(find.text('Rotation'), findsNothing);
  });

  testWidgets('shows a message when nothing matches', (tester) async {
    await _pump(tester);
    await tester.enterText(_search, 'zzz');
    await tester.pump();

    expect(
      find.text('No terms match "zzz". Try a different word.'),
      findsOneWidget,
    );
  });
}
