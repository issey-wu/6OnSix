import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/features/lesson/presentation/show_me_how.dart';

void main() {
  test('drag-and-drop steps place each player, then explain', () {
    const q = Question(
      id: 'd',
      type: QuestionType.dragDrop,
      prompt: 'p',
      explanation: 'The opposite is three zones away. So zone 4.',
      tokens: ['S', 'OPP'],
      answer: 'S=1|OPP=4',
    );
    expect(howToSteps(q), [
      'Setter (S) goes in zone 1, back right.',
      'Opposite (OPP) goes in zone 4, front left.',
      'The opposite is three zones away.',
      'So zone 4.',
    ]);
  });

  test('tap the zone steps name the zone first', () {
    const q = Question(
      id: 't',
      type: QuestionType.tapZone,
      prompt: 'p',
      explanation: 'The server stands behind zone 1.',
      answer: '1',
    );
    expect(howToSteps(q).first, 'Zone 1 is back right.');
  });

  test('multiple choice steps are the explanation sentences', () {
    const q = Question(
      id: 'm',
      type: QuestionType.multipleChoice,
      prompt: 'p',
      explanation: 'The court is 18 m long. Each side is 9 m square!',
      answer: 'a',
    );
    expect(howToSteps(q), [
      'The court is 18 m long.',
      'Each side is 9 m square!',
    ]);
  });
}
