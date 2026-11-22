import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/feedback.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/app/tips.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/lesson_session.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:six_on_six/core/ui/ace.dart';
import 'package:six_on_six/core/ui/ace_lines.dart';
import 'package:six_on_six/core/ui/coach_mark.dart';
import 'package:six_on_six/core/ui/components.dart';
import 'package:six_on_six/core/ui/court_lineup.dart';
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/core/ui/dialogs.dart';
import 'package:six_on_six/core/ui/motion.dart';
import 'package:six_on_six/features/lesson/presentation/card_diagram.dart';
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

  // Cards come in small groups between questions (see Lesson.interleaved):
  // the cards to show before each question, the group on screen now, and
  // the cards already seen.
  Map<String, List<int>> _cardsBefore = const {};
  List<int> _cardGroup = const [];
  int _cardPos = 0;
  final Set<int> _cardsSeen = {};
  int get _cardIndex => _cardGroup[_cardPos];
  int _attempt = 0;
  List<String> _options = const [];
  String? _response;
  bool? _lastCorrect;
  bool _matchingMistake = false;
  String _praiseLine = _praise.first;
  LessonOutcome? _outcome;

  /// Question types by id, for counting court questions right first try.
  Map<String, QuestionType> _types = const {};
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

  // Ace pops up at milestones: a run of right answers, the first mistake,
  // a second miss in a row, and the last question.
  int _combo = 0;
  int _missRun = 0;
  int _mistakes = 0;
  bool _saidLastOne = false;
  String? _aceLine;
  AceAction _aceAction = AceAction.cheer;
  AceMood _aceMood = AceMood.happy;
  int _aceKey = 0;

  /// What Ace says on the lesson complete screen.
  String _doneLine = '';

  // First-run tips point at these. The answer area gets a new key for each
  // question, because the old question is still on screen while it slides
  // out.
  GlobalKey _answerKey = GlobalKey();
  GlobalKey _feedbackKey = GlobalKey();
  GlobalKey _showMeHowKey = GlobalKey();
  final GlobalKey _checkKey = GlobalKey();
  final GlobalKey _hintKey = GlobalKey();
  bool _tipShowing = false;
  bool _tipQueued = false;

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
          : nodeLesson.interleaved().questions;
    }
    if (node == null) return;
    final lesson = node.lesson;
    _node = node;
    _session = LessonSession(questions);
    _types = {for (final q in questions) q.id: q.type};
    _cards = lesson?.cards ?? const [];
    _cardsBefore = lesson?.interleaved().cardsBefore ?? const {};
    _prepareQuestion();
  }

  /// Shows any cards due before the current question, or else the
  /// question itself.
  void _showCardsOrQuestion() {
    final q = _session?.current;
    final due = [
      for (final i in _cardsBefore[q?.id] ?? const <int>[])
        if (!_cardsSeen.contains(i)) i,
    ];
    if (due.isEmpty) {
      _stage = _Stage.question;
      return;
    }
    _cardGroup = due;
    _cardPos = 0;
    _stage = _Stage.teaching;
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
    _aceLine = null;
    _attempt++;
    _answerKey = GlobalKey();
    _feedbackKey = GlobalKey();
    _showMeHowKey = GlobalKey();
    _showCardsOrQuestion();
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
      _react(correct: correct);
    });
  }

  /// Decides whether Ace pops up after this answer, and with what.
  void _react({required bool correct}) {
    String? line;
    var action = AceAction.cheer;
    var mood = AceMood.happy;
    if (correct) {
      _combo++;
      _missRun = 0;
      line = aceCombo(_random, _combo);
      if (line != null) {
        // A cheeky fist pump at 3, a full cheer after that.
        action = _combo == 3 ? AceAction.fistPump : AceAction.cheer;
        mood = _combo == 3 ? AceMood.cheeky : AceMood.joyful;
      }
      // This answer leaves one question to go.
      if (line == null && !_saidLastOne && _session!.remaining == 2) {
        _saidLastOne = true;
        line = aceLastOne(_random);
        action = AceAction.hop;
      }
    } else {
      _combo = 0;
      _missRun++;
      _mistakes++;
      if (_mistakes == 1 &&
          !ref.read(settingsProvider.notifier).showTip(Tips.mistake)) {
        line = aceFirstMistake(_random);
        action = AceAction.shrug;
        mood = AceMood.surprised;
      } else if (_missRun == 2) {
        line = aceToughRally(_random);
        action = AceAction.sad;
        mood = AceMood.sad;
      }
    }
    _aceLine = line;
    if (line != null) {
      _aceAction = action;
      _aceMood = mood;
      _aceKey++;
    }
  }

  void _matchingDone(bool hadMistake) {
    _log(_session!.current!, correct: !hadMistake);
    ref.read(feedbackProvider).play(FeedbackEvent.correct);
    setState(() {
      _matchingMistake = hadMistake;
      _lastCorrect = true;
      _praiseLine = _praise[_random.nextInt(_praise.length)];
      _react(correct: true);
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
          // Name one other zone, two along from the answer, so the learner
          // counts round to it instead of being shown it.
          final target = int.tryParse(q.answer) ?? 1;
          final anchor = (target + 1) % 6 + 1;
          _hintZones = {anchor};
          _hintText =
              'This is zone $anchor. The numbers count up anticlockwise '
              'around the court.';
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
    // First attempts decide what counts as "right first try".
    final firstTry = <String, bool>{};
    for (final a in _answers) {
      firstTry.putIfAbsent(a.questionId, () => a.correct);
    }
    bool isCourt(QuestionType? t) =>
        t == QuestionType.tapZone || t == QuestionType.dragDrop;
    var combo = 0;
    var bestCombo = 0;
    for (final a in _answers) {
      combo = a.correct ? combo + 1 : 0;
      bestCombo = max(bestCombo, combo);
    }
    _outcome = ref
        .read(progressProvider.notifier)
        .complete(
          nodeId: _node.id,
          isReview: _node.isReview,
          perfect: _session!.isPerfect,
          answers: List.of(_answers),
          bestCombo: bestCombo,
          courtCorrect: firstTry.entries
              .where((e) => e.value && isCourt(_types[e.key]))
              .length,
          dragFirstTry: firstTry.entries
              .where((e) => e.value && _types[e.key] == QuestionType.dragDrop)
              .length,
          isWeakSpots: _node.id == Course.weakSpotsId,
        );
    final feedback = ref.read(feedbackProvider)..play(FeedbackEvent.complete);
    final streakNow = ref.read(progressProvider).streakOn(localNow);
    _doneLine = aceLessonDone(
      _random,
      perfect: _session!.isPerfect,
      review: _node.isReview,
      streak: streakNow,
      streakGrew: streakNow > _streakBefore,
      milestone: _outcome?.milestone != null,
    );
    if (streakNow > _streakBefore) {
      // After the lesson complete fanfare, not over it.
      feedback.play(
        FeedbackEvent.streakExtended,
        delay: const Duration(milliseconds: 1300),
      );
    }
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
    final quit = await confirmSheet(
      context,
      title: "Wait, don't go!",
      message: "If you quit now, your progress in this lesson won't be saved.",
      stay: 'Keep going',
      action: 'Quit lesson',
      art: const Ace(
        height: 120,
        action: AceAction.sad,
        mood: AceMood.sad,
        semanticLabel: 'Ace the eagle, looking sad',
      ),
    );
    if (quit && mounted) _leave();
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
    if (_stage == _Stage.question) _queueTip();
    return PopScope(
      canPop: _stage == _Stage.complete,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_confirmQuit());
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: motion(context, const Duration(milliseconds: 300)),
            child: KeyedSubtree(
              key: ValueKey(_stage),
              child: switch (_stage) {
                _Stage.teaching => _teaching(context, session),
                _Stage.question => _question(context, session, course),
                _Stage.complete => _complete(context, session),
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Looks for a first-run tip to show once this frame is drawn.
  void _queueTip() {
    if (_tipShowing || _tipQueued) return;
    _tipQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tipQueued = false;
      unawaited(_showTip());
    });
  }

  /// The guide for a new learner: where to answer, Check, Show me how,
  /// what happens after a mistake, and the hint. Each tip shows once.
  Future<void> _showTip() async {
    if (!mounted || _tipShowing || _stage != _Stage.question || _finishing) {
      return;
    }
    final tips = ref.read(settingsProvider.notifier);
    final q = _shown;
    if (q == null) return;
    final answered = _lastCorrect != null;
    final tip = switch ((answered, _lastCorrect)) {
      (true, false) when tips.showTip(Tips.mistake) => (
        Tips.mistake,
        _feedbackKey,
        'Missed one? No stress. It comes back at the end of the lesson for '
            'another go.',
        AceAction.shrug,
      ),
      (true, _) when tips.showTip(Tips.showMeHow) => (
        Tips.showMeHow,
        _showMeHowKey,
        'Want the why? Show me how walks you through any answer.',
        AceAction.hop,
      ),
      (false, _) when _response == null && tips.showTip(Tips.answer) => (
        Tips.answer,
        _answerKey,
        'Your turn! Tap an answer.',
        AceAction.wave,
      ),
      (false, _)
          when _response != null &&
              q.type != QuestionType.matching &&
              tips.showTip(Tips.check) =>
        (
          Tips.check,
          _checkKey,
          "Now tap Check to see if you're right.",
          AceAction.hop,
        ),
      // From the second question on, once the first ones are done.
      (false, _)
          when _response == null &&
              !tips.showTip(Tips.showMeHow) &&
              !_hintUsed &&
              tips.showTip(Tips.hint) =>
        (
          Tips.hint,
          _hintKey,
          "Stuck? The lightbulb gives you a hint. You just won't get a "
              'perfect lesson.',
          AceAction.fistPump,
        ),
      _ => null,
    };
    if (tip == null) return;
    final (id, target, text, action) = tip;
    if (target.currentContext == null) return;
    _tipShowing = true;
    final keepGoing = await showCoachMark(
      context,
      target: target,
      text: text,
      action: action,
      mood: action == AceAction.fistPump ? AceMood.cheeky : AceMood.joyful,
    );
    if (keepGoing) {
      tips.tipSeen(id);
    } else if (mounted && await confirmSkipTutorial(context)) {
      tips.skipTips();
    }
    // When they decide to keep the tips, the same one shows again.
    _tipShowing = false;
    if (mounted && _stage == _Stage.question) _queueTip();
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
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: session.progress),
            duration: Duration(milliseconds: _finishing ? 900 : 350),
            curve: _finishing
                ? const Interval(0, 0.5, curve: Curves.easeOut)
                : Curves.easeOutCubic,
            onEnd: _barFilled,
            builder: (context, value, _) => ShineBar(
              value: value,
              color: AppTokens.of(context).brandOrange,
              track: AppTokens.of(context).surfaceMuted,
              height: 16,
              semanticsLabel: 'Lesson progress',
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );

  Widget _hintButton(Course course, {required bool available}) => KeyedSubtree(
    key: _hintKey,
    child: IconButton(
      key: const ValueKey('hint'),
      tooltip: _hintUsed ? 'Hint used' : 'Hint',
      icon: Icon(_hintUsed ? Icons.lightbulb : Icons.lightbulb_outline),
      color: AppTokens.of(context).brandOrange,
      onPressed: available ? () => _useHint(course) : null,
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
              if (card.diagram case final diagram?) ...[
                const SizedBox(height: 20),
                PopIn(
                  key: ValueKey('diagram-$_cardIndex'),
                  scale: true,
                  offset: 0,
                  child: CardDiagram(spec: diagram),
                ),
              ],
              const SizedBox(height: 20),
              Text(card.body, style: text.bodyLarge?.copyWith(height: 1.5)),
            ],
          ),
        ),
        if (isReplay)
          TextButton(
            // Skips every card left in the lesson, not just this group.
            onPressed: () => setState(() {
              _cardsSeen.addAll(List.generate(_cards.length, (i) => i));
              _stage = _Stage.question;
            }),
            child: const Text('Skip'),
          ),
        _bottomButton(
          label: 'Continue',
          onPressed: () => setState(() {
            _cardsSeen.add(_cardIndex);
            if (_cardPos < _cardGroup.length - 1) {
              _cardPos++;
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
          child: Stack(
            children: [
              Positioned.fill(child: _questionList(q, instruction, answered)),
              // Ace rises from behind the answer panel at milestones.
              if (answered && _aceLine != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  left: 0,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: AcePeek(
                      key: ValueKey('ace-$_aceKey'),
                      text: _aceLine!,
                      action: _aceAction,
                      mood: _aceMood,
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnimatedSwitcher(
          // The answer panel springs up from the bottom.
          duration: motion(context, const Duration(milliseconds: 380)),
          reverseDuration: motion(context, const Duration(milliseconds: 160)),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
          child: answered
              ? KeyedSubtree(
                  key: const ValueKey('feedback'),
                  child: FeedbackPanel(
                    key: _feedbackKey,
                    showMeHowKey: _showMeHowKey,
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
                  ),
                )
              : q.type == QuestionType.matching
              ? const SizedBox.shrink()
              : KeyedSubtree(
                  key: const ValueKey('check'),
                  child: KeyedSubtree(
                    key: _checkKey,
                    child: _bottomButton(
                      label: 'Check',
                      onPressed: _response == null ? null : _check,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// The prompt, any hint and the answers, sliding in for each question.
  Widget _questionList(Question q, String instruction, bool answered) {
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    final hintText = _hintText;
    return AnimatedSwitcher(
      duration: motion(context, const Duration(milliseconds: 320)),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: _slideQuestion,
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
          KeyedSubtree(
            key: _answerKey,
            child: _answerArea(q, locked: answered),
          ),
        ],
      ),
    );
  }

  /// The next question slides in from the right as the last one leaves to
  /// the left.
  Widget _slideQuestion(Widget child, Animation<double> animation) {
    final key = _shown == null ? null : ValueKey('${_shown!.id}-$_attempt');
    final incoming = child.key == key;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: Offset(incoming ? 0.3 : -0.3, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
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
          numberedZones: _hintZones,
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

  /// After the first lesson ever, the learner sets a daily goal next.
  void _afterComplete() {
    if (!ref.read(motivationProvider).goalChosen) {
      context.go('/goal');
    } else {
      _leave();
    }
  }

  Widget _complete(BuildContext context, LessonSession session) {
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    final progress = ref.watch(progressProvider);
    final streak = progress.streakOn(ref.read(clockProvider).now().toLocal());
    final streakGrew = streak > _streakBefore;
    final outcome = _outcome;
    final milestone = outcome?.milestone;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              const Positioned.fill(child: ConfettiBurst()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopIn(
                        scale: true,
                        duration: const Duration(milliseconds: 600),
                        child: AceSays(
                          text: _doneLine,
                          action: AceAction.cheer,
                          mood: session.isPerfect
                              ? AceMood.joyful
                              : AceMood.happy,
                          aceHeight: 150,
                          bubbleWidth: 200,
                        ),
                      ),
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
                          textAlign: TextAlign.center,
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (milestone != null) ...[
                        const SizedBox(height: 12),
                        _StreakCelebration(streak: streak, milestone: true),
                        const SizedBox(height: 4),
                        Text(
                          '$milestone-day milestone! '
                          'You earned a streak freeze.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium,
                        ),
                      ] else if (streakGrew) ...[
                        const SizedBox(height: 12),
                        _StreakCelebration(streak: streak),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          StatCard(
                            label: (outcome?.boosted ?? false)
                                ? 'XP earned (2x)'
                                : 'XP earned',
                            value: '+${outcome?.xp ?? 0}',
                            countTo: outcome?.xp ?? 0,
                            prefix: '+',
                            icon: Icons.bolt,
                            iconColor: tokens.brandYellow,
                          ),
                          StatCard(
                            label: 'Accuracy',
                            value: '${(session.accuracy * 100).round()}%',
                            icon: Icons.track_changes,
                            iconColor: tokens.choice,
                          ),
                          StatCard(
                            label: 'Streak',
                            value: '$streak',
                            icon: Icons.local_fire_department,
                            iconColor: tokens.brandOrange,
                          ),
                        ],
                      ),
                      if (outcome != null) ...[
                        const SizedBox(height: 20),
                        DailyGoalBar(xp: outcome.todayXp, goal: outcome.goal),
                        for (final quest in outcome.questsJustDone)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _QuestDoneChip(title: quest.title),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _bottomButton(label: 'Continue', onPressed: _afterComplete),
      ],
    );
  }
}

/// A finished quest on the lesson complete screen.
class _QuestDoneChip extends StatelessWidget {
  const new({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Quest complete: $title. Open your chest in Quests.',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.selectedBg,
          border: Border.all(color: tokens.brandOrange),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.redeem, color: tokens.brandOrange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Quest complete: $title\nOpen your chest in Quests.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The flame grows in and shows the new streak when a lesson extends it.
class _StreakCelebration extends StatelessWidget {
  const new({required this.streak, this.milestone = false});

  final int streak;

  /// A bigger celebration for 7, 30, 100 and 365 days.
  final bool milestone;

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
              size: milestone ? 56 : 36,
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
