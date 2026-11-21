// Renders real app screens to PNG for reports and design reviews.
// Not part of CI. Run it with:
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
import 'package:six_on_six/core/domain/avatar.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/league.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/features/welcome/presentation/welcome_screen.dart';

Future<void> _loadFonts() async {
  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());
  // The app's own font, bundled in assets/fonts.
  final nunito = FontLoader('Nunito');
  for (final weight in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
    nunito.addFont(bytes('assets/fonts/Nunito-$weight.ttf'));
  }
  await nunito.load();
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
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _continue(WidgetTester tester) =>
    _tap(tester, find.text('Continue').last);

/// Taps through every teaching card to the first question.
Future<void> _throughCards(WidgetTester tester, Lesson lesson) async {
  for (var i = 0; i < lesson.cards.length; i++) {
    await _continue(tester);
  }
}

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
        await _tap(tester, find.byKey(ValueKey('token-$token')));
        await _tap(tester, find.byKey(ValueKey('zone-$zone')));
      }
  }
  await _tap(tester, find.text('Check'));
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('welcome', (tester) async {
    await _pumpApp(tester, state: const StoredState());
    // Images decode outside the test's fake clock.
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(appLogoAsset),
        tester.element(find.byType(WelcomeScreen)),
      ),
    );
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
    await _throughCards(tester, lesson);

    // An easy true or false first, then multiple choice.
    await _answer(tester, lesson.questions[0]);
    await _continue(tester);
    final mc = lesson.questions[1];
    await _tap(tester, find.text(mc.answer));
    await _shot(tester, '05_multiple_choice');
    await _tap(tester, find.text('Check'));
    await _shot(tester, '06_correct_feedback');
    await _continue(tester);

    // Third question is tap the zone. The hint numbers one other zone;
    // then answer it wrong on purpose.
    await _tap(tester, find.byKey(const ValueKey('hint')));
    await _shot(tester, '31_tap_zone_hint');
    await _tap(
      tester,
      find.bySemanticsLabel(RegExp('front left', caseSensitive: false)),
    );
    await _tap(tester, find.text('Check'));
    await _shot(tester, '07_court_wrong_answer');
    await _continue(tester);

    for (final q in [...lesson.questions.skip(3), lesson.questions[2]]) {
      await _answer(tester, q);
      await _continue(tester);
    }
    await _shot(tester, '08_lesson_complete');
  });

  testWidgets('teaching card diagrams', (tester) async {
    final container = await _pumpApp(tester);
    final course = _course();
    final shots = {
      (0, 0, 2): '26_card_attack_line',
      (0, 0, 3): '27_card_zones',
      (0, 0, 6): '28_card_zone_1',
      (0, 1, 0): '29_card_roles',
      (0, 2, 1): '30_card_rotation',
    };
    for (final MapEntry(key: (unit, lesson, card), value: name)
        in shots.entries) {
      final id = course.units[unit].lessons[lesson].id;
      container.read(routerProvider).go('/learn');
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/lesson/$id');
      await tester.pumpAndSettle();
      for (var i = 0; i < card; i++) {
        await _continue(tester);
      }
      await _shot(tester, name);
    }
  });

  testWidgets('drag and drop', (tester) async {
    final container = await _pumpApp(tester);
    final lesson = _course().units.last.lessons.first;
    container.read(routerProvider).go('/lesson/${lesson.id}');
    await tester.pumpAndSettle();
    await _throughCards(tester, lesson);
    final drag = lesson.questions.indexWhere(
      (q) => q.type == QuestionType.dragDrop,
    );
    for (final q in lesson.questions.take(drag)) {
      await _answer(tester, q);
      await _continue(tester);
    }
    await _tap(tester, find.byKey(const ValueKey('token-S')));
    await _shot(tester, '09_drag_and_drop');

    // Answer it wrong to show the correct arrangement in the panel.
    final q = lesson.questions[drag];
    final zones = [for (final t in q.tokens) q.placements[t]!].reversed
        .toList();
    for (final (i, token) in q.tokens.indexed) {
      if (i > 0) await _tap(tester, find.byKey(ValueKey('token-$token')));
      await _tap(tester, find.byKey(ValueKey('zone-${zones[i]}')));
    }
    await _tap(tester, find.text('Check'));
    await _shot(tester, '15_drag_wrong_answer');
  });

  testWidgets('hint and show me how', (tester) async {
    final container = await _pumpApp(tester);
    final lesson = _course().units.first.lessons.first;
    container.read(routerProvider).go('/lesson/${lesson.id}');
    await tester.pumpAndSettle();
    await _throughCards(tester, lesson);
    await _answer(tester, lesson.questions[0]);
    await _continue(tester);
    await _tap(tester, find.byKey(const ValueKey('hint')));
    await _shot(tester, '16_hint');

    final first = lesson.questions[1];
    final wrong = first.options.firstWhere(
      (o) => o != first.answer && find.text(o).evaluate().isNotEmpty,
    );
    await _tap(tester, find.text(wrong));
    await _tap(tester, find.text('Check'));
    await _tap(tester, find.byKey(const ValueKey('show-me-how')));
    await _shot(tester, '17_show_me_how');
  });

  testWidgets('show me how with a rotation', (tester) async {
    final container = await _pumpApp(tester);
    final lesson = _course().units.first.lessons[2];
    container.read(routerProvider).go('/lesson/${lesson.id}');
    await tester.pumpAndSettle();
    await _throughCards(tester, lesson);
    await _answer(tester, lesson.questions.first);
    await _tap(tester, find.byKey(const ValueKey('show-me-how')));
    await _shot(tester, '32_show_me_how_rotation');
  });

  testWidgets('show me how on a court question', (tester) async {
    final container = await _pumpApp(tester);
    final lesson = _course().units.last.lessons.first;
    container.read(routerProvider).go('/lesson/${lesson.id}');
    await tester.pumpAndSettle();
    await _throughCards(tester, lesson);
    final drag = lesson.questions.indexWhere(
      (q) => q.type == QuestionType.dragDrop,
    );
    for (final q in lesson.questions.take(drag)) {
      await _answer(tester, q);
      await _continue(tester);
    }
    await _answer(tester, lesson.questions[drag]);
    await _tap(tester, find.byKey(const ValueKey('show-me-how')));
    await _shot(tester, '18_show_me_how_court');
  });

  testWidgets('final review and weak spots', (tester) async {
    final course = _course();
    final allButFinal = {
      for (final node in course.path)
        if (!node.isFinal) node.id,
    };
    final missed = [
      for (final q in course.allQuestions.take(4)) ...[
        (q.id, false),
        (q.id, true),
      ],
    ];
    await _pumpApp(
      tester,
      state: StoredState(
        name: 'Issey',
        settings: const AppSettings(welcomeSeen: true),
        progress: Progress(
          completed: allButFinal,
          xp: 400,
          streak: 3,
          lastActiveDay: DateTime.utc(2026, 11, 8),
        ),
        answerStats: const AnswerStats().withResults(missed),
      ),
    );
    await tester.scrollUntilVisible(find.byIcon(Icons.workspace_premium), 300);
    await _shot(tester, '19_final_review');
    await tester.scrollUntilVisible(find.text('Practice weak spots'), -300);
    await _shot(tester, '20_weak_spots');
  });

  testWidgets('daily goal and quests', (tester) async {
    final container = await _pumpApp(tester, state: const StoredState());
    container.read(routerProvider).go('/goal');
    await _shot(tester, '21_daily_goal');

    final local = DateTime.now();
    final state = StoredState(
      name: 'Issey',
      settings: const AppSettings(welcomeSeen: true),
      progress: _returning.progress,
      motivation: MotivationState(
        goalChosen: true,
        freezes: 1,
        days: {
          dayKey(local): const DayStats(
            xp: 15,
            lessons: 1,
            perfectLessons: 1,
            bestCombo: 5,
            glossaryViews: 1,
            courtCorrect: 2,
          ),
        },
      ),
    );
    final second = await _pumpApp(tester, state: state);
    second.read(routerProvider).go('/quests');
    await _shot(tester, '22_quests');
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

  testWidgets('avatar builder and profile', (tester) async {
    final container = await _pumpApp(tester);
    container.read(routerProvider).go('/avatar');
    await tester.pumpAndSettle();
    await _shot(tester, '23_avatar_presets');
    await _tap(tester, find.text('Build your own'));
    await _tap(tester, find.byKey(const ValueKey('hair-curly')));
    await _tap(tester, find.byKey(const ValueKey('jersey-0')));
    await _shot(tester, '24_avatar_builder');
    // Saving returns to the Profile tab.
    await _tap(tester, find.byKey(const ValueKey('save-avatar')));
    await _shot(tester, '25_profile_avatar');
  });

  testWidgets('league and friends', (tester) async {
    final now = DateTime.now();
    final joined = StoredState(
      name: 'Issey',
      settings: const AppSettings(welcomeSeen: true),
      avatar: avatarPresets[8],
      league: const LeagueState(division: Division.club).addXp(140, now),
    );
    var container = await _pumpApp(tester, state: joined);
    container.read(routerProvider).go('/league');
    await tester.pumpAndSettle();
    await _shot(tester, '33_league');
    final friend = find.byKey(ValueKey(demoFriends.first.id));
    await tester.scrollUntilVisible(friend, 300);
    await _tap(tester, friend);
    await _shot(tester, '34_friend');

    final finished = StoredState(
      name: 'Issey',
      settings: const AppSettings(welcomeSeen: true),
      avatar: avatarPresets[8],
      league: const LeagueState(division: Division.club)
          .addXp(900, now)
          .settle(now, force: true),
    );
    container = await _pumpApp(tester, state: finished);
    container.read(routerProvider).go('/league');
    await tester.pumpAndSettle();
    await _shot(tester, '35_league_result');
    await _tap(tester, find.byKey(const ValueKey('league-result-ok')));
    await _shot(tester, '36_league_join');
  });

  testWidgets('profile and settings, dark theme', (tester) async {
    await _pumpApp(tester, dark: true);
    await _tap(tester, find.text('Profile'));
    await _shot(tester, '13_profile_dark');
    await _tap(tester, find.byTooltip('Settings'));
    await _shot(tester, '14_settings_dark');
  });
}
