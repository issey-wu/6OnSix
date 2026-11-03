import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/data/database.dart';
import 'package:six_on_six/core/data/drift_progress_repository.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/user_state.dart';

import '../../support/fake_clock.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock(DateTime.utc(2026, 11, 2, 18));
  });

  tearDown(() => db.close());

  DriftProgressRepository repo() => DriftProgressRepository(db, clock: clock);

  test('first launch creates one anonymous user with defaults', () async {
    final state = await repo().load();
    expect(state.progress.completed, isEmpty);
    expect(state.progress.xp, 0);
    expect(state.settings, const AppSettings());
    expect(state.name, isNull);

    await repo().load();
    expect(await db.select(db.localUsers).get(), hasLength(1));
  });

  test('a completion survives a restart, with its answers logged', () async {
    final first = repo();
    await first.load();
    final updated = const Progress().complete(
      nodeId: 'u1.l1',
      xpEarned: 15,
      localNow: DateTime(2026, 11, 2, 13),
    );
    await first.recordCompletion(
      nodeId: 'u1.l1',
      perfect: true,
      xpEarned: 15,
      updated: updated,
      answers: [
        AnswerAttempt(
          questionId: 'u1.l1.q01',
          correct: true,
          answeredAt: clock.now(),
        ),
        AnswerAttempt(
          questionId: 'u1.l1.q02',
          correct: false,
          answeredAt: clock.now(),
        ),
      ],
    );

    // A new repository on the same database is like reopening the app.
    final reopened = await repo().load();
    expect(reopened.progress.completed, {'u1.l1'});
    expect(reopened.progress.xp, 15);
    expect(reopened.progress.streak, 1);
    expect(reopened.progress.lastActiveDay, updated.lastActiveDay);
    expect(await db.select(db.answerLog).get(), hasLength(2));
    expect(await db.select(db.completions).get(), hasLength(1));
  });

  test(
    'replaying a lesson adds a completion but lists the node once',
    () async {
      final r = repo();
      await r.load();
      var progress = const Progress();
      for (var i = 0; i < 2; i++) {
        progress = progress.complete(
          nodeId: 'u1.l1',
          xpEarned: 10,
          localNow: DateTime(2026, 11, 2, 13),
        );
        await r.recordCompletion(
          nodeId: 'u1.l1',
          perfect: false,
          xpEarned: 10,
          updated: progress,
          answers: const [],
        );
      }
      final state = await repo().load();
      expect(state.progress.completed, {'u1.l1'});
      expect(state.progress.xp, 20);
      expect(await db.select(db.completions).get(), hasLength(2));
    },
  );

  test('settings and name are saved', () async {
    final r = repo();
    await r.load();
    await r.saveSettings(
      const AppSettings(
        theme: ThemePreference.dark,
        soundOn: false,
        welcomeSeen: true,
      ),
    );
    await r.saveName('Issey');
    final state = await repo().load();
    expect(state.settings.theme, ThemePreference.dark);
    expect(state.settings.soundOn, isFalse);
    expect(state.settings.hapticsOn, isTrue);
    expect(state.settings.welcomeSeen, isTrue);
    expect(state.name, 'Issey');
  });

  test('reset clears progress but keeps settings and name', () async {
    final r = repo();
    await r.load();
    await r.saveName('Issey');
    await r.recordCompletion(
      nodeId: 'u1.l1',
      perfect: true,
      xpEarned: 15,
      updated: const Progress().complete(
        nodeId: 'u1.l1',
        xpEarned: 15,
        localNow: DateTime(2026, 11, 2),
      ),
      answers: const [],
    );
    await r.resetProgress();
    final state = await repo().load();
    expect(state.progress.completed, isEmpty);
    expect(state.progress.xp, 0);
    expect(state.progress.streak, 0);
    expect(state.name, 'Issey');
  });
}
