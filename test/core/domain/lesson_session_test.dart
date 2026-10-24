import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/lesson_session.dart';

Question _q(String id, [QuestionType type = QuestionType.trueFalse]) =>
    Question(id: id, type: type, prompt: id, explanation: 'x', answer: 'true');

void main() {
  group('LessonSession', () {
    test('a wrong answer sends the question to the end of the queue', () {
      final session = LessonSession([_q('a'), _q('b')])..submit(correct: false);
      expect(session.current!.id, 'b');
      session.submit(correct: true);
      expect(session.current!.id, 'a');
      expect(session.isComplete, isFalse);
    });

    test('the lesson ends once every question is answered correctly', () {
      final session = LessonSession([_q('a'), _q('b')])
        ..submit(correct: false)
        ..submit(correct: true)
        ..submit(correct: true);
      expect(session.isComplete, isTrue);
      expect(session.isPerfect, isFalse);
      expect(session.accuracy, 0.5);
    });

    test('progress never moves backward', () {
      final session = LessonSession([_q('a'), _q('b'), _q('c')]);
      var last = session.progress;
      for (final correct in [true, false, false, true, true]) {
        session.submit(correct: correct);
        expect(session.progress, greaterThanOrEqualTo(last));
        last = session.progress;
      }
      expect(session.isComplete, isTrue);
      expect(session.progress, 1);
    });

    test(
      'a matching mistake removes the perfect bonus but is not re-asked',
      () {
        final session = LessonSession([_q('m', QuestionType.matching)])
          ..submitMatching(hadMistake: true);
        expect(session.isComplete, isTrue);
        expect(session.isPerfect, isFalse);
      },
    );
  });
}
