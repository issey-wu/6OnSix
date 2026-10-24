import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/progress.dart';

/// The Learn tab: one vertical path of lessons and unit reviews.
class HomeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final progress = ref.watch(progressProvider);
    final streak = progress.streakOn(ref.watch(clockProvider).now().toLocal());
    final tokens = AppTokens.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('6 On Six'),
        actions: [
          Semantics(
            label: '$streak day streak',
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: streak > 0 ? tokens.brandOrange : tokens.surfaceMuted,
                ),
                Text('$streak'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            label: '${progress.xp} XP',
            child: Text('${progress.xp} XP'),
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

class _Path extends StatelessWidget {
  const new({required this.course, required this.progress});

  final Course course;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final path = course.path;
    final children = <Widget>[];
    Unit? lastUnit;
    for (var i = 0; i < path.length; i++) {
      final node = path[i];
      if (node.unit != lastUnit) {
        lastUnit = node.unit;
        children.add(
          _UnitHeader(
            number: course.units.indexOf(node.unit) + 1,
            unit: node.unit,
          ),
        );
      }
      const offsets = [-0.45, 0.0, 0.45, 0.0];
      children.add(
        Align(
          alignment: Alignment(offsets[i % offsets.length], 0),
          child: _NodeButton(node: node, state: progress.stateOf(path, i)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: children,
    );
  }
}

class _UnitHeader extends StatelessWidget {
  const new({required this.number, required this.unit});

  final int number;
  final Unit unit;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.buttonRed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UNIT $number',
            style: text.labelLarge?.copyWith(color: tokens.onBrandRed),
          ),
          Text(
            unit.title,
            style: text.titleLarge?.copyWith(
              color: tokens.onBrandRed,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            unit.description,
            style: text.bodyMedium?.copyWith(color: tokens.onBrandRed),
          ),
        ],
      ),
    );
  }
}

class _NodeButton extends StatelessWidget {
  const new({required this.node, required this.state});

  final PathNode node;
  final NodeState state;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final (fill, iconColor, icon, label) = switch (state) {
      NodeState.locked => (
        tokens.surfaceMuted,
        tokens.textSecondary,
        Icons.lock,
        'locked',
      ),
      NodeState.current => (
        tokens.brandOrange,
        tokens.onYellowOrange,
        node.isReview ? Icons.emoji_events : Icons.play_arrow_rounded,
        'current',
      ),
      NodeState.completed => (
        tokens.brandYellow,
        tokens.onYellowOrange,
        node.isReview ? Icons.emoji_events : Icons.check_rounded,
        'completed',
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Semantics(
        button: true,
        label: '${node.title}, $label',
        child: Column(
          children: [
            Material(
              color: fill,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _open(context),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Icon(icon, color: iconColor, size: 34),
                ),
              ),
            ),
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                node.title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
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
    unawaited(context.push('/lesson/${node.id}'));
  }
}
