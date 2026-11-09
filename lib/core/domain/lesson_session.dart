import 'dart:collection';

import 'package:six_on_six/core/domain/course.dart';

/// Runs one lesson under the complete-until-correct rule.
///
/// A wrong answer moves the question to the end of the queue. The lesson
/// ends once every question has been answered correctly once, so nobody can
/// fail, and [progress] only ever goes up.
class LessonSession {
  new(List<Question> questions)
    : total = questions.length,
      _queue = Queue.of(questions);

  final int total;
  final Queue<Question> _queue;
  final Set<String> _missed = {};
  int _correct = 0;
  bool _hintUsed = false;

  Question? get current => _queue.isEmpty ? null : _queue.first;

  bool get isComplete => _queue.isEmpty;

  /// Share of questions answered correctly so far, from 0 to 1.
  double get progress => total == 0 ? 1 : _correct / total;

  /// True if no question was missed and no hint was used.
  bool get isPerfect => _missed.isEmpty && !_hintUsed;

  /// Whether a hint was used anywhere in this lesson.
  bool get hintUsed => _hintUsed;

  /// Records that a hint was used. A hint never counts as a wrong answer;
  /// it only removes the perfect-lesson bonus.
  void useHint() => _hintUsed = true;

  /// Questions answered correctly on the first try, divided by the total.
  double get accuracy => total == 0 ? 1 : (total - _missed.length) / total;

  /// Records an answer to the current question.
  void submit({required bool correct}) {
    final question = _queue.removeFirst();
    if (correct) {
      _correct++;
    } else {
      _missed.add(question.id);
      _queue.addLast(question);
    }
  }

  /// Records a finished matching question. A wrong pairing only removes the
  /// perfect bonus; the question is not asked again.
  void submitMatching({required bool hadMistake}) {
    final question = _queue.removeFirst();
    _correct++;
    if (hadMistake) _missed.add(question.id);
  }
}
