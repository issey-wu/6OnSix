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

/// Another clock moved forward by [shift]. The developer menu uses this to
/// simulate days when testing streaks.
class ShiftedClock implements Clock {
  const new(this.base, this.shift);

  final Clock base;
  final Duration shift;

  @override
  DateTime now() => base.now().add(shift);
}
