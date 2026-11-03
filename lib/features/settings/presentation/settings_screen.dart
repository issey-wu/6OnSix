import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/preferences.dart';

/// Keep in step with `version` in pubspec.yaml.
const appVersion = '0.0.1';

/// Settings: theme, sound, haptics, reset progress and About. Debug builds
/// also get the developer menu at the bottom.
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    final tokens = AppTokens.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _SectionTitle('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeChoice>(
              segments: const [
                ButtonSegment(value: ThemeChoice.system, label: Text('System')),
                ButtonSegment(value: ThemeChoice.light, label: Text('Light')),
                ButtonSegment(value: ThemeChoice.dark, label: Text('Dark')),
              ],
              selected: {prefs.theme},
              showSelectedIcon: false,
              onSelectionChanged: (choice) =>
                  notifier.chooseTheme(choice.first),
            ),
          ),
          const _SectionTitle('Feedback'),
          SwitchListTile(
            title: const Text('Sound effects'),
            value: prefs.sound,
            onChanged: (on) => notifier.toggleSound(on: on),
          ),
          SwitchListTile(
            title: const Text('Haptics'),
            value: prefs.haptics,
            onChanged: (on) => notifier.toggleHaptics(on: on),
          ),
          const _SectionTitle('Progress'),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: tokens.error),
                onPressed: () => unawaited(_confirmReset(context, ref)),
                child: const Text('Reset progress'),
              ),
            ),
          ),
          const _SectionTitle('About'),
          const ListTile(title: Text('Version'), trailing: Text(appVersion)),
          const ListTile(
            title: Text('Team'),
            trailing: Text('Issey Wu · Yash Dubey'),
          ),
          const ListTile(
            title: Text('Course'),
            trailing: Text('PROCTECH 4TR3, McMaster'),
          ),
          if (kDebugMode) const _DeveloperMenu(),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final progress = ref.read(progressProvider.notifier);
    final tokens = AppTokens.of(context);
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This clears your XP, streak, and completed lessons. '
          "This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: tokens.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (reset ?? false) progress.reset();
  }
}

class _SectionTitle extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Semantics(
      header: true,
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppTokens.of(context).textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

/// Debug builds only: tools for testing streaks and reaching any lesson
/// without playing through the path.
class _DeveloperMenu extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(clockShiftProvider);
    final shiftNotifier = ref.read(clockShiftProvider.notifier);
    final now = ref.watch(clockProvider).now().toLocal();
    final progress = ref.watch(progressProvider);
    final days = shift.inDays;
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${now.year}-${two(now.month)}-${two(now.day)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Developer menu'),
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
          onTap: () => shiftNotifier.addDays(1),
        ),
        ListTile(
          leading: const Icon(Icons.update),
          title: const Text('Reset clock to today'),
          onTap: shiftNotifier.reset,
        ),
        ListTile(
          leading: const Icon(Icons.skip_next_outlined),
          title: const Text('Jump to any lesson'),
          onTap: () => unawaited(_jump(context, ref)),
        ),
      ],
    );
  }

  Future<void> _jump(BuildContext context, WidgetRef ref) async {
    final course = ref.read(courseProvider).value;
    if (course == null) return;
    final router = GoRouter.of(context);
    final nodeId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Jump to'),
        children: [
          for (final (index, unit) in course.units.indexed)
            for (final node in course.path.where((n) => n.unit == unit))
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, node.id),
                child: Text('Unit ${index + 1} · ${node.title}'),
              ),
        ],
      ),
    );
    if (nodeId != null) unawaited(router.push('/lesson/$nodeId'));
  }
}
