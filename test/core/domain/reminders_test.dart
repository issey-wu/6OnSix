import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/reminders.dart';

List<Reminder> _plan({
  required DateTime now,
  bool practised = false,
  int streak = 0,
  int minutes = 19 * 60,
}) => planReminders(
  localNow: now,
  minutes: minutes,
  practisedToday: practised,
  streak: streak,
  random: Random(1),
);

void main() {
  test('a week of reminders at the chosen time, today included', () {
    final plan = _plan(now: DateTime(2026, 11, 24, 9));
    expect(plan, hasLength(reminderDaysAhead));
    expect(plan.first.at, DateTime(2026, 11, 24, 19));
    expect(plan.last.at, DateTime(2026, 11, 30, 19));
    expect(plan.map((r) => r.id).toSet(), hasLength(reminderDaysAhead));
  });

  test('no reminder today once practised, or once its time has passed', () {
    final practised = _plan(now: DateTime(2026, 11, 24, 9), practised: true);
    expect(practised.first.at, DateTime(2026, 11, 25, 19));
    expect(practised, hasLength(reminderDaysAhead - 1));

    final late = _plan(now: DateTime(2026, 11, 24, 21));
    expect(late.first.at, DateTime(2026, 11, 25, 19));
  });

  test('with a streak going, the next reminder is about keeping it', () {
    final plan = _plan(now: DateTime(2026, 11, 24, 9), streak: 5);
    expect(plan.first.title, 'Keep your streak alive');
    expect(plan.first.body, contains('5 day streak'));
    expect(plan[1].title, isNot('Keep your streak alive'));
  });

  test('the clock time holds across a month end', () {
    final plan = _plan(now: DateTime(2026, 12, 29, 9), minutes: 8 * 60 + 30);
    expect(plan.last.at, DateTime(2027, 1, 4, 8, 30));
  });

  test('times read like a phone clock', () {
    expect(reminderTimeLabel(19 * 60), '7:00 pm');
    expect(reminderTimeLabel(8 * 60 + 5), '8:05 am');
    expect(reminderTimeLabel(0), '12:00 am');
    expect(reminderTimeLabel(12 * 60 + 30), '12:30 pm');
  });
}
