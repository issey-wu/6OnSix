// Renders real app screens to PNG for reports and design reviews.
// Not part of CI (it needs the Mac's system fonts). Run on the Mac with:
//   dart run tool/check.dart --screens
// Images are written to build/screens/.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/router.dart';
import 'package:six_on_six/core/data/course_parser.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:six_on_six/core/ui/court_view.dart';

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

final _returning = StoredState(
  name: 'Issey',
  settings: const AppSettings(welcomeSeen: true),
  progress: const Progress()
      .complete(
        nodeId: 'u1.l1',
        xpEarned: 15,
        localNow: DateTime(2026, 11, 1, 19),
      )
      .complete(
        nodeId: 'u1.l2',
        xpEarned: 10,
        localNow: DateTime(2026, 11, 2, 19),
      ),
);

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  StoredState? state,
  bool dark = false,
}) async {
  tester.view
    ..physicalSize = const Size(1179, 2556)
    ..devicePixelRatio = 3;
  tester.platformDispatcher
    ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    )
    ..platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final initial = state ?? _returning;
  final container = ProviderContainer(
    overrides: [
      initialStateProvider.overrideWithValue(initial),
      progressRepositoryProvider.overrideWithValue(
        InMemoryProgressRepository(initial),
      ),
    ],
  );
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _continue(WidgetTester tester) =>
    _tap(tester, find.text('Continue').last);

Future<void> _answer(WidgetTester tester, Question q) async {
  switch (q.type) {
    case QuestionType.multipleChoice:
      await _tap(tester, find.text(q.answer));
    case QuestionType.trueFalse:
      await _tap(tester, find.text(q.answerLabel));
    case QuestionType.tapZone:
      final zone = int.parse(q.answer);
      await _tap(
        tester,
        find.bySemanticsLabel(
          RegExp(courtZoneNames[zone]!, caseSensitive: false),
        ),
      );
    case QuestionType.matching:
      for (final pair in q.pairs) {
        await _tap(tester, find.text(pair.left));
        await _tap(tester, find.text(pair.right));
      }
      return;
    case QuestionType.dragDrop:
      for (final MapEntry(key: token, value: zone) in q.placements.entries) {
        await _tap(tester, find.bySemanticsLabel('Player $token'));
        await _tap(tester, find.bySemanticsLabel(RegExp('^Zone $zone,')));
      }
  }
  await _tap(tester, find.text('Check'));
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('welcome', (tester) async {
    await _pumpApp(tester, state: const StoredState());
    await _shot(tester, '01_welcome');
  });

  testWidgets('learning path and node card', (tester) async {
    await _pumpApp(tester);
    await _shot(tester, '02_learning_path');
    await _tap(tester, find.byIcon(Icons.play_arrow_rounded));
    await _shot(tester, '03_node_card');
  });

  testWidgets('lesson flow', (tester) async {
    final container = await _pumpApp(tester);
    final lesson = _course().units.first.lessons.first;
    container.read(routerProvider).go('/lesson/${lesson.id}');
    await _shot(tester, '04_teaching_card');
    await _continue(tester);
    await _continue(tester);

    final first = lesson.questions.first;
    await _tap(tester, find.text(first.answer));
    await _shot(tester, '05_multiple_choice');
    await _tap(tester, find.text('Check'));
    await _shot(tester, '06_correct_feedback');
    await _continue(tester);

    await _answer(tester, lesson.questions[1]);
    await _continue(tester);

    // Third question is tap the zone: answer it wrong on purpose.
    await _tap(tester, find.bySemanticsLabel('Front left'));
    await _tap(tester, find.text('Check'));
    await _shot(tester, '07_court_wrong_answer');
    await _continue(tester);

    for (final q in [...lesson.questions.skip(3), lesson.questions[2]]) {
      await _answer(tester, q);
      await _continue(tester);
    }
    await _shot(tester, '08_lesson_complete');
  });

  testWidgets('drag and drop', (tester) async {
    final container = await _pumpApp(tester);
    final lesson = _course().units.last.lessons.first;
    container.read(routerProvider).go('/lesson/${lesson.id}');
    await tester.pumpAndSettle();
    await _continue(tester);
    await _continue(tester);
    final drag = lesson.questions.indexWhere(
      (q) => q.type == QuestionType.dragDrop,
    );
    for (final q in lesson.questions.take(drag)) {
      await _answer(tester, q);
      await _continue(tester);
    }
    await _tap(tester, find.bySemanticsLabel('Player S'));
    await _shot(tester, '09_drag_and_drop');
  });

  testWidgets('matching', (tester) async {
    final container = await _pumpApp(tester);
    final lesson = _course().units.first.lessons[1];
    container.read(routerProvider).go('/lesson/${lesson.id}');
    await tester.pumpAndSettle();
    await _continue(tester);
    await _continue(tester);
    final pairs = lesson.questions.first.pairs;
    await _tap(tester, find.text(pairs[0].left));
    await _tap(tester, find.text(pairs[0].right));
    await _tap(tester, find.text(pairs[1].left));
    await _shot(tester, '10_matching');
  });

  testWidgets('glossary', (tester) async {
    await _pumpApp(tester);
    await _tap(tester, find.text('Glossary'));
    await _shot(tester, '11_glossary');
    await tester.enterText(find.byType(TextField), 'libero');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Libero').last);
    await _shot(tester, '12_term_detail');
  });

  testWidgets('profile and settings, dark theme', (tester) async {
    await _pumpApp(tester, dark: true);
    await _tap(tester, find.text('Profile'));
    await _shot(tester, '13_profile_dark');
    await _tap(tester, find.byTooltip('Settings'));
    await _shot(tester, '14_settings_dark');
  });
}
