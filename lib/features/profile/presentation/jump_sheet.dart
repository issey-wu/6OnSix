import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/ui/components.dart';

/// Developer menu: a sheet listing every lesson and review on the path,
/// grouped by unit, styled like the path itself. Returns the chosen node's
/// id, or null when the sheet is closed.
Future<String?> showJumpSheet(
  BuildContext context, {
  required Course course,
  required Progress progress,
}) => showModalBottomSheet<String>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.85,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (context, scroll) =>
        _JumpList(course: course, progress: progress, scroll: scroll),
  ),
);

class _JumpList extends StatelessWidget {
  const new({
    required this.course,
    required this.progress,
    required this.scroll,
  });

  final Course course;
  final Progress progress;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    final path = course.path;
    final children = <Widget>[
      Semantics(
        header: true,
        child: Text(
          'Jump to a lesson',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Opens any lesson, even locked ones. Finishing it counts as usual.',
        style: text.bodyMedium?.copyWith(color: tokens.textSecondary),
      ),
    ];
    Unit? unit;
    var lessonNumber = 0;
    for (final (i, node) in path.indexed) {
      if (node.isFinal) {
        children.add(const _UnitLabel(number: null, title: 'Final review'));
      } else if (node.unit != unit) {
        unit = node.unit;
        lessonNumber = 0;
        children.add(
          _UnitLabel(
            number: course.units.indexOf(node.unit) + 1,
            title: node.unit.title,
          ),
        );
      }
      if (!node.isReview) lessonNumber++;
      children.add(
        _JumpTile(
          node: node,
          state: progress.stateOf(path, i),
          label: node.isFinal
              ? 'Final review'
              : node.isReview
              ? 'Unit review'
              : 'Lesson $lessonNumber',
        ),
      );
    }
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: children,
    );
  }
}

/// A unit's symbol and name above its lessons.
class _UnitLabel extends StatelessWidget {
  const new({required this.number, required this.title});

  final int? number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final number = this.number;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.brandRed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                number == null
                    ? Icons.workspace_premium_rounded
                    : unitSymbol(number),
                size: 20,
                color: tokens.brandYellow,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number == null ? 'ALL UNITS' : 'UNIT $number',
                    style: text.labelMedium?.copyWith(
                      color: tokens.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One lesson or review: a chunky card with the path's circle on the left.
class _JumpTile extends StatelessWidget {
  const new({required this.node, required this.state, required this.label});

  final PathNode node;
  final NodeState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final (fill, iconColor, icon, status) = switch (state) {
      NodeState.locked => (
        tokens.surfaceMuted,
        tokens.textSecondary,
        Icons.lock_rounded,
        'Locked',
      ),
      NodeState.current => (
        tokens.brandOrange,
        Colors.white,
        Icons.play_arrow_rounded,
        'Up next',
      ),
      NodeState.completed => (
        tokens.brandYellow,
        tokens.onYellowOrange,
        Icons.check_rounded,
        'Done',
      ),
    };
    final nodeIcon = node.isFinal
        ? Icons.workspace_premium_rounded
        : node.isReview
        ? Icons.emoji_events_rounded
        : icon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: LedgeBorder(
          side: BorderSide(color: tokens.surfaceMuted, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('jump-${node.id}'),
          onTap: () => Navigator.pop(context, node.id),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color.lerp(fill, Colors.black, 0.22)!,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(nodeIcon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.title,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$label · $status',
                        style: text.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
