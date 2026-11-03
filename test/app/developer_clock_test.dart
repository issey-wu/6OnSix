// Adapted from Yash Dubey's tests on yash/screens.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/core/domain/clock.dart';

import '../support/fake_clock.dart';

void main() {
  test('a shifted clock runs ahead of its base by the shift', () {
    final base = FakeClock(DateTime.utc(2026, 11, 3, 12));
    final shifted = ShiftedClock(base, const Duration(days: 2));
    expect(shifted.now(), DateTime.utc(2026, 11, 5, 12));
    base.advance(const Duration(hours: 1));
    expect(shifted.now(), DateTime.utc(2026, 11, 5, 13));
  });

  group('developer clock', () {
    test('defaults to the real clock', () {
      final container = ProviderContainer.test();
      expect(container.read(clockProvider), isA<SystemClock>());
    });

    test('simulating the next day grows the streak', () {
      final container = ProviderContainer.test();
      final progress = container.read(progressProvider.notifier)
        ..complete(nodeId: 'a', isReview: false, perfect: true);
      container.read(clockShiftProvider.notifier).addDays(1);
      progress.complete(nodeId: 'b', isReview: false, perfect: true);

      expect(container.read(progressProvider).streak, 2);
      expect(container.read(clockProvider), isA<ShiftedClock>());
    });

    test('skipping a day shows the streak as zero', () {
      final container = ProviderContainer.test();
      container
          .read(progressProvider.notifier)
          .complete(nodeId: 'a', isReview: false, perfect: true);
      container.read(clockShiftProvider.notifier).addDays(2);

      final now = container.read(clockProvider).now().toLocal();
      expect(container.read(progressProvider).streakOn(now), 0);
    });

    test('reset puts the clock back to today', () {
      final container = ProviderContainer.test();
      container.read(clockShiftProvider.notifier)
        ..addDays(3)
        ..reset();
      expect(container.read(clockShiftProvider), Duration.zero);
      expect(container.read(clockProvider), isA<SystemClock>());
    });
  });
}
