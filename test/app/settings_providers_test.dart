import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/core/domain/clock.dart';
import 'package:six_on_six/core/domain/preferences.dart';

void main() {
  group('preferences', () {
    test('the name shows as Player until one is set', () {
      final container = ProviderContainer.test();
      expect(container.read(preferencesProvider).displayName, 'Player');

      container.read(preferencesProvider.notifier).rename('  Yash ');
      expect(container.read(preferencesProvider).displayName, 'Yash');
      expect(container.read(preferencesProvider).hasName, isTrue);
    });

    test('defaults follow the design: system theme, sound and haptics on', () {
      const prefs = Preferences();
      expect(prefs.theme, ThemeChoice.system);
      expect(prefs.sound, isTrue);
      expect(prefs.haptics, isTrue);
      expect(prefs.welcomeSeen, isFalse);
    });
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

    test('skipping a day resets the streak shown to zero', () {
      final container = ProviderContainer.test();
      container
          .read(progressProvider.notifier)
          .complete(nodeId: 'a', isReview: false, perfect: true);
      container.read(clockShiftProvider.notifier).addDays(2);

      final now = container.read(clockProvider).now().toLocal();
      expect(container.read(progressProvider).streakOn(now), 0);
    });
  });

  test('reset progress clears XP, the streak and completed lessons', () {
    final container = ProviderContainer.test();
    container.read(progressProvider.notifier)
      ..complete(nodeId: 'a', isReview: false, perfect: true)
      ..reset();

    final progress = container.read(progressProvider);
    expect(progress.xp, 0);
    expect(progress.streak, 0);
    expect(progress.completed, isEmpty);
  });
}
