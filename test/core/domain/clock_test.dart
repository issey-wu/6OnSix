import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/core/domain/clock.dart';

import '../../support/fake_clock.dart';

void main() {
  group('SystemClock', () {
    test('returns the current time in UTC', () {
      final before = DateTime.now().toUtc();
      final now = const SystemClock().now();
      final after = DateTime.now().toUtc();

      expect(now.isUtc, isTrue);
      expect(now.isBefore(before), isFalse);
      expect(now.isAfter(after), isFalse);
    });
  });

  group('clockProvider', () {
    test('defaults to SystemClock', () {
      final container = ProviderContainer.test();

      expect(container.read(clockProvider), isA<SystemClock>());
    });

    test('can be overridden with a fake clock', () {
      final fake = FakeClock(DateTime.utc(2026, 10, 23, 9));
      final container = ProviderContainer.test(
        overrides: [clockProvider.overrideWithValue(fake)],
      );

      expect(
        container.read(clockProvider).now(),
        DateTime.utc(2026, 10, 23, 9),
      );

      fake.advance(const Duration(days: 1));
      expect(
        container.read(clockProvider).now(),
        DateTime.utc(2026, 10, 24, 9),
      );
    });
  });
}
