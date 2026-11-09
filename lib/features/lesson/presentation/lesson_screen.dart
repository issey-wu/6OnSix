import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/feedback.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/lesson_session.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:six_on_six/core/ui/components.dart';
import 'package:six_on_six/core/ui/court_lineup.dart';
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/features/lesson/presentation/drag_drop_view.dart';
import 'package:six_on_six/features/lesson/presentation/matching_view.dart';
import 'package:six_on_six/features/lesson/presentation/show_me_how.dart';

enum _Stage { teaching, question, complete }

/// Plays one lesson, unit review, final review or weak spots practice:
/// teaching cards, then questions under the complete-until-correct rule,
/// then the lesson complete screen.
class LessonScreen extends ConsumerStatefulWidget {
  const new({required this.nodeId, super.key});

  final String nodeId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  static const _praise = ['Nice!', 'Clean pass!', 'Ace!', 'Kill!', 'Great!'];

  late PathNode _node;
  LessonSession? _session;
  List<TeachingCard> _cards = const [];
  _Stage _stage = _Stage.teaching;
  int _cardIndex = 0;
  int _attempt = 0;
  List<String> _options = const [];
  String? _response;
  bool? _lastCorrect;
  bool _matchingMistake = false;
  String _praiseLine = _praise.first;
  int _xpEarned = 0;
  int _streakBefore = 0;

  /// True between the last answer and the complete screen, while the
  /// progress bar fills to the end.
  bool _finishing = false;

  /// The question on screen. It stays set while the bar fills after the
  /// last answer, when the session itself has no current question left.
  Question? _shown;

  // Hint state for the current question.
  bool _hintUsed = false;
  String? _hintText;
  final Set<String> _removedOptions = {};
  Set<int> _hintZones = const {};
  final List<AnswerAttempt> _answers = [];
  final _random = Random();

  void _start(Course course) {
    final rules = ref.read(gameRulesProvider);
    final PathNode? node;
    final List<Question> questions;
    if (widget.nodeId == Course.weakSpotsId) {
      final ids = ref
          .read(answerStatsProvider)
          .weakest(limit: rules.weakSpotQuestionCount);
      questions = ids.map(course.questionById).nonNulls.toList();
      node = questions.isEmpty || course.units.isEmpty
          ? null
          : PathNode(
              id: Course.weakSpotsId,
              unit: course.units.first,
              title: 'Weak spots',
            );
    } else {
      node = course.nodeById(widget.nodeId);
      final nodeLesson = node?.lesson;
      questions = node == null
          ? const []
          : node.isFinal
          ? course.finalReviewQuestions(count: rules.finalReviewQuestionCount)
          : nodeLesson == null
          ? course.reviewQuestions(node.unit, count: rules.reviewQuestionCount)
          : nodeLesson.questions;
    }
    if (node == null) return;
    final lesson = node.lesson;
    _node = node;
    _session = LessonSession(questions);
    _cards = lesson?.cards ?? const [];
    _stage = _cards.isEmpty ? _Stage.question : _Stage.teaching;
    _prepareQuestion();
  }

  void _prepareQuestion() {
    final q = _session?.current;
    _shown = q;
    _response = null;
    _lastCorrect = null;
    _matchingMistake = false;
    _hintUsed = false;
    _hintText = null;
    _removedOptions.clear();
    _hintZones = const {};
    _attempt++;
    _options = q == null ? const [] : ([...q.options]..shuffle(_random));
  }

  void _log(Question q, {required bool correct}) => _answers.add(
    AnswerAttempt(
      questionId: q.id,
      correct: correct,
      answeredAt: ref.read(clockProvider).now(),
    ),
  );

  void _check() {
    final q = _session!.current!;
    final correct = q.isCorrect(_response!);
    _log(q, correct: correct);
    ref
        .read(feedbackProvider)
        .play(correct ? FeedbackEvent.correct : FeedbackEvent.incorrect);
    setState(() {
      _lastCorrect = correct;
      _praiseLine = _praise[_random.nextInt(_praise.length)];
    });
  }

  void _matchingDone(bool hadMistake) {
    _log(_session!.current!, correct: !hadMistake);
    ref.read(feedbackProvider).play(FeedbackEvent.correct);
    setState(() {
      _matchingMistake = hadMistake;
      _lastCorrect = true;
      _praiseLine = _praise[_random.nextInt(_praise.length)];
    });
  }

  void _continue() {
    if (_finishing) return;
    final session = _session!;
    final q = session.current!;
    if (q.type == QuestionType.matching) {
      session.submitMatching(hadMistake: _matchingMistake);
    } else {
      session.submit(correct: _lastCorrect!);
    }
    setState(() {
      if (session.isComplete) {
        // Let the progress bar fill to the end first (see _topBar).
        _finishing = true;
      } else {
        _prepareQuestion();
      }
    });
  }

  void _barFilled() {
    if (!_finishing || !mounted) return;
    setState(() {
      _finishing = false;
      _finish();
    });
  }

  void _useHint(Course course) {
    final session = _session!;
    final q = session.current!;
    session.useHint();
    setState(() {
      _hintUsed = true;
      switch (q.type) {
        case QuestionType.multipleChoice:
          final wrong = [
            for (final option in _options)
              if (option != q.answer && !_removedOptions.contains(option))
                option,
          ];
          if (wrong.isNotEmpty) {
            final removed = wrong[_random.nextInt(wrong.length)];
            _removedOptions.add(removed);
            if (_response == removed) _response = null;
          }
          _hintText = 'One wrong answer is gone.';
        case QuestionType.trueFalse:
          _hintText = _trueFalseHint(course, q);
        case QuestionType.tapZone:
          final front = const {4, 3, 2}.contains(int.tryParse(q.answer));
          _hintZones = front ? const {4, 3, 2} : const {5, 6, 1};
          _hintText = front
              ? "It's in the front row, by the net."
              : "It's in the back row.";
        case QuestionType.dragDrop:
          _hintText = 'One player is placed for you.';
        case QuestionType.matching:
          _hintText = 'One pair is matched for you.';
      }
    });
  }

  /// A nudge for a true or false question: the meaning of a key term in it,
  /// or else the lesson's first teaching card.
  String _trueFalseHint(Course course, Question q) {
    final term = course.termsFor(q, q.prompt, limit: 1).firstOrNull;
    if (term != null) return 'Think about ${term.term}: ${term.definition}';
    final card = course.lessonOf(q)?.cards.firstOrNull;
    if (card != null) return '${card.title}: ${card.body}';
    return 'Read it slowly. One word, like "always" or "never", can change '
        'the answer.';
  }

  void _finish() {
    final localNow = ref.read(clockProvider).now().toLocal();
    _streakBefore = ref.read(progressProvider).streakOn(localNow);
    _xpEarned = ref
        .read(progressProvider.notifier)
        .complete(
          nodeId: _node.id,
          isReview: _node.isReview,
          perfect: _session!.isPerfect,
          answers: List.of(_answers),
        );
    ref.read(feedbackProvider).play(FeedbackEvent.complete);
    _stage = _Stage.complete;
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/learn');
    }
  }

  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit this lesson?'),
        content: const Text("Your progress in this lesson won't be saved."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    if ((quit ?? false) && mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(courseProvider).value;
    if (course == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_session == null) _start(course);
    final session = _session;
    if (session == null) {
      return const Scaffold(body: Center(child: Text('Lesson not found.')));
    }
    return PopScope(
      canPop: _stage == _Stage.complete,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_confirmQuit());
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: switch (_stage) {
            _Stage.teaching => _teaching(context, session),
            _Stage.question => _question(context, session, course),
            _Stage.complete => _complete(context, session),
          },
        ),
      ),
    );
  }

  /// The quit button, the progress bar and, on questions, the hint button.
  /// When the last question is done the bar fills to the end and holds for a
  /// moment before the complete screen shows.
  Widget _topBar(LessonSession session, {Widget? trailing}) => Padding(
    padding: EdgeInsets.fromLTRB(4, 8, trailing == null ? 16 : 4, 8),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Quit lesson',
          icon: const Icon(Icons.close),
          onPressed: _confirmQuit,
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: session.progress),
              duration: Duration(milliseconds: _finishing ? 900 : 250),
              curve: _finishing
                  ? const Interval(0, 0.5, curve: Curves.easeOut)
                  : Curves.linear,
              onEnd: _barFilled,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 14,
                semanticsLabel: 'Lesson progress',
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );

  Widget _hintButton(Course course, {required bool available}) => IconButton(
    key: const ValueKey('hint'),
    tooltip: _hintUsed ? 'Hint used' : 'Hint',
    icon: Icon(_hintUsed ? Icons.lightbulb : Icons.lightbulb_outline),
    color: AppTokens.of(context).brandOrange,
    onPressed: available ? () => _useHint(course) : null,
  );

  Widget _bottomButton({required String label, VoidCallback? onPressed}) =>
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(onPressed: onPressed, child: Text(label)),
        ),
      );

  Widget _teaching(BuildContext context, LessonSession session) {
    final card = _cards[_cardIndex];
    final text = Theme.of(context).textTheme;
    final isReplay = ref.read(progressProvider).completed.contains(_node.id);
    return Column(
      children: [
        _topBar(session),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                _node.title.toUpperCase(),
                style: text.labelLarge?.copyWith(
                  color: AppTokens.of(context).textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                header: true,
                child: Text(
                  card.title,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(card.body, style: text.bodyLarge?.copyWith(height: 1.5)),
            ],
          ),
        ),
        if (isReplay)
          TextButton(
            onPressed: () => setState(() => _stage = _Stage.question),
            child: const Text('Skip'),
          ),
        _bottomButton(
          label: 'Continue',
          onPressed: () => setState(() {
            if (_cardIndex < _cards.length - 1) {
              _cardIndex++;
            } else {
              _stage = _Stage.question;
            }
          }),
        ),
      ],
    );
  }

  Widget _question(BuildContext context, LessonSession session, Course course) {
    final q = _shown!;
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    final answered = _lastCorrect != null;
    final instruction = switch (q.type) {
      QuestionType.multipleChoice => 'Select the correct answer',
      QuestionType.trueFalse => 'True or false?',
      QuestionType.matching => 'Match the pairs',
      QuestionType.tapZone => 'Tap the correct zone',
      QuestionType.dragDrop => 'Drag players into position',
    };
    final showLineup = _lastCorrect == false && q.type == QuestionType.dragDrop;
    final title = (_lastCorrect ?? false)
        ? (_matchingMistake ? 'All matched' : _praiseLine)
        : showLineup
        ? 'Correct arrangement:'
        : 'Correct answer: ${q.answerLabel}';
    final hintText = _hintText;
    return Column(
      children: [
        _topBar(
          session,
          trailing: _hintButton(
            course,
            available: !answered && !_hintUsed && !_finishing,
          ),
        ),
        Expanded(
          child: ListView(
            key: ValueKey('${q.id}-$_attempt'),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text(
                instruction,
                style: text.labelLarge?.copyWith(color: tokens.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                q.prompt,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              // Always present, so the answer area below keeps its place in
              // the list and its state (placed players, matched pairs) when
              // a hint appears.
              if (hintText == null)
                const SizedBox.shrink()
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _HintBox(text: hintText),
                ),
              _answerArea(q, locked: answered),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
          child: answered
              ? FeedbackPanel(
                  key: const ValueKey('feedback'),
                  correct: _lastCorrect!,
                  title: title,
                  explanation: q.explanation,
                  note: q.leagueNote,
                  extra: showLineup
                      ? SizedBox(
                          width: 168,
                          child: CourtLineup(placements: q.placements),
                        )
                      : null,
                  onShowMeHow: () => unawaited(
                    showMeHow(context, question: q, course: course),
                  ),
                  onContinue: _continue,
                )
              : q.type == QuestionType.matching
              ? const SizedBox.shrink()
              : KeyedSubtree(
                  key: const ValueKey('check'),
                  child: _bottomButton(
                    label: 'Check',
                    onPressed: _response == null ? null : _check,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _answerArea(Question q, {required bool locked}) {
    void choose(String value) => setState(() => _response = value);
    switch (q.type) {
      case QuestionType.multipleChoice:
        return Column(
          children: [
            for (final option in _options)
              if (!_removedOptions.contains(option))
                OptionTile(
                  label: option,
                  selected: _response == option,
                  onTap: locked ? null : () => choose(option),
                ),
          ],
        );
      case QuestionType.trueFalse:
        return Row(
          children: [
            for (final (value, label) in [('true', 'True'), ('false', 'False')])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OptionTile(
                    label: label,
                    selected: _response == value,
                    onTap: locked ? null : () => choose(value),
                    centered: true,
                  ),
                ),
              ),
          ],
        );
      case QuestionType.tapZone:
        return CourtView(
          selectedZone: int.tryParse(_response ?? ''),
          onZoneTap: locked ? null : (zone) => choose('$zone'),
          hintZones: _hintZones,
        );
      case QuestionType.matching:
        final feedback = ref.read(feedbackProvider);
        return MatchingView(
          question: q,
          onDone: _matchingDone,
          onPairMatched: () => feedback.play(FeedbackEvent.pairMatched),
          onWrongPair: () => feedback.play(FeedbackEvent.incorrect),
          revealPair: _hintUsed,
        );
      case QuestionType.dragDrop:
        return DragDropView(
          question: q,
          locked: locked,
          hint: _hintUsed,
          onChanged: (value) => setState(() => _response = value),
          onSnap: () =>
              ref.read(feedbackProvider).play(FeedbackEvent.tokenSnapped),
        );
    }
  }

  Widget _complete(BuildContext context, LessonSession session) {
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    final progress = ref.watch(progressProvider);
    final streak = progress.streakOn(ref.read(clockProvider).now().toLocal());
    final streakGrew = streak > _streakBefore;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 72, color: tokens.brandOrange),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    switch ((session.isPerfect, _node.isReview)) {
                      (true, false) => 'Perfect lesson!',
                      (true, true) => 'Perfect review!',
                      (false, false) => 'Lesson complete!',
                      (false, true) => 'Review complete!',
                    },
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (streakGrew) ...[
                  const SizedBox(height: 12),
                  _StreakCelebration(streak: streak),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    StatCard(label: 'XP earned', value: '+$_xpEarned'),
                    StatCard(
                      label: 'Accuracy',
                      value: '${(session.accuracy * 100).round()}%',
                    ),
                    StatCard(
                      label: 'Streak',
                      value: '$streak',
                      icon: Icons.local_fire_department,
                      iconColor: tokens.brandOrange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _bottomButton(label: 'Continue', onPressed: _leave),
      ],
    );
  }
}

/// The flame grows in and shows the new streak when a lesson extends it.
class _StreakCelebration extends StatelessWidget {
  const new({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0.4, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Semantics(
        liveRegion: true,
        label: '$streak day streak',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              color: tokens.brandOrange,
              size: 36,
            ),
            Text(
              '$streak day streak!',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// The hint shown above the answers after the learner taps the lightbulb.
class _HintBox extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Hint: $text',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.selectedBg,
          border: Border.all(color: tokens.brandOrange),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb, color: tokens.brandOrange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
