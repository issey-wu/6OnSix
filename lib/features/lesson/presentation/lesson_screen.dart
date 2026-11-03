import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/lesson_session.dart';
import 'package:six_on_six/features/lesson/presentation/court_view.dart';
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
  int _xpEarned = 0;
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

  void _check() {
    final q = _session!.current!;
    final correct = q.isCorrect(_response!);
    if (ref.read(preferencesProvider).haptics) {
      unawaited(
        correct ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact(),
      );
    }
    setState(() => _lastCorrect = correct);
  }

  void _matchingDone(bool hadMistake) {
    setState(() {
      _matchingMistake = hadMistake;
      _lastCorrect = true;
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
    final node = _node;
    _xpEarned = ref
        .read(progressProvider.notifier)
        .complete(
          nodeId: node.id,
          isReview: node.isReview,
          perfect: _session!.isPerfect,
        );
    _stage = _Stage.complete;
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
    if ((quit ?? false) && mounted) context.pop();
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
    return Scaffold(
      body: SafeArea(
        child: switch (_stage) {
          _Stage.teaching => _teaching(context, session),
          _Stage.question => _question(context, session),
          _Stage.complete => _complete(context, session),
        },
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
            child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 14,
              semanticsLabel: 'Lesson progress',
            ),
          ),
        ),
      ],
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
              Text(
                card.title,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(card.body, style: text.bodyLarge?.copyWith(height: 1.5)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (isReplay)
                TextButton(
                  onPressed: () => setState(() => _stage = _Stage.question),
                  child: const Text('Skip'),
                ),
              FilledButton(
                onPressed: () => setState(() {
                  if (_cardIndex < _cards.length - 1) {
                    _cardIndex++;
                  } else {
                    _stage = _Stage.question;
                  }
                }),
                child: const Text('Continue'),
              ),
            ],
          ),
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
        if (answered)
          _FeedbackPanel(
            correct: _lastCorrect!,
            praise: _praise[_random.nextInt(_praise.length)],
            question: q,
            matchingMistake: _matchingMistake,
            onContinue: _continue,
          )
        else if (q.type != QuestionType.matching)
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _response == null ? null : _check,
              child: const Text('Check'),
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
              _OptionTile(
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
                  child: _OptionTile(
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
        return MatchingView(question: q, onDone: _matchingDone);
      case QuestionType.dragDrop:
        return DragDropView(
          question: q,
          locked: locked,
          haptics: ref.watch(preferencesProvider.select((p) => p.haptics)),
          onChanged: (value) => setState(() => _response = value),
        );
    }
  }

  Widget _complete(BuildContext context, LessonSession session) {
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(progressProvider);
    final streak = progress.streakOn(ref.read(clockProvider).now().toLocal());
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Icon(
            Icons.emoji_events,
            size: 72,
            color: AppTokens.of(context).brandOrange,
          ),
          const SizedBox(height: 12),
          Text(
            session.isPerfect ? 'Perfect lesson!' : 'Lesson complete!',
            style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatCard(label: 'XP earned', value: '+$_xpEarned'),
              _StatCard(
                label: 'Accuracy',
                value: '${(session.accuracy * 100).round()}%',
              ),
              _StatCard(label: 'Streak', value: '$streak'),
            ],
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    this.centered = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: selected
            ? tokens.selectedBg
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? tokens.brandOrange : tokens.surfaceMuted,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: centered ? Alignment.center : Alignment.centerLeft,
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const new({
    required this.correct,
    required this.praise,
    required this.question,
    required this.matchingMistake,
    required this.onContinue,
  });

  final bool correct;
  final String praise;
  final Question question;
  final bool matchingMistake;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final fg = correct ? tokens.onSuccess : tokens.onError;
    final showArrangement = !correct && question.type == QuestionType.dragDrop;
    final title = correct
        ? (matchingMistake ? 'All matched' : praise)
        : showArrangement
        ? 'Correct arrangement:'
        : 'Correct answer: ${question.answerLabel}';
    final note = question.leagueNote;
    return Container(
      width: double.infinity,
      color: correct ? tokens.successBg : tokens.errorBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle : Icons.cancel, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (showArrangement) ...[
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 168,
                child: CourtLineup(placements: question.placements),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            question.explanation,
            style: text.bodyMedium?.copyWith(color: fg),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(
              'League note: $note',
              style: text.bodySmall?.copyWith(color: fg),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: correct ? tokens.success : tokens.error,
            ),
            onPressed: onContinue,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: text.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
