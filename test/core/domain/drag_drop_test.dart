import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/data/course_parser.dart';
import 'package:six_on_six/core/domain/course.dart';

Map<String, Object?> _courseWith(Map<String, Object?> question) => {
  'schemaVersion': 1,
  'units': [
    {
      'id': 'u1',
      'title': 't',
      'description': 'd',
      'lessons': [
        {
          'id': 'u1.l1',
          'title': 't',
          'cards': <Object?>[],
          'questions': [question],
        },
      ],
    },
  ],
};

void main() {
  group('drag-and-drop', () {
    test('placements encode the same way whatever order they are in', () {
      expect(
        Question.encodePlacements({'S': 1, 'OH1': 2, 'MB1': 3}),
        Question.encodePlacements({'MB1': 3, 'S': 1, 'OH1': 2}),
      );
      expect(Question.encodePlacements({'S': 1, 'OH1': 2}), 'OH1=2|S=1');
    });

    test('the parser reads placements and grades exact placement only', () {
      final course = parseCourse(
        _courseWith({
          'id': 'q',
          'type': 'drag',
          'prompt': 'p',
          'placements': {'S': 1, 'OH1': 2},
          'explanation': 'e',
          'concepts': ['rotating'],
        }),
      );
      final q = course.units.first.lessons.first.questions.first;
      expect(q.type, QuestionType.dragDrop);
      expect(q.placements, {'S': 1, 'OH1': 2});
      expect(
        q.isCorrect(Question.encodePlacements({'OH1': 2, 'S': 1})),
        isTrue,
      );
      expect(
        q.isCorrect(Question.encodePlacements({'S': 2, 'OH1': 1})),
        isFalse,
      );
      expect(q.isCorrect(Question.encodePlacements({'S': 1})), isFalse);
    });

    test('a zone outside 1 to 6 is rejected', () {
      expect(
        () => parseCourse(
          _courseWith({
            'id': 'q',
            'type': 'drag',
            'prompt': 'p',
            'placements': {'S': 7},
            'explanation': 'e',
            'concepts': ['c'],
          }),
        ),
        throwsA(isA<ContentFormatException>()),
      );
    });

    test('a drag question with no placements is rejected', () {
      expect(
        () => parseCourse(
          _courseWith({
            'id': 'q',
            'type': 'drag',
            'prompt': 'p',
            'explanation': 'e',
            'concepts': ['c'],
          }),
        ),
        throwsA(isA<ContentFormatException>()),
      );
    });

    test('bundled drag questions put one token per zone, libero at the '
        'back', () {
      final course = parseCourse(
        jsonDecode(File('assets/content/course.json').readAsStringSync())
            as Map<String, Object?>,
      );
      final drags = [
        for (final unit in course.units)
          for (final lesson in unit.lessons)
            for (final q in lesson.questions)
              if (q.type == QuestionType.dragDrop) q,
      ];
      expect(drags, isNotEmpty);
      for (final q in drags) {
        final zones = q.placements.values.toList();
        expect(zones.toSet().length, zones.length, reason: q.id);
        final libero = q.placements['L'];
        if (libero != null) expect([5, 6, 1], contains(libero), reason: q.id);
      }
    });
  });
}
