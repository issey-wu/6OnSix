import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/reminders.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/reminders.dart';
import 'package:six_on_six/core/domain/user_state.dart';

/// Books slowly, like the real phone, so two bookings could overlap.
class _SlowScheduler implements ReminderScheduler {
  List<Reminder> booked = const [];

  @override
  Future<bool> askPermission() async => true;

  @override
  Future<void> book(List<Reminder> reminders) async {
    booked = const [];
    for (final r in reminders) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      booked = [...booked, r];
    }
  }

  @override
  Future<void> test(Reminder reminder, Duration delay) async {}
}

void main() {
  test('turning reminders off wins over a booking still in progress', () async {
    const state = StoredState();
    final scheduler = _SlowScheduler();
    final container = ProviderContainer(
      overrides: [
        initialStateProvider.overrideWithValue(state),
        progressRepositoryProvider.overrideWithValue(
          InMemoryProgressRepository(),
        ),
        reminderSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);
    container.read(reminderSyncProvider);
    final settings = container.read(settingsProvider.notifier)
      ..update(const AppSettings(reminderOn: true));
    await Future<void>.delayed(const Duration(milliseconds: 8));
    settings.update(const AppSettings());
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(scheduler.booked, isEmpty);
  });
}
