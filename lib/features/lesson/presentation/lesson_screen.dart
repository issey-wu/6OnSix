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
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/features/lesson/presentation/drag_drop_view.dart';
import 'package:six_on_six/features/lesson/presentation/matching_view.dart';

enum _Stage { teaching, question, complete }

/// Plays one lesson or unit review: teaching cards, then questions under the
/// complete-until-correct rule, then the lesson complete screen.
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
  final List<AnswerAttempt> _answers = [];
  final _random = Random();

  void _start(Course course) {
    final node = course.nodeById(widget.nodeId);
    if (node == null) return;
    final rules = ref.read(gameRulesProvider);
    final lesson = node.lesson;
    final questions = lesson == null
        ? course.reviewQuestions(node.unit, count: rules.reviewQuestionCount)
        : lesson.questions;
    _node = node;
    _session = LessonSession(questions);
    _cards = lesson?.cards ?? const [];
    _stage = _cards.isEmpty ? _Stage.question : _Stage.teaching;
    _prepareQuestion();
  }

  void _prepareQuestion() {
    final q = _session?.current;
    _response = null;
    _lastCorrect = null;
    _matchingMistake = false;
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
    final session = _session!;
    final q = session.current!;
    if (q.type == QuestionType.matching) {
      session.submitMatching(hadMistake: _matchingMistake);
    } else {
      session.submit(correct: _lastCorrect!);
    }
    setState(() {
      if (session.isComplete) {
        _finish();
      } else {
        _prepareQuestion();
      }
    });
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
            _Stage.question => _question(context, session),
            _Stage.complete => _complete(context, session),
          },
        ),
      ),
    );
  }

  Widget _topBar(LessonSession session) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
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
              duration: const Duration(milliseconds: 250),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 14,
                semanticsLabel: 'Lesson progress',
              ),
            ),
          ),
        ),
      ],
    ),
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

  Widget _question(BuildContext context, LessonSession session) {
    final q = session.current!;
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
    final title = (_lastCorrect ?? false)
        ? (_matchingMistake ? 'All matched' : _praiseLine)
        : 'Correct answer: ${q.answerLabel}';
    return Column(
      children: [
        _topBar(session),
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
        );
      case QuestionType.matching:
        final feedback = ref.read(feedbackProvider);
        return MatchingView(
          question: q,
          onDone: _matchingDone,
          onPairMatched: () => feedback.play(FeedbackEvent.pairMatched),
          onWrongPair: () => feedback.play(FeedbackEvent.incorrect),
        );
      case QuestionType.dragDrop:
        return DragDropView(
          question: q,
          locked: locked,
          showAnswer: _lastCorrect == false,
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
                    session.isPerfect ? 'Perfect lesson!' : 'Lesson complete!',
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
