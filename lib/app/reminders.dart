import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/core/domain/reminders.dart';
import 'package:timezone/timezone.dart' as tz;

/// Books practice reminders as notifications on the phone. Nothing goes
/// over the internet: the phone itself shows them at the booked times.
abstract interface class ReminderScheduler {
  /// Asks the learner, once, to allow notifications. True if allowed.
  Future<bool> askPermission();

  /// Replaces every booked reminder with [reminders].
  Future<void> book(List<Reminder> reminders);

  /// Shows one reminder after [delay], for trying reminders out in a demo.
  Future<void> test(Reminder reminder, Duration delay);
}

/// UTC under the name iOS knows it by. The timezone package calls it
/// "Etc/UTC", which iOS may not recognise.
final _utc = tz.Location('UTC', [tz.minTime], [0], [tz.TimeZone.UTC]);

/// Real reminders, through the phone's notification system.
class LocalNotificationScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(),
    android: AndroidNotificationDetails(
      'practice',
      'Practice reminders',
      channelDescription: 'A daily reminder to practise',
    ),
  );

  Future<void> _init() => _ready ??= _plugin.initialize(
    settings: const InitializationSettings(
      // Permission is asked for when the learner turns reminders on, not
      // as soon as the app opens.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  @override
  Future<bool> askPermission() async {
    await _init();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> book(List<Reminder> reminders) async {
    await _init();
    await _plugin.cancelAllPendingNotifications();
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        // An exact moment in UTC, so no time zone data is needed. The
        // local clock time was settled when the reminder was planned.
        scheduledDate: tz.TZDateTime.from(r.at.toUtc(), _utc),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> test(Reminder reminder, Duration delay) async {
    await _init();
    await _plugin.zonedSchedule(
      id: 99,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: tz.TZDateTime.from(
        DateTime.now().toUtc().add(delay),
        _utc,
      ),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}

/// Keeps reminders in memory only. Used by the automated tests, where
/// there is no phone to show them.
class MemoryReminderScheduler implements ReminderScheduler {
  List<Reminder> booked = const [];
  bool allow = true;

  @override
  Future<bool> askPermission() async => allow;

  @override
  Future<void> book(List<Reminder> reminders) async => booked = reminders;

  @override
  Future<void> test(Reminder reminder, Duration delay) async {}
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => Platform.environment.containsKey('FLUTTER_TEST')
      ? MemoryReminderScheduler()
      : LocalNotificationScheduler(),
);

/// The booking in progress, if any. Bookings run one at a time, so an
/// older booking can never finish after a newer one (such as turning
/// reminders off) and put back reminders the learner just cleared.
Future<void> _lastSync = Future.value();

/// Books the next week of reminders, or clears them when reminders are off.
/// Called when the app opens, after a lesson and when the setting changes.
Future<void> syncReminders(Ref ref) =>
    _lastSync = _lastSync.then((_) => _syncNow(ref));

Future<void> _syncNow(Ref ref) async {
  final settings = ref.read(settingsProvider);
  final scheduler = ref.read(reminderSchedulerProvider);
  final localNow = ref.read(clockProvider).now().toLocal();
  final progress = ref.read(progressProvider);
  final last = progress.lastActiveDay;
  final practisedToday =
      last != null &&
      last.year == localNow.year &&
      last.month == localNow.month &&
      last.day == localNow.day;
  try {
    await scheduler.book(
      settings.reminderOn
          ? planReminders(
              localNow: localNow,
              minutes: settings.reminderMinutes,
              practisedToday: practisedToday,
              streak: progress.streakOn(localNow),
              random: Random(),
            )
          : const [],
    );
  } on Object catch (error) {
    // Reminders are a nice extra: never let them break the app.
    debugPrint('Could not book reminders: $error');
  }
}

/// Watches what reminders depend on (the setting, its time, and whether
/// today's lesson is done) and books them again when any of it changes.
final reminderSyncProvider = Provider<void>((ref) {
  ref
    ..listen(
      settingsProvider.select((s) => (s.reminderOn, s.reminderMinutes)),
      (_, _) => unawaited(syncReminders(ref)),
    )
    ..listen(
      progressProvider.select((p) => (p.lastActiveDay, p.streak)),
      (_, _) => unawaited(syncReminders(ref)),
    );
  unawaited(syncReminders(ref));
});
