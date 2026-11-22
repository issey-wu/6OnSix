import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/league.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:six_on_six/core/ui/ace.dart';
import 'package:six_on_six/core/ui/dialogs.dart';
import 'package:six_on_six/features/profile/presentation/jump_sheet.dart';

/// App version shown under About. Keep in step with pubspec.yaml.
const appVersion = '0.2.0';

/// Settings: appearance, sound, haptics, reset progress and about.
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final goal = ref.watch(motivationProvider.select((m) => m.goal));
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: text.labelLarge?.copyWith(color: tokens.textSecondary),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          section('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemePreference>(
              segments: const [
                ButtonSegment(
                  value: ThemePreference.system,
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemePreference.light,
                  label: Text('Light'),
                ),
                ButtonSegment(value: ThemePreference.dark, label: Text('Dark')),
              ],
              selected: {settings.theme},
              onSelectionChanged: (value) =>
                  controller.update(settings.copyWith(theme: value.first)),
            ),
          ),
          section('Feedback'),
          SwitchListTile(
            title: const Text('Sound effects'),
            subtitle: const Text('Follows the silent switch'),
            value: settings.soundOn,
            onChanged: (on) =>
                controller.update(settings.copyWith(soundOn: on)),
          ),
          SwitchListTile(
            title: const Text('Haptics'),
            value: settings.hapticsOn,
            onChanged: (on) =>
                controller.update(settings.copyWith(hapticsOn: on)),
          ),
          section('Progress'),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Daily goal'),
            subtitle: Text('${goal.label}: ${goal.minutes} min a day'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(context.push('/goal')),
          ),
          ListTile(
            key: const ValueKey('replay-tips'),
            leading: const Icon(Icons.tips_and_updates_outlined),
            title: const Text('Replay the tutorial'),
            subtitle: const Text("Ace's tips show again on each screen"),
            onTap: () {
              ref.read(settingsProvider.notifier).replayTips();
              context.go('/learn');
            },
          ),
          ListTile(
            title: Text(
              'Reset progress',
              style: TextStyle(
                color: tokens.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () async {
              final confirmed = await confirmSheet(
                context,
                title: 'Reset progress?',
                message:
                    'This clears your XP, streak, and completed lessons. '
                    "This can't be undone.",
                stay: 'Keep my progress',
                action: 'Reset progress',
                art: const Ace(
                  height: 110,
                  action: AceAction.sad,
                  mood: AceMood.sad,
                  semanticLabel: 'Ace the eagle, looking sad',
                ),
              );
              if (confirmed) {
                ref.read(progressProvider.notifier).reset();
              }
            },
          ),
          section('About'),
          const ListTile(
            title: Text('6 On Six'),
            subtitle: Text(
              'Version $appVersion\n'
              'Yash Dubey and Issey Wu\n'
              'PROCTECH 4TR3 Capstone, McMaster University',
            ),
            isThreeLine: true,
          ),
          // Shown in every build, release included: the app is only used for
          // demos, and the menu is how a demo jumps around.
          section('Developer menu'),
          const _DeveloperMenu(),
        ],
      ),
    );
  }
}

/// Debug builds only: tools for testing streaks and reaching any lesson
/// without playing through the path. From Yash Dubey (yash/screens).
class _DeveloperMenu extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(clockShiftProvider);
    final shiftController = ref.read(clockShiftProvider.notifier);
    final now = ref.watch(clockProvider).now().toLocal();
    final progress = ref.watch(progressProvider);
    final days = shift.inDays;
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${now.year}-${two(now.month)}-${two(now.day)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: const Text('App date'),
          subtitle: Text(
            '$date${days == 0 ? '' : ' (+$days days)'} · '
            'streak ${progress.streakOn(now)}',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.today_outlined),
          title: const Text('Simulate next day'),
          onTap: () {
            shiftController.addDays(1);
            // As if the app had just been opened on the new day.
            ref.read(progressProvider.notifier).checkStreakFreezes();
            ref.read(leagueProvider.notifier).settle();
          },
        ),
        ListTile(
          leading: const Icon(Icons.update),
          title: const Text('Reset clock to today'),
          onTap: shiftController.reset,
        ),
        ListTile(
          leading: const Icon(Icons.skip_next_outlined),
          title: const Text('Jump to any lesson'),
          onTap: () => unawaited(_jump(context, ref)),
        ),
        _FreezeTile(freezes: ref.watch(motivationProvider).freezes),
        ListTile(
          key: const ValueKey('end-league-week'),
          leading: const Icon(Icons.leaderboard_outlined),
          title: const Text('End this league week now'),
          subtitle: Text(_leagueStatus(ref.watch(leagueProvider))),
          onTap: () {
            ref.read(leagueProvider.notifier).endWeekNow();
            context.go('/league');
          },
        ),
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: const Text('Start over as a new learner'),
          subtitle: const Text('Clears everything and shows the welcome'),
          onTap: () => _startOver(context, ref),
        ),
      ],
    );
  }

  void _startOver(BuildContext context, WidgetRef ref) {
    ref.read(progressProvider.notifier).reset();
    ref.read(motivationProvider.notifier).replace(const MotivationState());
    ref.read(nameProvider.notifier).set(null);
    ref.read(avatarProvider.notifier).set(null);
    ref.read(leagueProvider.notifier).reset();
    final settings = ref.read(settingsProvider);
    ref
        .read(settingsProvider.notifier)
        .update(settings.copyWith(welcomeSeen: false, tipsSeen: const {}));
    ref.read(clockShiftProvider.notifier).reset();
    context.go('/welcome');
  }

  Future<void> _jump(BuildContext context, WidgetRef ref) async {
    final course = ref.read(courseProvider).value;
    if (course == null) return;
    final router = GoRouter.of(context);
    final nodeId = await showJumpSheet(
      context,
      course: course,
      progress: ref.read(progressProvider),
    );
    if (nodeId != null) unawaited(router.push('/lesson/$nodeId'));
  }
}

/// Streak freezes held, with buttons to take one back or give one more.
class _FreezeTile extends ConsumerWidget {
  const new({required this.freezes});

  final int freezes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(motivationProvider.notifier);
    return ListTile(
      leading: const Icon(Icons.ac_unit),
      title: const Text('Streak freezes'),
      subtitle: Text('Holding $freezes of $maxStreakFreezes'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            key: const ValueKey('take-freeze'),
            tooltip: 'Take a streak freeze back',
            onPressed: freezes > 0 ? controller.takeFreeze : null,
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 4),
          IconButton.outlined(
            key: const ValueKey('give-freeze'),
            tooltip: 'Give a streak freeze',
            onPressed: freezes < maxStreakFreezes
                ? controller.giveFreeze
                : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

String _leagueStatus(LeagueState league) => league.joined
    ? '${league.division.label}, ${league.xp} XP this week'
    : '${league.division.label}, not joined this week';
