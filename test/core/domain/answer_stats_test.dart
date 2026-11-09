import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/user_state.dart';

void main() {
  group('AnswerStats', () {
    test('a question missed once is weak until answered right again', () {
      // In a lesson, a miss is always followed by a right answer.
      var stats = const AnswerStats().withResults([
        ('q1', false),
        ('q1', true),
      ]);
      expect(stats.weakest(), ['q1']);

      stats = stats.withResults([('q1', true)]);
      expect(stats.weakest(), isEmpty);
    });

    test('questions never missed are never weak', () {
      final stats = const AnswerStats().withResults([
        ('q1', true),
        ('q2', true),
      ]);
      expect(stats.weakest(), isEmpty);
    });

    test('the most-missed questions come first, up to the limit', () {
      final stats = const AnswerStats().withResults([
        ('a', false),
        ('a', true),
        ('b', false),
        ('b', false),
        ('b', true),
        ('c', false),
        ('c', true),
      ]);
      expect(stats.weakest(), ['b', 'a', 'c']);
      expect(stats.weakest(limit: 2), ['b', 'a']);
      expect(stats.tally('b'), (1, 2));
    });

    test('attempts from a lesson are counted', () {
      final at = DateTime.utc(2026, 11, 9);
      final stats = const AnswerStats().withAttempts([
        AnswerAttempt(questionId: 'q', correct: false, answeredAt: at),
        AnswerAttempt(questionId: 'q', correct: true, answeredAt: at),
      ]);
      expect(stats.tally('q'), (1, 1));
    });
  });
}
