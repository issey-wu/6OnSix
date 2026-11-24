import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/reminders.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/domain/user_state.dart';

import '../../support/pump_app.dart';

const _state = StoredState(
  settings: AppSettings(welcomeSeen: true, tipsSeen: Tips.all),
  motivation: MotivationState(goalChosen: true),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('turning reminders on books them at the chosen time', (
    tester,
  ) async {
    final container = await pumpWholeApp(
      tester,
      state: _state,
      location: '/profile/settings',
      size: const Size(1170, 6000),
    );
    final scheduler =
        container.read(reminderSchedulerProvider) as MemoryReminderScheduler;
    expect(scheduler.booked, isEmpty);
    expect(find.byKey(const ValueKey('reminder-time')), findsNothing);

    await _tap(tester, find.byKey(const ValueKey('reminder-switch')));
    expect(container.read(settingsProvider).reminderOn, isTrue);
    expect(find.text('7:00 pm'), findsOneWidget);
    expect(scheduler.booked, isNotEmpty);
    expect(
      scheduler.booked.every((r) => r.at.hour == 19 && r.at.minute == 0),
      isTrue,
    );

    await _tap(tester, find.byKey(const ValueKey('reminder-switch')));
    expect(container.read(settingsProvider).reminderOn, isFalse);
    expect(scheduler.booked, isEmpty);
  });

  testWidgets('if notifications are not allowed, reminders stay off', (
    tester,
  ) async {
    final container = await pumpWholeApp(
      tester,
      state: _state,
      location: '/profile/settings',
      size: const Size(1170, 6000),
    );
    (container.read(
      reminderSchedulerProvider,
    ) as MemoryReminderScheduler).allow = false;
    await _tap(tester, find.byKey(const ValueKey('reminder-switch')));
    expect(container.read(settingsProvider).reminderOn, isFalse);
    expect(find.text('Notifications are off'), findsOneWidget);
  });
}
