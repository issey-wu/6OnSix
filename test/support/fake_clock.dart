import 'package:six_on_six/core/domain/clock.dart';

/// A clock whose time is set by the test.
class FakeClock implements Clock {
  new(DateTime initial) : _now = initial.toUtc();

  DateTime _now;

  @override
  DateTime now() => _now;

  void set(DateTime time) => _now = time.toUtc();

  void advance(Duration duration) => _now = _now.add(duration);
}
