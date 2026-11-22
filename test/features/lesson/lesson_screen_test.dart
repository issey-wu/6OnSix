import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/router.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/content_repository.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:six_on_six/core/ui/ace.dart';
import 'package:six_on_six/core/ui/components.dart';
import 'package:six_on_six/core/ui/player_token.dart';

const _card = TeachingCard(title: 'Card', body: 'Body');

const _mc = Question(
  id: 'q1',
  type: QuestionType.multipleChoice,
  prompt: 'Pick A.',
  explanation: 'A is right. The rest are not.',
  options: ['A', 'B', 'C', 'D'],
  answer: 'A',
);
const _tf = Question(
  id: 'q2',
  type: QuestionType.trueFalse,
  prompt: 'The libero can serve.',
  explanation: 'Under FIVB rules the libero may not serve.',
  answer: 'false',
  concepts: ['libero'],
);
const _zone = Question(
  id: 'q3',
  type: QuestionType.tapZone,
  prompt: 'Tap zone 4.',
  explanation: 'Zone 4 is front left.',
  answer: '4',
);
const _drag = Question(
  id: 'q4',
  type: QuestionType.dragDrop,
  prompt: 'Place them.',
  explanation: 'Opposites are three zones apart.',
  tokens: ['S', 'OPP'],
  answer: 'S=1|OPP=4',
);
const _short = Question(
  id: 'q5',
  type: QuestionType.trueFalse,
  prompt: 'Six players are on court.',
  explanation: 'Each team has six players on court.',
  answer: 'true',
);

const _course = Course(
  schemaVersion: 2,
  units: [
    Unit(
      id: 'u1',
      title: 'Unit one',
      description: 'd',
      lessons: [
        Lesson(
          id: 'u1.l1',
          title: 'Mixed',
          cards: [_card],
          questions: [_mc, _tf, _zone, _drag],
        ),
        Lesson(
          id: 'u1.l2',
          title: 'Short',
          cards: [_card],
          questions: [_short],
        ),
      ],
    ),
  ],
  glossary: [
    GlossaryTerm(
      id: 'libero',
      term: 'Libero',
      definition: 'A back-row defender in a different coloured jersey.',
    ),
  ],
);

class _FakeContent implements ContentRepository {
  @override
  Future<Course> loadCourse() async => _course;
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String? location,
  StoredState state = const StoredState(
    settings: AppSettings(welcomeSeen: true, tipsSeen: Tips.all),
  ),
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final container = ProviderContainer(
    overrides: [
      initialStateProvider.overrideWithValue(state),
      progressRepositoryProvider.overrideWithValue(
        InMemoryProgressRepository(state),
      ),
      contentRepositoryProvider.overrideWithValue(_FakeContent()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SixOnSixApp()),
  );
  await tester.pumpAndSettle();
  if (location != null) {
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  // Let the scroll land before tapping, so the tap hits the widget.
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Taps through the teaching card to the first question.
Future<void> _toQuestions(WidgetTester tester) =>
    _tap(tester, find.text('Continue'));

final Finder _hint = find.byKey(const ValueKey('hint'));

void main() {
  testWidgets('a hint on multiple choice removes one wrong answer', (
    tester,
  ) async {
    await _pump(tester, location: '/lesson/u1.l1');
    await _toQuestions(tester);
    expect(find.byType(OptionTile), findsNWidgets(4));

    await _tap(tester, _hint);
    expect(find.byType(OptionTile), findsNWidgets(3));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('One wrong answer is gone.'), findsOneWidget);
    // One hint per question.
    expect(tester.widget<IconButton>(_hint).onPressed, isNull);
  });

  testWidgets('show me how opens the step-by-step panel', (tester) async {
    await _pump(tester, location: '/lesson/u1.l1');
    await _toQuestions(tester);
    await _tap(tester, find.text('B'));
    await _tap(tester, find.text('Check'));

    await _tap(tester, find.byKey(const ValueKey('show-me-how')));
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Answer: A'), findsOneWidget);
    expect(find.text('A is right.'), findsOneWidget);

    await _tap(tester, find.text('Got it'));
    expect(find.text('How it works'), findsNothing);
  });

  testWidgets('hints for true or false, tap the zone and drag-and-drop', (
    tester,
  ) async {
    await _pump(tester, location: '/lesson/u1.l1');
    await _toQuestions(tester);
    await _tap(tester, find.text('A'));
    await _tap(tester, find.text('Check'));
    await _tap(tester, find.text('Continue').last);

    // True or false: the meaning of a key term.
    await _tap(tester, _hint);
    expect(find.textContaining('Think about Libero'), findsOneWidget);
    await _tap(tester, find.text('False'));
    await _tap(tester, find.text('Check'));
    await _tap(tester, find.text('Continue').last);

    // Tap the zone: numbers one other zone, two along from the answer, so
    // the learner counts round. The answer is zone 4, so zone 6 is named.
    await _tap(tester, _hint);
    expect(find.textContaining('This is zone 6'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Zone 6, back middle')),
      findsOneWidget,
    );
    await _tap(tester, find.bySemanticsLabel('Front left'));
    await _tap(tester, find.text('Check'));
    await _tap(tester, find.text('Continue').last);

    // Drag-and-drop: the setter is placed in zone 1 and stays there.
    await _tap(tester, _hint);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('zone-1')),
        matching: find.byType(PlayerToken),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('token-S')), findsNothing);
  });

  testWidgets('the bar fills before the complete screen, and a hint skips '
      'the perfect bonus', (tester) async {
    await _pump(tester, location: '/lesson/u1.l2');
    await _toQuestions(tester);
    await _tap(tester, _hint);
    await _tap(tester, find.text('True'));
    await _tap(tester, find.text('Check'));

    // Step through frames, noting the bar, until the complete screen shows.
    await tester.tap(find.text('Continue').last);
    double? lastBar;
    final complete = find.text('Lesson complete!');
    for (var i = 0; i < 400 && complete.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 5));
      final bar = find.byWidgetPredicate(
        (w) =>
            w is LinearProgressIndicator &&
            w.semanticsLabel == 'Lesson progress',
      );
      if (bar.evaluate().isNotEmpty) {
        lastBar = tester.widget<LinearProgressIndicator>(bar).value;
      }
    }
    expect(complete, findsOneWidget);
    expect(lastBar, 1, reason: 'the bar was full just before');

    await tester.pumpAndSettle();
    expect(find.text('Lesson complete!'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
  });

  testWidgets('Ace pops up at the first mistake and after 3 in a row', (
    tester,
  ) async {
    final ace = find.bySemanticsLabel(RegExp('^Ace says: '));
    await _pump(tester, location: '/lesson/u1.l1');
    await _toQuestions(tester);

    // A first mistake gets a word from Ace.
    await _tap(tester, find.text('B'));
    await _tap(tester, find.text('Check'));
    expect(ace, findsOneWidget);
    await _tap(tester, find.text('Continue').last);
    expect(ace, findsNothing);

    // One and two right in a row: no interruption.
    await _tap(tester, find.text('False'));
    await _tap(tester, find.text('Check'));
    expect(ace, findsNothing);
    await _tap(tester, find.text('Continue').last);
    await _tap(tester, find.bySemanticsLabel('Front left'));
    await _tap(tester, find.text('Check'));
    expect(ace, findsNothing);
    await _tap(tester, find.text('Continue').last);

    // Three in a row: Ace cheers.
    await _tap(tester, _hint);
    await _tap(tester, find.byKey(const ValueKey('token-OPP')));
    await _tap(tester, find.byKey(const ValueKey('zone-4')));
    await _tap(tester, find.text('Check'));
    expect(
      find.bySemanticsLabel(RegExp('^Ace says: (3 in a row|Three straight)')),
      findsOneWidget,
    );
  });

  testWidgets('Ace looks sad when you try to quit, and cheers at the end', (
    tester,
  ) async {
    await _pump(tester, location: '/lesson/u1.l2');
    await _toQuestions(tester);
    await _tap(tester, find.byTooltip('Quit lesson'));
    expect(find.text("Wait, don't go!"), findsOneWidget);
    expect(find.bySemanticsLabel('Ace the eagle, looking sad'), findsOneWidget);
    await _tap(tester, find.text('Keep going'));

    await _tap(tester, find.text('True'));
    await _tap(tester, find.text('Check'));
    await _tap(tester, find.text('Continue').last);
    expect(find.text('Perfect lesson!'), findsOneWidget);
    expect(find.byType(AceSays), findsOneWidget);
    // The first lesson of the day starts the streak.
    expect(find.bySemanticsLabel(RegExp('^Ace says: Day one')), findsOneWidget);
  });

  testWidgets('Ace stands by the next lesson and talks when tapped', (
    tester,
  ) async {
    await _pump(tester);
    final ace = find.byKey(const ValueKey('path-ace'));
    expect(ace, findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Ace says: ')), findsNothing);
    await _tap(tester, ace);
    expect(find.bySemanticsLabel(RegExp('^Ace says: ')), findsOneWidget);
  });

  group('first-run tips', () {
    const fresh = StoredState(settings: AppSettings(welcomeSeen: true));

    testWidgets('walk a new learner through answering, Check and Show me '
        'how, without extra taps', (tester) async {
      final container = await _pump(
        tester,
        location: '/lesson/u1.l1',
        state: fresh,
      );
      await _toQuestions(tester);
      expect(find.text('Your turn! Tap an answer.'), findsOneWidget);

      // Tapping the lit-up answers both picks one and moves the guide on.
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.text('Your turn! Tap an answer.'), findsNothing);
      expect(
        find.text("Now tap Check to see if you're right."),
        findsOneWidget,
      );

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('show-me-how')), findsOneWidget);
      expect(
        find.text('Want the why? Show me how walks you through any answer.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('tips-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tips-ok')), findsNothing);
      expect(container.read(settingsProvider).tipsSeen, {
        Tips.answer,
        Tips.check,
        Tips.showMeHow,
      });

      // The next question points out the hint.
      await _tap(tester, find.text('Continue').last);
      expect(find.textContaining('The lightbulb gives you a hint'), findsOne);
    });

    testWidgets('a first mistake is explained once', (tester) async {
      await _pump(
        tester,
        location: '/lesson/u1.l1',
        state: const StoredState(
          settings: AppSettings(
            welcomeSeen: true,
            tipsSeen: {Tips.answer, Tips.check},
          ),
        ),
      );
      await _toQuestions(tester);
      await _tap(tester, find.text('B'));
      await _tap(tester, find.text('Check'));
      expect(find.textContaining('It comes back at the end'), findsOneWidget);
      // Ace's own pop-up waits, so the two don't talk over each other.
      expect(find.bySemanticsLabel(RegExp('^Ace says: Sh')), findsNothing);
    });

    testWidgets('Skip tutorial asks, then turns every tip off', (tester) async {
      final container = await _pump(
        tester,
        location: '/lesson/u1.l1',
        state: fresh,
      );
      await _toQuestions(tester);
      // Skipping asks first; keeping the tips brings the same one back.
      await tester.tap(find.byKey(const ValueKey('tips-skip')));
      await tester.pumpAndSettle();
      expect(find.text('Skip the tutorial?'), findsOneWidget);
      await tester.tap(find.text('Keep the tips'));
      await tester.pumpAndSettle();
      expect(find.text('Your turn! Tap an answer.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tips-skip')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip tutorial'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tips-ok')), findsNothing);
      expect(container.read(settingsProvider).tipsSeen, Tips.all);
      await _tap(tester, find.text('A'));
      expect(find.byKey(const ValueKey('tips-ok')), findsNothing);
    });

    testWidgets('a tip blocks taps outside the lit-up part', (tester) async {
      await _pump(tester, location: '/lesson/u1.l1', state: fresh);
      await _toQuestions(tester);
      await tester.tap(find.byTooltip('Quit lesson'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text("Wait, don't go!"), findsNothing);
    });
  });

  testWidgets('the final review sits at the end of the path', (tester) async {
    await _pump(tester);
    await tester.scrollUntilVisible(find.text('ALL UNITS'), 200);
    expect(find.text('Final review'), findsWidgets);
  });

  testWidgets('weak spots practice appears once 3 questions are weak', (
    tester,
  ) async {
    final stats = const AnswerStats().withResults([
      for (final id in ['q1', 'q2', 'q3']) ...[(id, false), (id, true)],
    ]);
    await _pump(
      tester,
      state: StoredState(
        settings: const AppSettings(welcomeSeen: true, tipsSeen: Tips.all),
        answerStats: stats,
      ),
    );
    expect(find.text('Practice weak spots'), findsOneWidget);
    expect(find.text('3 questions you have missed before'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('weak-spots')));
    expect(find.text('Select the correct answer'), findsOneWidget);
  });
}
