import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/data/course_parser.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/features/glossary/presentation/glossary_screen.dart';

Course _course() => parseCourse(
  jsonDecode(File('assets/content/course.json').readAsStringSync())
      as Map<String, Object?>,
);

void main() {
  group('glossary', () {
    test('is sorted A to Z and every related term exists', () {
      final glossary = _course().glossary;
      expect(glossary, isNotEmpty);
      final names = [
        for (final t in glossary)
          t.term.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), ''),
      ];
      expect(names, [...names]..sort());
      final ids = glossary.map((t) => t.id).toSet();
      for (final term in glossary) {
        expect(ids.containsAll(term.related), isTrue, reason: term.id);
      }
    });

    test('search matches names and definitions, ignoring case', () {
      final glossary = _course().glossary;
      expect(
        searchGlossary(glossary, 'LIBERO').map((t) => t.id),
        contains('libero'),
      );
      expect(
        searchGlossary(glossary, 'different coloured jersey').map((t) => t.id),
        contains('libero'),
      );
      expect(searchGlossary(glossary, 'zzzz'), isEmpty);
      expect(searchGlossary(glossary, '  '), hasLength(glossary.length));
    });
  });

  group('drag-and-drop questions', () {
    final drags = [
      for (final u in _course().units)
        for (final l in u.lessons)
          for (final q in l.questions)
            if (q.type == QuestionType.dragDrop) q,
    ];

    test('exist and place every token exactly once', () {
      expect(drags, isNotEmpty);
      for (final q in drags) {
        expect(q.placements.keys.toList(), q.tokens, reason: q.id);
        expect(
          q.placements.values.toSet(),
          hasLength(q.tokens.length),
          reason: q.id,
        );
      }
    });

    test('keep the libero in the back row', () {
      for (final q in drags) {
        final libero = q.placements['L'];
        if (libero != null) expect({5, 6, 1}, contains(libero), reason: q.id);
      }
    });

    test('are graded on exact placement', () {
      final q = drags.firstWhere((q) => q.tokens.length == 2);
      expect(q.isCorrect(q.answer), isTrue);
      final zones = q.tokens.map((t) => q.placements[t]).toList().reversed;
      final swapped = [
        for (final (i, zone) in zones.indexed) '${q.tokens[i]}=$zone',
      ].join('|');
      expect(q.isCorrect(swapped), isFalse);
    });
  });
}
