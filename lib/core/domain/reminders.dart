import 'dart:math';

import 'package:meta/meta.dart';

// Daily practice reminders, sent as phone notifications without any
// internet: the app books the next week's reminders on the phone itself.
// Like Duolingo's, a day the learner has already practised gets no
// reminder, and Ace writes each one.

/// How many days ahead reminders are booked. Opening the app or finishing
/// a lesson books them again, so they never run out for a regular learner.
const reminderDaysAhead = 7;

/// One reminder: when it goes off (device local time) and what it says.
@immutable
class Reminder {
  const new({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  /// The notification's id, from 1 to [reminderDaysAhead].
  final int id;
  final DateTime at;
  final String title;
  final String body;
}

/// Ace's reminder lines: a title and the text under it.
const _lines = [
  ('Ace here', "Your volleyball lesson won't play itself. Got 5 minutes?"),
  (
    'Time for volleyball',
    'Ace is waiting at the net. Ready for a quick lesson?',
  ),
  ('Quick set?', 'One short lesson keeps your rotations sharp.'),
  ('Your court misses you', 'Hop in for a lesson before the day ends.'),
  ('Ace again', "I'd serve you a reminder, but I can't hold the ball. Lesson?"),
  (
    'Rally time',
    "A few questions now and you'll thank yourself at the next game.",
  ),
];

/// The reminders to book from [localNow]: one a day at [minutes] after
/// midnight, for [reminderDaysAhead] days. Today is left out once
/// [practisedToday], or once its time has passed. With a [streak] going,
/// the next reminder is about keeping it.
List<Reminder> planReminders({
  required DateTime localNow,
  required int minutes,
  required bool practisedToday,
  required int streak,
  required Random random,
}) {
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final order = [..._lines]..shuffle(random);
  final reminders = <Reminder>[];
  for (var day = 0; day < reminderDaysAhead; day++) {
    // Built from the calendar date, so a daylight saving change keeps the
    // reminder at the same clock time.
    final at = DateTime(
      today.year,
      today.month,
      today.day + day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (day == 0 && (practisedToday || !at.isAfter(localNow))) continue;
    final (title, body) = reminders.isEmpty && streak > 0
        ? (
            'Keep your streak alive',
            "You're on a $streak day streak. One lesson keeps it going.",
          )
        : order[day % order.length];
    reminders.add(Reminder(id: day + 1, at: at, title: title, body: body));
  }
  return reminders;
}

/// [minutes] after midnight as a clock time, such as "7:00 pm".
String reminderTimeLabel(int minutes) {
  final hour = minutes ~/ 60;
  final minute = (minutes % 60).toString().padLeft(2, '0');
  final twelve = hour % 12 == 0 ? 12 : hour % 12;
  return '$twelve:$minute ${hour < 12 ? 'am' : 'pm'}';
}
