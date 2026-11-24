import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/data/database.dart';
import 'package:six_on_six/core/data/drift_progress_repository.dart';
import 'package:six_on_six/core/domain/avatar.dart';
import 'package:six_on_six/core/domain/league.dart';
import 'package:six_on_six/core/domain/motivation.dart';
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

  test('motivation and bonus XP are saved', () async {
    final r = repo();
    await r.load();
    expect((await repo().load()).motivation.goalChosen, isFalse);
    await r.saveMotivation(
      const MotivationState(
        goal: DailyGoal.intense,
        goalChosen: true,
        freezes: 2,
      ),
    );
    await r.saveProgress(const Progress(xp: 40));
    final state = await repo().load();
    expect(state.motivation.goal, DailyGoal.intense);
    expect(state.motivation.goalChosen, isTrue);
    expect(state.motivation.freezes, 2);
    expect(state.progress.xp, 40);
  });

  test('the avatar survives a restart, and can be cleared', () async {
    await repo().saveMotivation(const MotivationState(goalChosen: true));
    const avatar = Avatar(hair: HairStyle.ponytail, jersey: 3, number: 12);
    await repo().saveAvatar(avatar);

    final loaded = await repo().load();
    expect(loaded.avatar, avatar);
    // Saving the avatar keeps the motivation document in the same row.
    expect(loaded.motivation.goalChosen, isTrue);

    await repo().saveAvatar(null);
    expect((await repo().load()).avatar, isNull);
  });

  test('a version 2 database gains the avatar and league columns and keeps its '
      'data', () async {
    final dir = Directory.systemTemp.createTempSync('six_on_six');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    // Make a database as version 2 left it: no avatar or league column.
    final old = AppDatabase(NativeDatabase(file));
    final before = DriftProgressRepository(old, clock: clock);
    await before.load();
    await before.saveMotivation(const MotivationState(goalChosen: true));
    await old.customStatement(
      'ALTER TABLE user_extras DROP COLUMN avatar_json',
    );
    await old.customStatement(
      'ALTER TABLE user_extras DROP COLUMN league_json',
    );
    await old.customStatement(
      'ALTER TABLE user_settings DROP COLUMN tips_seen',
    );
    await old.customStatement(
      'ALTER TABLE user_settings DROP COLUMN reminder_on',
    );
    await old.customStatement(
      'ALTER TABLE user_settings DROP COLUMN reminder_minutes',
    );
    await old.customStatement('PRAGMA user_version = 2');
    await old.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final after = DriftProgressRepository(upgraded, clock: clock);
    final loaded = await after.load();
    expect(loaded.motivation.goalChosen, isTrue);
    expect(loaded.avatar, isNull);

    expect(loaded.league.division, Division.rec);

    await after.saveAvatar(const Avatar(number: 9));
    await after.saveLeague(const LeagueState(division: Division.club));
    final reloaded = await after.load();
    expect(reloaded.avatar?.number, 9);
    expect(reloaded.league.division, Division.club);
    expect(reloaded.settings.tipsSeen, isEmpty);
    expect(reloaded.settings.reminderOn, isFalse);
    expect(reloaded.settings.reminderMinutes, defaultReminderMinutes);
  });

  test('the practice reminder survives a restart', () async {
    await repo().saveSettings(
      const AppSettings(reminderOn: true, reminderMinutes: 8 * 60 + 30),
    );
    final loaded = (await repo().load()).settings;
    expect(loaded.reminderOn, isTrue);
    expect(loaded.reminderMinutes, 8 * 60 + 30);
  });

  test('the tips already seen survive a restart', () async {
    await repo().saveSettings(
      const AppSettings(tipsSeen: {'lesson.answer', 'home.path'}),
    );
    final loaded = (await repo().load()).settings;
    expect(loaded.tipsSeen, {'lesson.answer', 'home.path'});
  });

  test('the league survives a restart', () async {
    final league = const LeagueState(division: Division.house)
        .addXp(35, DateTime.utc(2026, 11, 18, 18));
    await repo().saveLeague(league);
    final loaded = (await repo().load()).league;
    expect(loaded.division, Division.house);
    expect(loaded.xp, 35);
    expect(loaded.start, league.start);
    expect(loaded.end, league.end);
    expect(loaded.seed, league.seed);
  });
}
