import 'package:drift/drift.dart';
import 'package:six_on_six/core/data/database.dart';
import 'package:six_on_six/core/domain/clock.dart';
import 'package:six_on_six/core/domain/progress.dart';
import 'package:six_on_six/core/domain/progress_repository.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:uuid/uuid.dart';

/// Saves progress in the on-device SQLite database.
///
/// Follows the sync-ready data rules: IDs are created on the device, times
/// are stored in UTC, answers and completions are append-only, and the
/// running totals are written in the same transaction as the event.
class DriftProgressRepository implements ProgressRepository {
  new(this._db, {required this._clock, this._uuid = const Uuid()});

  final AppDatabase _db;
  final Clock _clock;
  final Uuid _uuid;
  String? _userId;

  Future<String> _ensureUser() async {
    final cached = _userId;
    if (cached != null) return cached;
    final existing = await _db.select(_db.localUsers).getSingleOrNull();
    if (existing != null) return _userId = existing.id;
    final now = _clock.now();
    final id = _uuid.v4();
    await _db.transaction(() async {
      await _db
          .into(_db.localUsers)
          .insert(
            LocalUsersCompanion.insert(id: id, createdAt: now, updatedAt: now),
          );
      await _db
          .into(_db.progressSummary)
          .insert(ProgressSummaryCompanion.insert(userId: id, updatedAt: now));
      await _db
          .into(_db.userSettings)
          .insert(UserSettingsCompanion.insert(userId: id, updatedAt: now));
    });
    return _userId = id;
  }

  @override
  Future<StoredState> load() async {
    final userId = await _ensureUser();
    final user = await (_db.select(
      _db.localUsers,
    )..where((t) => t.id.equals(userId))).getSingle();
    final summary = await (_db.select(
      _db.progressSummary,
    )..where((t) => t.userId.equals(userId))).getSingle();
    final settings = await (_db.select(
      _db.userSettings,
    )..where((t) => t.userId.equals(userId))).getSingle();
    final completed =
        await (_db.selectOnly(_db.completions, distinct: true)
              ..addColumns([_db.completions.nodeId])
              ..where(_db.completions.userId.equals(userId)))
            .map((row) => row.read(_db.completions.nodeId)!)
            .get();
    final answers = await (_db.select(
      _db.answerLog,
    )..where((t) => t.userId.equals(userId))).get();

    return StoredState(
      name: user.displayName,
      progress: Progress(
        completed: completed.toSet(),
        xp: summary.xp,
        streak: summary.streak,
        lastActiveDay: summary.lastActiveDay?.toUtc(),
      ),
      settings: AppSettings(
        theme: ThemePreference.values.firstWhere(
          (t) => t.name == settings.theme,
          orElse: () => ThemePreference.system,
        ),
        soundOn: settings.soundOn,
        hapticsOn: settings.hapticsOn,
        welcomeSeen: settings.welcomeSeen,
      ),
      answerStats: const AnswerStats().withResults([
        for (final a in answers) (a.questionId, a.correct),
      ]),
    );
  }

  @override
  Future<void> recordCompletion({
    required String nodeId,
    required bool perfect,
    required int xpEarned,
    required List<AnswerAttempt> answers,
    required Progress updated,
  }) async {
    final userId = await _ensureUser();
    final now = _clock.now();
    await _db.transaction(() async {
      await _db
          .into(_db.completions)
          .insert(
            CompletionsCompanion.insert(
              id: _uuid.v4(),
              userId: userId,
              nodeId: nodeId,
              perfect: perfect,
              xpEarned: xpEarned,
              completedAt: now,
            ),
          );
      await _db.batch((batch) {
        batch.insertAll(_db.answerLog, [
          for (final a in answers)
            AnswerLogCompanion.insert(
              id: _uuid.v4(),
              userId: userId,
              nodeId: nodeId,
              questionId: a.questionId,
              correct: a.correct,
              answeredAt: a.answeredAt,
            ),
        ]);
      });
      await (_db.update(
        _db.progressSummary,
      )..where((t) => t.userId.equals(userId))).write(
        ProgressSummaryCompanion(
          xp: Value(updated.xp),
          streak: Value(updated.streak),
          lastActiveDay: Value(updated.lastActiveDay),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final userId = await _ensureUser();
    await (_db.update(
      _db.userSettings,
    )..where((t) => t.userId.equals(userId))).write(
      UserSettingsCompanion(
        theme: Value(settings.theme.name),
        soundOn: Value(settings.soundOn),
        hapticsOn: Value(settings.hapticsOn),
        welcomeSeen: Value(settings.welcomeSeen),
        updatedAt: Value(_clock.now()),
      ),
    );
  }

  @override
  Future<void> saveName(String? name) async {
    final userId = await _ensureUser();
    await (_db.update(_db.localUsers)..where((t) => t.id.equals(userId))).write(
      LocalUsersCompanion(
        displayName: Value(name),
        updatedAt: Value(_clock.now()),
      ),
    );
  }

  @override
  Future<void> resetProgress() async {
    final userId = await _ensureUser();
    await _db.transaction(() async {
      await (_db.delete(
        _db.completions,
      )..where((t) => t.userId.equals(userId))).go();
      await (_db.delete(
        _db.answerLog,
      )..where((t) => t.userId.equals(userId))).go();
      await (_db.update(
        _db.progressSummary,
      )..where((t) => t.userId.equals(userId))).write(
        ProgressSummaryCompanion(
          xp: const Value(0),
          streak: const Value(0),
          lastActiveDay: const Value(null),
          updatedAt: Value(_clock.now()),
        ),
      );
    });
  }
}
