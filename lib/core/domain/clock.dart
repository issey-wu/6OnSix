/// A source of the current time. Inject this instead of calling
/// `DateTime.now()` so tests can control time.
abstract interface class Clock {
  /// The current time, in UTC.
  DateTime now();
}

class SystemClock implements Clock {
  const new();

  @override
  DateTime now() => DateTime.now().toUtc();
}
