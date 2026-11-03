import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/data/course_parser.dart';
import 'package:six_on_six/core/domain/course.dart';

void main() {
  test(
    'the bundled course parses and every lesson has cards and questions',
    () {
      final json = jsonDecode(
        File('assets/content/course.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final course = parseCourse(json);
      expect(course.units, isNotEmpty);
      for (final unit in course.units) {
        for (final lesson in unit.lessons) {
          expect(lesson.cards, isNotEmpty, reason: lesson.id);
          expect(lesson.questions, isNotEmpty, reason: lesson.id);
        }
      }
      expect(course.path.where((n) => n.isReview).length, course.units.length);
    },
  );

  test('unit reviews draw questions from across the unit', () {
    final json = jsonDecode(
      File('assets/content/course.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final course = parseCourse(json);
    final unit = course.units.first;
    final review = course.reviewQuestions(unit, count: 8, seed: 1);
    expect(review.length, 8);
    expect(review.toSet().length, 8);
    final lessonsUsed = {
      for (final q in review)
        unit.lessons.firstWhere((l) => l.questions.contains(q)).id,
    };
    expect(lessonsUsed.length, greaterThan(1));
  });

  test('an unknown schema version is rejected', () {
    expect(
      () => parseCourse({'schemaVersion': 99, 'units': <Object?>[]}),
      throwsA(isA<ContentFormatException>()),
    );
  });

  test('an unknown question type is rejected', () {
    final json = {
      'schemaVersion': 2,
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
              'questions': [
                {
                  'id': 'q',
                  'type': 'essay',
                  'prompt': 'p',
                  'explanation': 'e',
                  'concepts': ['c'],
                },
              ],
            },
          ],
        },
      ],
    };
    expect(() => parseCourse(json), throwsA(isA<ContentFormatException>()));
  });

  test('question answer labels read naturally', () {
    const tf = Question(
      id: 'q',
      type: QuestionType.trueFalse,
      prompt: 'p',
      explanation: 'e',
      answer: 'false',
    );
    expect(tf.answerLabel, 'False');
  });
}
