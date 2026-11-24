import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/reminders.dart';
import 'package:six_on_six/core/domain/reminders.dart';
import 'package:six_on_six/core/ui/ace.dart';
import 'package:six_on_six/core/ui/tap_haptics.dart';

/// The practice reminder switch and, when it's on, the time it goes off.
/// Shown on the Daily goal screen and in Settings.
class ReminderTiles extends ConsumerWidget {
  const new({super.key, this.padding});

  /// Side padding for the rows, to line up with the screen around them.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          key: const ValueKey('reminder-switch'),
          contentPadding: padding,
          secondary: const Icon(Icons.notifications_active_rounded),
          title: const Text('Practice reminder'),
          subtitle: const Text(
            'A daily nudge from Ace, skipped once you practise',
          ),
          value: settings.reminderOn,
          onChanged: (on) {
            TapHaptics.play();
            unawaited(_setReminder(context, ref, on: on));
          },
        ),
        if (settings.reminderOn)
          ListTile(
            key: const ValueKey('reminder-time'),
            contentPadding: padding,
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('Reminder time'),
            subtitle: Text(reminderTimeLabel(settings.reminderMinutes)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => unawaited(_pickTime(context, ref)),
          ),
      ],
    );
  }
}

/// Turns reminders on or off. Turning them on asks for permission first;
/// if the learner says no, reminders stay off and a sheet says where to
/// change it.
Future<void> _setReminder(
  BuildContext context,
  WidgetRef ref, {
  required bool on,
}) async {
  final controller = ref.read(settingsProvider.notifier);
  if (on) {
    final allowed = await ref.read(reminderSchedulerProvider).askPermission();
    if (!context.mounted) return;
    if (!allowed) {
      await _showBlocked(context);
      return;
    }
  }
  controller.update(ref.read(settingsProvider).copyWith(reminderOn: on));
}

Future<void> _showBlocked(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Ace(
          height: 100,
          action: AceAction.sad,
          mood: AceMood.sad,
          semanticLabel: 'Ace the eagle, looking sad',
        ),
        const SizedBox(height: 12),
        Text(
          'Notifications are off',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          "Ace can't remind you yet. To allow it, open the Settings app, "
          'tap 6 On Six, then Notifications.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  ),
);

/// A sheet with the phone's own time wheel, to pick the reminder time.
Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  var minutes = settings.reminderMinutes;
  final picked = await showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'When should Ace remind you?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            SizedBox(
              height: 180,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Theme.of(context).brightness,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontSize: 22,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  minuteInterval: 5,
                  // The wheel moves in 5 minute steps, so start on one.
                  initialDateTime: DateTime(
                    2000,
                    1,
                    1,
                    minutes ~/ 60,
                    (minutes % 60) ~/ 5 * 5,
                  ),
                  onDateTimeChanged: (time) =>
                      minutes = time.hour * 60 + time.minute,
                ),
              ),
            ),
            FilledButton(
              key: const ValueKey('reminder-save'),
              onPressed: () => Navigator.pop(context, minutes),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
  if (picked != null && context.mounted) {
    ref
        .read(settingsProvider.notifier)
        .update(ref.read(settingsProvider).copyWith(reminderMinutes: picked));
  }
}

/// Developer menu: a sample reminder a few seconds from now, to show
/// reminders in a demo without waiting for the evening.
Future<void> sendTestReminder(BuildContext context, WidgetRef ref) async {
  final scheduler = ref.read(reminderSchedulerProvider);
  final allowed = await scheduler.askPermission();
  if (!context.mounted) return;
  if (!allowed) {
    await _showBlocked(context);
    return;
  }
  final now = ref.read(clockProvider).now().toLocal();
  final sample = planReminders(
    localNow: now.subtract(const Duration(days: 1)),
    minutes: 0,
    practisedToday: true,
    streak: ref.read(progressProvider).streakOn(now),
    random: Random(),
  ).first;
  await scheduler.test(sample, const Duration(seconds: 5));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test reminder on its way. Lock your phone to see it.'),
      ),
    );
  }
}
