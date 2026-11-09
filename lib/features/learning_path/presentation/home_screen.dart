import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/ui/components.dart';

/// The Learn tab: one vertical path of lessons and unit reviews.
class HomeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final progress = ref.watch(progressProvider);
    final streak = progress.streakOn(ref.watch(clockProvider).now().toLocal());

    return Scaffold(
      appBar: AppBar(
        leading: Center(child: StreakBadge(streak: streak)),
        leadingWidth: 72,
        centerTitle: true,
        title: const Text('6 On Six'),
        actions: [
          Semantics(
            label: '${progress.xp} XP',
            excludeSemantics: true,
            child: Text(
              '${progress.xp} XP',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: course.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Lessons could not be loaded. Please reinstall the app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (course) => _Path(course: course, progress: progress),
      ),
    );
  }
}

class _Path extends ConsumerStatefulWidget {
  const new({required this.course, required this.progress});

  final Course course;
  final Progress progress;

  @override
  ConsumerState<_Path> createState() => _PathState();
}

class _PathState extends ConsumerState<_Path> {
  final GlobalKey _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    final target = _currentKey.currentContext;
    if (target == null || !mounted) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.4,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final progress = widget.progress;
    final path = course.path;
    final name = ref.watch(nameProvider);
    final rules = ref.watch(gameRulesProvider);
    final weak = ref
        .watch(answerStatsProvider)
        .weakest(limit: rules.weakSpotQuestionCount)
        .where((id) => course.questionById(id) != null)
        .length;
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          name == null ? 'Hey there' : 'Hey, $name',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: AppTokens.of(context).textSecondary),
        ),
      ),
      if (weak >= rules.weakSpotMinimum)
        _WeakSpotsCard(
          count: weak,
          onStart: () =>
              unawaited(context.push('/lesson/${Course.weakSpotsId}')),
        ),
    ];
    Unit? lastUnit;
    var lessonNumber = 0;
    for (var i = 0; i < path.length; i++) {
      final node = path[i];
      if (node.unit != lastUnit) {
        lastUnit = node.unit;
        lessonNumber = 0;
        children.add(
          UnitHeader(
            number: course.units.indexOf(node.unit) + 1,
            title: node.unit.title,
            description: node.unit.description,
          ),
        );
      }
      if (!node.isReview) lessonNumber++;
      if (node.isFinal) {
        children.add(
          const UnitHeader(
            title: 'Final review',
            description:
                'Questions from every unit. Come back any time to stay '
                'sharp.',
          ),
        );
      }
      final state = progress.stateOf(path, i);
      const offsets = [-0.45, 0.0, 0.45, 0.0];
      children.add(
        Align(
          alignment: Alignment(offsets[i % offsets.length], 0),
          child: _NodeButton(
            key: state == NodeState.current ? _currentKey : null,
            node: node,
            state: state,
            label: node.isFinal
                ? 'Final review'
                : node.isReview
                ? 'Unit review'
                : 'Lesson $lessonNumber',
            onOpen: () => _openNode(node, state),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: children,
    );
  }

  void _openNode(PathNode node, NodeState state) {
    if (state == NodeState.locked) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Finish the lesson before this to unlock it.'),
          ),
        );
      return;
    }
    final rules = ref.read(gameRulesProvider);
    final lesson = node.lesson;
    final poolSize = node.isFinal
        ? widget.course.allQuestions.length
        : node.unit.lessons.fold<int>(0, (sum, l) => sum + l.questions.length);
    final draw = node.isFinal
        ? rules.finalReviewQuestionCount
        : rules.reviewQuestionCount;
    final count = lesson == null
        ? (poolSize < draw ? poolSize : draw)
        : lesson.questions.length;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => _NodeCard(
          title: node.title,
          questionCount: count,
          replay: state == NodeState.completed,
          onStart: () {
            Navigator.pop(sheetContext);
            unawaited(context.push('/lesson/${node.id}'));
          },
        ),
      ),
    );
  }
}

/// Offers a short practice of the questions the learner has missed most.
class _WeakSpotsCard extends StatelessWidget {
  const new({required this.count, required this.onStart});

  final int count;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: tokens.selectedBg,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: tokens.brandOrange, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          key: const ValueKey('weak-spots'),
          borderRadius: BorderRadius.circular(16),
          onTap: onStart,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: tokens.brandOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Practice weak spots',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$count questions you have missed before',
                        style: text.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: tokens.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const new({
    required this.title,
    required this.questionCount,
    required this.replay,
    required this.onStart,
  });

  final String title;
  final int questionCount;
  final bool replay;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '$questionCount questions',
              style: text.bodyMedium?.copyWith(
                color: AppTokens.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onStart,
              child: Text(replay ? 'Practice again' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The final review gets a medal, unit reviews a trophy, and lessons
/// [lessonIcon].
IconData _icon(PathNode node, IconData lessonIcon) => node.isFinal
    ? Icons.workspace_premium
    : node.isReview
    ? Icons.emoji_events
    : lessonIcon;

class _NodeButton extends StatefulWidget {
  const new({
    required this.node,
    required this.state,
    required this.label,
    required this.onOpen,
    super.key,
  });

  final PathNode node;
  final NodeState state;

  /// Such as "Lesson 2" or "Unit review", for the screen reader.
  final String label;
  final VoidCallback onOpen;

  @override
  State<_NodeButton> createState() => _NodeButtonState();
}

class _NodeButtonState extends State<_NodeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 1,
    upperBound: 1.08,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_NodeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final animate =
        widget.state == NodeState.current &&
        !MediaQuery.of(context).disableAnimations &&
        TickerMode.valuesOf(context).enabled;
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final node = widget.node;
    final (fill, iconColor, icon, stateLabel) = switch (widget.state) {
      NodeState.locked => (
        tokens.surfaceMuted,
        tokens.textSecondary,
        _icon(node, Icons.lock),
        'locked',
      ),
      NodeState.current => (
        tokens.brandOrange,
        tokens.onYellowOrange,
        _icon(node, Icons.play_arrow_rounded),
        'current',
      ),
      NodeState.completed => (
        tokens.brandYellow,
        tokens.onYellowOrange,
        _icon(node, Icons.check_rounded),
        'completed',
      ),
    };
    final size = widget.state == NodeState.current ? 80.0 : 72.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Semantics(
        button: true,
        label: '${widget.label}, ${node.title}, $stateLabel',
        excludeSemantics: true,
        child: Column(
          children: [
            ScaleTransition(
              scale: _pulse,
              child: Material(
                color: fill,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onOpen,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Icon(icon, color: iconColor, size: 34),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(node.title, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
