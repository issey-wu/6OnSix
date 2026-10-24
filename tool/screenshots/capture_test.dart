// Renders real app screens to PNG for reports and design reviews.
// Not part of CI (it needs the Mac's system fonts). Run on the Mac with:
//   flutter test tool/screenshots/capture_test.dart --update-goldens
// Images are written to build/screens/.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/router.dart';
import 'package:six_on_six/core/data/course_parser.dart';
import 'package:six_on_six/core/domain/course.dart';

Future<void> _loadFonts() async {
  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());
  const supplemental = '/System/Library/Fonts/Supplemental';
  final text = FontLoader('Roboto')
    ..addFont(bytes('$supplemental/Arial.ttf'))
    ..addFont(bytes('$supplemental/Arial Bold.ttf'));
  await text.load();
  final root = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      bytes(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    );
  await icons.load();
}

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1179, 2556)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SixOnSixApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(SixOnSixApp),
    matchesGoldenFile('../../build/screens/$name.png'),
  );
}

Course _course() => parseCourse(
  jsonDecode(File('assets/content/course.json').readAsStringSync())
      as Map<String, Object?>,
);

Future<void> _answer(WidgetTester tester, Question q) async {
  switch (q.type) {
    case QuestionType.multipleChoice:
      await tester.tap(find.text(q.answer));
    case QuestionType.trueFalse:
      await tester.tap(find.text(q.answerLabel));
    case QuestionType.tapZone:
      const order = [4, 3, 2, 5, 6, 1];
      final index = order.indexOf(int.parse(q.answer));
      await tester.tap(find.bySemanticsLabel('Court zone').at(index));
    case QuestionType.matching:
      for (final pair in q.pairs) {
        await tester.tap(find.text(pair.left));
        await tester.pump();
        await tester.tap(find.text(pair.right));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      return;
  }
  await tester.pumpAndSettle();
  await tester.tap(find.text('Check'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('learning path', (tester) async {
    final container = await _pumpApp(tester);
    container.read(progressProvider.notifier)
      ..complete(nodeId: 'u1.l1', isReview: false, perfect: true)
      ..complete(nodeId: 'u1.l2', isReview: false, perfect: false);
    await _shot(tester, '01_learning_path');
  });

  testWidgets('lesson flow', (tester) async {
    final container = await _pumpApp(tester);
    final lesson = _course().units.first.lessons.first;
    container.read(routerProvider).go('/lesson/${lesson.id}');
    await _shot(tester, '02_teaching_card');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final first = lesson.questions.first;
    await tester.tap(find.text(first.answer));
    await _shot(tester, '03_multiple_choice');
    await tester.tap(find.text('Check'));
    await _shot(tester, '04_correct_feedback');
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();

    final second = lesson.questions[1];
    await _answer(tester, second);
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();

    // Third question is tap the zone: answer it wrong on purpose.
    await tester.tap(find.bySemanticsLabel('Court zone').at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await _shot(tester, '05_court_wrong_answer');
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();

    for (final q in [...lesson.questions.skip(3), lesson.questions[2]]) {
      await _answer(tester, q);
      await tester.tap(find.text('Continue').last);
      await tester.pumpAndSettle();
    }
    await _shot(tester, '06_lesson_complete');
  });

  testWidgets('matching', (tester) async {
    final container = await _pumpApp(tester);
    final lesson = _course().units.first.lessons[1];
    container.read(routerProvider).go('/lesson/${lesson.id}');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    final pairs = lesson.questions.first.pairs;
    await tester.tap(find.text(pairs[0].left));
    await tester.pump();
    await tester.tap(find.text(pairs[0].right));
    await tester.pump();
    await tester.tap(find.text(pairs[1].left));
    await _shot(tester, '07_matching');
  });
}
