import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// The anonymous learner on this device. One row, created on first launch.
@DataClassName('LocalUserRow')
class LocalUsers extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Append-only log of every answer in a finished lesson or review.
@DataClassName('AnswerRow')
class AnswerLog extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(LocalUsers, #id)();
  TextColumn get nodeId => text()();
  TextColumn get questionId => text()();
  BoolColumn get correct => boolean()();
  DateTimeColumn get answeredAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Append-only log of finished lessons and reviews.
@DataClassName('CompletionRow')
class Completions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(LocalUsers, #id)();
  TextColumn get nodeId => text()();
  BoolColumn get perfect => boolean()();
  IntColumn get xpEarned => integer()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Running totals derived from the completions, updated in the same
/// transaction as each completion.
@DataClassName('ProgressSummaryRow')
class ProgressSummary extends Table {
  TextColumn get userId => text().references(LocalUsers, #id)();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get streak => integer().withDefault(const Constant(0))();

  /// The device-local calendar day of the last completion, stored as
  /// midnight UTC.
  DateTimeColumn get lastActiveDay => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

@DataClassName('UserSettingsRow')
class UserSettings extends Table {
  TextColumn get userId => text().references(LocalUsers, #id)();
  TextColumn get theme => text().withDefault(const Constant('system'))();
  BoolColumn get soundOn => boolean().withDefault(const Constant(true))();
  BoolColumn get hapticsOn => boolean().withDefault(const Constant(true))();
  BoolColumn get welcomeSeen => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

/// Newer per-learner state stored as JSON documents: the daily goal,
/// quests, streak freezes and related stats (schema version 2), and the
/// player avatar (schema version 3), and the league (schema version 4).
@DataClassName('UserExtrasRow')
class UserExtras extends Table {
  TextColumn get userId => text().references(LocalUsers, #id)();
  TextColumn get motivationJson => text().withDefault(const Constant('{}'))();
  TextColumn get avatarJson => text().nullable()();
  TextColumn get leagueJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

/// Opens the database file on the device.
AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'six_on_six'));

@DriftDatabase(
  tables: [
    LocalUsers,
    AnswerLog,
    Completions,
    ProgressSummary,
    UserSettings,
    UserExtras,
  ],
)
class AppDatabase extends _$AppDatabase {
  new(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Version 2 added the motivation layer's table, version 3 the avatar,
      // version 4 the league. A table created fresh has every column.
      if (from < 2) {
        await m.createTable(userExtras);
        return;
      }
      if (from < 3) await m.addColumn(userExtras, userExtras.avatarJson);
      if (from < 4) await m.addColumn(userExtras, userExtras.leagueJson);
    },
  );
}
