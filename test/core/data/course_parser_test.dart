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
      expect(
        course.path.where((n) => n.isReview && !n.isFinal).length,
        course.units.length,
      );
      expect(course.path.last.id, Course.finalReviewId);
      expect(course.path.where((n) => n.isFinal), hasLength(1));
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

  test('the final review draws from more than one unit', () {
    final course = parseCourse(
      jsonDecode(File('assets/content/course.json').readAsStringSync())
          as Map<String, Object?>,
    );
    final review = course.finalReviewQuestions(count: 12, seed: 3);
    expect(review, hasLength(12));
    expect(review.toSet(), hasLength(12));
    final unitsUsed = {
      for (final q in review)
        course.units
            .firstWhere((u) => u.lessons.any((l) => l.questions.contains(q)))
            .id,
    };
    expect(unitsUsed.length, greaterThan(1));
  });

  test('terms for a question come from its concepts and its words', () {
    final course = parseCourse(
      jsonDecode(File('assets/content/course.json').readAsStringSync())
          as Map<String, Object?>,
    );
    final q = course.questionById('u3.l3.q07')!;
    final terms = course.termsFor(q, '${q.prompt} ${q.explanation}');
    expect(terms.first.id, 'libero');
    expect(terms.length, lessThanOrEqualTo(3));
    expect(course.lessonOf(q)!.id, 'u3.l3');
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
