import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/ui/ace.dart';
import 'package:six_on_six/core/ui/ace_lines.dart';
import 'package:six_on_six/core/ui/components.dart';
import 'package:six_on_six/features/goal/presentation/reminder_tiles.dart';

/// Picks a daily goal (shown as minutes a day) and a streak to commit to.
/// Shown once after the first lesson, and from Settings or Quests later.
class GoalScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  late DailyGoal _goal;
  int? _streakGoal;

  static const _streakOptions = [7, 14, 30];

  @override
  void initState() {
    super.initState();
    final current = ref.read(motivationProvider);
    _goal = current.goal;
    // First time: suggest a one-week streak, as Duolingo does.
    _streakGoal = current.goalChosen ? current.streakGoal : 7;
  }

  void _save() {
    ref
        .read(motivationProvider.notifier)
        .chooseGoal(_goal, streakGoal: _streakGoal);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/learn');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily goal')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Semantics(
                  header: true,
                  child: const AceSays(
                    text: aceGoalQuestion,
                    aceHeight: 110,
                    bubbleWidth: 210,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A few minutes every day builds the habit. You can change '
                  'this any time in Settings.',
                  style: text.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: 20),
                for (final goal in DailyGoal.values)
                  OptionTile(
                    key: ValueKey('goal-${goal.name}'),
                    label: '${goal.minutes} min a day  ·  ${goal.label}',
                    selected: goal == _goal,
                    onTap: () => setState(() => _goal = goal),
                  ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    'Commit to a streak',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick how many days in a row you want to aim for first.',
                  style: text.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final days in _streakOptions)
                      ChoiceChip(
                        label: Text('$days days'),
                        selected: _streakGoal == days,
                        onSelected: (_) => setState(() => _streakGoal = days),
                      ),
                    ChoiceChip(
                      label: const Text('Not now'),
                      selected: _streakGoal == null,
                      onSelected: (_) => setState(() => _streakGoal = null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const ReminderTiles(padding: EdgeInsets.zero),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                key: const ValueKey('save-goal'),
                onPressed: _save,
                child: const Text('Set my goal'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
