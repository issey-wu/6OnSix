import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/user_state.dart';

/// App version shown under About. Keep in step with pubspec.yaml.
const appVersion = '0.2.0';

/// Settings: appearance, sound, haptics, reset progress and about.
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
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
            title: Text(
              'Reset progress',
              style: TextStyle(
                color: tokens.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
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
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Reset',
                        style: TextStyle(color: tokens.error),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed ?? false) {
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
        ],
      ),
    );
  }
}
