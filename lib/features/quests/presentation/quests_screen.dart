import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/feedback.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/app/tips.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/ui/ace.dart';
import 'package:six_on_six/core/ui/components.dart';
import 'package:six_on_six/core/ui/motion.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// What the first-run tip on this screen points at.
final GlobalKey _questsTipKey = GlobalKey(debugLabel: 'daily quests');

/// Today's goal, streak freezes, the XP boost, the three daily quests with
/// their chests, and the monthly challenge.
class QuestsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motivation = ref.watch(motivationProvider);
    final now = ref.watch(clockProvider).now();
    final local = now.toLocal();
    final today = motivation.statsOn(local);
    final quests = dailyQuests(local);
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    final midnight = DateTime(local.year, local.month, local.day + 1);
    final left = midnight.difference(local);
    final monthDone = motivation.questsByMonth[monthKey(local)] ?? 0;
    final boostUntil = motivation.boostUntil;

    Widget section(String title, [String? trailing]) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: text.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
        ],
      ),
    );

    return TipsOnArrival(
      path: '/quests',
      tips: [
        Tip(
          Tips.quests,
          _questsTipKey,
          'Three new quests every day. Finish one to open its chest.',
          action: AceAction.cheer,
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Quests')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DailyGoalBar(xp: today.xp, goal: motivation.goal),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${motivation.goal.label}: '
                          '${motivation.goal.minutes} min a day',
                          style: text.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => unawaited(context.push('/goal')),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (boostUntil != null && motivation.boostActive(now)) ...[
              const SizedBox(height: 12),
              _Banner(
                icon: Icons.flash_on_rounded,
                text: 'Double XP until ${_clockTime(context, boostUntil)}',
              ),
            ],
            const SizedBox(height: 12),
            _FreezeRow(count: motivation.freezes),
            section(
              'Daily quests',
              'New quests in ${left.inHours} h ${left.inMinutes % 60} min',
            ),
            KeyedSubtree(
              key: _questsTipKey,
              child: Column(
                children: [
                  for (final (index, quest) in quests.indexed)
                    _QuestCard(
                      index: index,
                      quest: quest,
                      progress: quest.progressIn(today),
                      done: quest.doneIn(today),
                      opened: motivation.chestOpened(local, index),
                    ),
                ],
              ),
            ),
            section('${_months.elementAt(local.month - 1)} challenge'),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthDone >= monthlyQuestTarget
                        ? 'Badge earned! You finished $monthDone quests.'
                        : 'Finish $monthlyQuestTarget quests this month '
                              'to earn the monthly badge.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  ChunkyBar(
                    value: monthDone / monthlyQuestTarget,
                    color: tokens.brandRed,
                    height: 12,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$monthDone of $monthlyQuestTarget quests',
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
    );
  }
}

/// A time of day such as "10:45 PM", in the device's format.
String _clockTime(BuildContext context, DateTime utc) =>
    TimeOfDay.fromDateTime(utc.toLocal()).format(context);

class _Panel extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 19),
    decoration: ShapeDecoration(
      color: Theme.of(context).colorScheme.surface,
      shape: LedgeBorder(
        side: BorderSide(color: AppTokens.of(context).surfaceMuted, width: 2),
      ),
    ),
    child: child,
  );
}

class _Banner extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.selectedBg,
        border: Border.all(color: tokens.brandOrange),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: tokens.brandOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// The streak freezes held, as snowflakes in two slots.
class _FreezeRow extends StatelessWidget {
  const new({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'Streak freezes: $count of $maxStreakFreezes',
      excludeSemantics: true,
      child: _Panel(
        child: Row(
          children: [
            for (var i = 0; i < maxStreakFreezes; i++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.ac_unit_rounded,
                  size: 28,
                  color: i < count ? Colors.lightBlue : tokens.surfaceMuted,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Streak freezes: $count of $maxStreakFreezes. Each one '
                'covers a missed day automatically.',
                style: text.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  const new({
    required this.index,
    required this.quest,
    required this.progress,
    required this.done,
    required this.opened,
  });

  final int index;
  final Quest quest;
  final int progress;
  final bool done;
  final bool opened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ChunkyBar(
                    value: progress / quest.target,
                    color: done ? tokens.success : tokens.brandOrange,
                    height: 12,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$progress / ${quest.target}',
                    style: text.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ChestButton(
              key: ValueKey('chest-$index'),
              state: opened
                  ? _ChestState.opened
                  : (done ? _ChestState.ready : _ChestState.locked),
              onOpen: () => unawaited(_open(context, ref)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final reward = ref.read(motivationProvider.notifier).openChest(index);
    if (reward == null) return;
    ref.read(feedbackProvider).play(FeedbackEvent.chestOpened);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _RewardSheet(reward: reward),
    );
  }
}

enum _ChestState { locked, ready, opened }

class _ChestButton extends StatelessWidget {
  const new({required this.state, required this.onOpen, super.key});

  final _ChestState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return switch (state) {
      _ChestState.locked => Semantics(
        label: 'Chest, locked until the quest is done',
        excludeSemantics: true,
        child: Icon(Icons.redeem_rounded, size: 36, color: tokens.surfaceMuted),
      ),
      _ChestState.ready => Wiggle(
        child: FilledButton.icon(
          // The app's buttons are full width by default; this one sits in a
          // row, so it needs its own size.
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: onOpen,
          icon: const Icon(Icons.redeem_rounded),
          label: const Text('Open'),
        ),
      ),
      _ChestState.opened => Semantics(
        label: 'Chest opened',
        excludeSemantics: true,
        child: Icon(
          Icons.check_circle_rounded,
          size: 36,
          color: tokens.success,
        ),
      ),
    };
  }
}

/// What came out of a chest, in a sheet that rises from the bottom: Ace
/// cheering, the reward on a chunky badge, and a burst of confetti.
class _RewardSheet extends StatelessWidget {
  const new({required this.reward});

  final ChestReward reward;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final (icon, title, detail) = switch (reward) {
      BonusXpReward(:final xp) => (
        Icons.bolt_rounded,
        '+$xp XP',
        'Bonus XP, added to today and your total.',
      ),
      StreakFreezeReward() => (
        Icons.ac_unit_rounded,
        'Streak freeze',
        'If you miss a day, it keeps your streak alive automatically.',
      ),
      XpBoostReward(:final length) => (
        Icons.flash_on_rounded,
        'Double XP',
        'Every lesson earns double XP for the next ${length.inMinutes} '
            'minutes.',
      ),
    };
    return Stack(
      children: [
        const Positioned.fill(child: IgnorePointer(child: ConfettiBurst())),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chest opened!',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Ace(
                    height: 120,
                    action: AceAction.cheer,
                    mood: AceMood.joyful,
                  ),
                  const SizedBox(width: 12),
                  PopIn(
                    scale: true,
                    offset: 0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: tokens.brandYellow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.lerp(
                              tokens.brandYellow,
                              Colors.black,
                              0.25,
                            )!,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 56, color: tokens.brandRed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: tokens.brandOrange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: tokens.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nice!'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
