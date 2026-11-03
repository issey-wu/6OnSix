import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/progress.dart';

/// The Profile tab: the learner's name, their stats and progress per unit.
class ProfileScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => unawaited(context.push('/profile/settings')),
          ),
        ],
      ),
      body: course.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(
          child: Text('Lessons could not be loaded. Please reinstall the app.'),
        ),
        data: (course) => _ProfileBody(course: course),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const new({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final progress = ref.watch(progressProvider);
    final streak = progress.streakOn(ref.watch(clockProvider).now().toLocal());
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final path = course.path;
    final lessons = path.where((n) => !n.isReview).toList();
    final lessonsDone = lessons
        .where((n) => progress.completed.contains(n.id))
        .length;
    final unitsDone = course.units
        .where((u) => _unitDone(u, path, progress))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: tokens.brandRed,
              foregroundColor: tokens.onBrandRed,
              child: Text(
                prefs.displayName.substring(0, 1).toUpperCase(),
                style: text.headlineSmall?.copyWith(
                  color: tokens.onBrandRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Name, ${prefs.displayName}. Tap to edit.',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => unawaited(_editName(context, ref)),
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              prefs.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: text.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: tokens.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatCard(
              icon: Icons.local_fire_department,
              iconColor: streak > 0 ? tokens.brandOrange : tokens.surfaceMuted,
              value: '$streak',
              label: 'Day streak',
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.bolt,
              iconColor: tokens.brandOrange,
              value: '${progress.xp}',
              label: 'Total XP',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              icon: Icons.check_circle_outline,
              iconColor: tokens.brandOrange,
              value: '$lessonsDone / ${lessons.length}',
              label: 'Lessons',
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.emoji_events_outlined,
              iconColor: tokens.brandOrange,
              value: '$unitsDone / ${course.units.length}',
              label: 'Units',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Units',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        for (final (index, unit) in course.units.indexed)
          _UnitRow(
            number: index + 1,
            unit: unit,
            done: _nodesOf(
              unit,
              path,
            ).where((n) => progress.completed.contains(n.id)).length,
            total: _nodesOf(unit, path).length,
          ),
      ],
    );
  }

  static List<PathNode> _nodesOf(Unit unit, List<PathNode> path) =>
      path.where((n) => n.unit == unit).toList();

  static bool _unitDone(Unit unit, List<PathNode> path, Progress progress) =>
      _nodesOf(unit, path).every((n) => progress.completed.contains(n.id));

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(preferencesProvider.notifier);
    final current = ref.read(preferencesProvider).name;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: current),
    );
    if (name != null) notifier.rename(name);
  }
}

class _NameDialog extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Your name'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 24,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(hintText: 'Player'),
      onSubmitted: (value) => Navigator.pop(context, value),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Save'),
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Semantics(
        label: '$label: $value',
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.surfaceMuted, width: 2),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        label,
                        style: text.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const new({
    required this.number,
    required this.unit,
    required this.done,
    required this.total,
  });

  final int number;
  final Unit unit;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Unit $number · ${unit.title}',
                  style: text.titleSmall,
                ),
              ),
              Text(
                '$done / $total',
                style: text.bodySmall?.copyWith(color: tokens.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 10,
              color: tokens.brandYellow,
              backgroundColor: tokens.surfaceMuted,
              semanticsLabel: 'Unit $number progress, $done of $total done',
            ),
          ),
        ],
      ),
    );
  }
}
