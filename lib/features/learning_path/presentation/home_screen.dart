import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/ui/components.dart';
import 'package:six_on_six/core/ui/motion.dart';

/// The Learn tab: one vertical path of lessons and unit reviews.
class HomeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final progress = ref.watch(progressProvider);
    final local = ref.watch(clockProvider).now().toLocal();
    final streak = progress.streakOn(local);
    final motivation = ref.watch(motivationProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Center(child: StreakBadge(streak: streak)),
        leadingWidth: 72,
        centerTitle: true,
        title: const Text('6 On Six'),
        actions: [
          GoalRing(
            xp: motivation.statsOn(local).xp,
            goal: motivation.goal,
            onTap: () => context.go('/quests'),
          ),
          const SizedBox(width: 10),
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
    // Leave the list at the top when the next lesson is already on screen,
    // so cards above it (such as weak spots) stay in view.
    final node = target.findRenderObject();
    final list = Scrollable.of(target).context.findRenderObject();
    if (node is RenderBox && list is RenderBox) {
      final top = node.localToGlobal(Offset.zero, ancestor: list).dy;
      if (top >= 0 && top + node.size.height <= list.size.height) return;
    }
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
      children: [
        // The first screenful drops in one item after another.
        for (final (i, child) in children.indexed)
          if (i < 14)
            PopIn(
              delay: Duration(milliseconds: 45 * i),
              child: child,
            )
          else
            child,
      ],
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
        shape: LedgeBorder(
          side: BorderSide(color: tokens.brandOrange, width: 2),
        ),
        child: InkWell(
          key: const ValueKey('weak-spots'),
          customBorder: const LedgeBorder(),
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

class _NodeButtonState extends State<_NodeButton> {
  bool _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final node = widget.node;
    final current = widget.state == NodeState.current;
    final (fill, iconColor, icon, stateLabel) = switch (widget.state) {
      NodeState.locked => (
        tokens.surfaceMuted,
        tokens.textSecondary,
        _icon(node, Icons.lock),
        'locked',
      ),
      NodeState.current => (
        tokens.brandOrange,
        Colors.white,
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
    // The circle sits on a darker copy of itself; pressing pushes it down.
    final edge = Color.lerp(fill, Colors.black, 0.22)!;
    const depth = 7.0;
    final size = current ? 78.0 : 70.0;
    final lift = _pressed ? 1.0 : depth;
    Widget circle = GestureDetector(
      onTapDown: (_) => _press(true),
      onTapUp: (_) => _press(false),
      onTapCancel: () => _press(false),
      onTap: widget.onOpen,
      child: SizedBox(
        width: size,
        height: size * 0.92 + depth,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size * 0.92,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: edge,
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(size / 2, size * 0.46),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: motion(context, const Duration(milliseconds: 70)),
              left: 0,
              right: 0,
              top: depth - lift,
              height: size * 0.92,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(size / 2, size * 0.46),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),
            ),
          ],
        ),
      ),
    );
    if (current) {
      // A ring around the next lesson, and a Start tag floating above it.
      circle = Bob(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StartTag(color: tokens.brandOrange),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.brandOrange.withValues(alpha: 0.3),
                  width: 6,
                ),
              ),
              child: Padding(padding: const EdgeInsets.all(6), child: circle),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Semantics(
        button: true,
        label: '${widget.label}, ${node.title}, $stateLabel',
        excludeSemantics: true,
        onTap: widget.onOpen,
        child: Column(
          children: [
            circle,
            const SizedBox(height: 6),
            Text(
              node.title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: widget.state == NodeState.locked
                    ? tokens.textSecondary
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "START" tag above the next lesson.
class _StartTag extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 5, 12, 7),
    decoration: ShapeDecoration(
      color: Theme.of(context).colorScheme.surface,
      shape: LedgeBorder(
        radius: 12,
        ledge: 3,
        side: BorderSide(color: AppTokens.of(context).surfaceMuted, width: 2),
      ),
    ),
    child: Text(
      'START',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    ),
  );
}
