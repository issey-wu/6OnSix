import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/course.dart';

Question _q(String id) => Question(
  id: id,
  type: QuestionType.trueFalse,
  prompt: id,
  explanation: '',
  answer: 'true',
);

TeachingCard _card(String title, [List<String> check = const []]) =>
    TeachingCard(title: title, body: '', check: check);

Lesson _lesson(List<TeachingCard> cards) => Lesson(
  id: 'l',
  title: 'L',
  cards: cards,
  questions: [_q('a'), _q('b'), _q('c'), _q('d')],
);

void main() {
  test('each card is followed by the questions it checks', () {
    final plan = _lesson([
      _card('one', ['b']),
      _card('two', ['a', 'd']),
    ]).interleaved();
    expect([for (final q in plan.questions) q.id], ['b', 'a', 'd', 'c']);
    expect(plan.cardsBefore, {
      'b': [0],
      'a': [1],
    });
  });

  test('a card that checks nothing shows with the next one', () {
    final plan = _lesson([
      _card('one'),
      _card('two', ['c']),
      _card('three'),
    ]).interleaved();
    expect([for (final q in plan.questions) q.id], ['c', 'a', 'b', 'd']);
    expect(plan.cardsBefore, {
      'c': [0, 1],
      'a': [2],
    });
  });

  test('without any checks, every card comes first, as before', () {
    final plan = _lesson([_card('one'), _card('two')]).interleaved();
    expect([for (final q in plan.questions) q.id], ['a', 'b', 'c', 'd']);
    expect(plan.cardsBefore, {
      'a': [0, 1],
    });
  });

  test('a last card with every question placed goes before the last one', () {
    final plan = _lesson([
      _card('one', ['a', 'b', 'c', 'd']),
      _card('two'),
    ]).interleaved();
    expect(plan.cardsBefore, {
      'a': [0],
      'd': [1],
    });
  });

  test('an unknown or repeated id is ignored', () {
    final plan = _lesson([
      _card('one', ['zz', 'a']),
      _card('two', ['a', 'b']),
    ]).interleaved();
    expect([for (final q in plan.questions) q.id], ['a', 'b', 'c', 'd']);
    expect(plan.cardsBefore, {
      'a': [0],
      'b': [1],
    });
  });
}
