import 'dart:math';

import 'package:meta/meta.dart';
import 'package:six_on_six/core/domain/avatar.dart';

// The league and friends are a simulated "demo community": every other
// player is made up on the device from a seed, so the same league looks the
// same every time it is opened, and nothing needs the internet.

/// The seven divisions, lowest first.
enum Division {
  rec('Rec'),
  house('House League'),
  club('Club'),
  varsity('Varsity'),
  provincial('Provincial'),
  national('National'),
  olympic('Olympic');

  new(this.label);

  final String label;

  /// The league's name, such as "Club League".
  String get title => this == Division.house ? label : '$label League';

  /// How many players move up at the end of the week.
  int get promoted => switch (this) {
    Division.rec => 10,
    Division.olympic => 0,
    _ => 7,
  };

  /// How many players move down at the end of the week.
  int get demoted => this == Division.rec ? 0 : 5;

  Division get up => this == Division.olympic ? this : values[index + 1];

  Division get down => this == Division.rec ? this : values[index - 1];

  /// A typical player's XP over a whole week in this division.
  int get typicalWeekXp => const [120, 200, 300, 420, 560, 720, 900][index];
}

/// Players in one league, the learner included.
const leagueSize = 30;

/// Made-up first names for simulated players, with a last initial added.
const _firstNames = [
  'Aiko',
  'Amara',
  'Andre',
  'Aria',
  'Ben',
  'Camila',
  'Chen',
  'Daniel',
  'Dev',
  'Elena',
  'Emeka',
  'Farah',
  'Felix',
  'Gabriel',
  'Hana',
  'Hugo',
  'Imani',
  'Isla',
  'Jae',
  'Jonah',
  'Kai',
  'Kofi',
  'Lara',
  'Leo',
  'Lina',
  'Luca',
  'Maya',
  'Mateo',
  'Mina',
  'Nadia',
  'Nico',
  'Noah',
  'Omar',
  'Priya',
  'Quinn',
  'Rafael',
  'Rania',
  'Ravi',
  'Rosa',
  'Sam',
  'Sana',
  'Sofia',
  'Taro',
  'Tessa',
  'Theo',
  'Uma',
  'Victor',
  'Wren',
  'Yara',
  'Yusuf',
  'Zara',
  'Zoe',
  'Ines',
  'Malik',
  'Elif',
  'Arjun',
  'Chloe',
  'Diego',
  'Freya',
  'Kenji',
];

const _initials = 'ABCDEFGHJKLMNOPRSTVWY';

/// One simulated player in a league: their XP for each day of the week and
/// the time of day they usually practise.
@immutable
class LeaguePlayer {
  const new({
    required this.id,
    required this.name,
    required this.avatar,
    required this.dayXp,
    required this.practiceAt,
  });

  final String id;
  final String name;
  final Avatar avatar;

  /// XP earned on each of the seven days.
  final List<int> dayXp;

  /// When in each day they practise, from 0 (midnight) to 1.
  final List<double> practiceAt;

  /// Their XP once [progress] of the week has passed (0 to 1). Each day's
  /// XP arrives at once, at their practice time.
  int xpAt(double progress) {
    final p = progress.clamp(0.0, 1.0);
    var total = 0;
    for (var day = 0; day < 7; day++) {
      if (p * 7 >= day + practiceAt[day]) total += dayXp[day];
    }
    return total;
  }

  int get weekXp => dayXp.fold(0, (a, b) => a + b);
}

/// Makes a simulated player whose week averages about [typical] XP.
LeaguePlayer _player(Random random, String id, String name, int typical) {
  // Most players land near the typical week; a few are far ahead or behind.
  final spread = 0.2 + random.nextDouble() * random.nextDouble() * 2.2;
  final target = max(10, (typical * spread).round());
  final activeDays = 2 + random.nextInt(6);
  final days = List<int>.filled(7, 0);
  final active = (List<int>.generate(
    7,
    (i) => i,
  )..shuffle(random)).take(activeDays);
  final weights = {for (final d in active) d: 0.5 + random.nextDouble()};
  final sum = weights.values.fold<double>(0, (a, b) => a + b);
  for (final MapEntry(key: day, value: weight) in weights.entries) {
    // Lessons give XP in steps of five.
    days[day] = max(5, (target * weight / sum / 5).round() * 5);
  }
  return LeaguePlayer(
    id: id,
    name: name,
    avatar: avatarPresets[random.nextInt(avatarPresets.length)],
    dayXp: days,
    practiceAt: [for (var i = 0; i < 7; i++) 0.3 + random.nextDouble() * 0.65],
  );
}

/// The other 29 players in league number [seed] of [division]. The same seed
/// and division always give the same players.
List<LeaguePlayer> leagueRivals(int seed, Division division) {
  final random = Random(seed * 7919 + division.index * 104729);
  final names = [..._firstNames]..shuffle(random);
  return [
    for (var i = 0; i < leagueSize - 1; i++)
      _player(
        random,
        'rival-$seed-$i',
        '${names[i]} ${_initials[random.nextInt(_initials.length)]}.',
        division.typicalWeekXp,
      ),
  ];
}

/// How a league week ended for the learner.
@immutable
class LeagueResult {
  const new({
    required this.division,
    required this.rank,
    required this.newDivision,
    this.seen = false,
  });

  /// The division the week was played in.
  final Division division;
  final int rank;
  final Division newDivision;

  /// True once the learner has seen the results sheet.
  final bool seen;

  bool get promoted => newDivision.index > division.index;
  bool get demoted => newDivision.index < division.index;

  Map<String, Object?> toJson() => {
    'division': division.name,
    'rank': rank,
    'newDivision': newDivision.name,
    'seen': seen,
  };
}

/// The learner's place in the league: their division, and the current week
/// if they have joined one.
@immutable
class LeagueState {
  const new({
    this.division = Division.rec,
    this.seed = 0,
    this.start,
    this.end,
    this.xp = 0,
    this.lastResult,
  });

  final Division division;

  /// Counts up with each league joined; picks the simulated players.
  final int seed;

  /// When the current league week began and ends (UTC). Null until the
  /// learner joins by earning XP.
  final DateTime? start;
  final DateTime? end;

  /// XP the learner has earned in the current league week.
  final int xp;

  /// The last week's outcome, for the results sheet.
  final LeagueResult? lastResult;

  bool get joined => start != null && end != null;

  /// How much of the current league week has passed, from 0 to 1.
  double progressAt(DateTime now) {
    final start = this.start;
    final end = this.end;
    if (start == null || end == null) return 0;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 1;
    return (now.toUtc().difference(start).inSeconds / total).clamp(0.0, 1.0);
  }

  bool endedAt(DateTime now) {
    final end = this.end;
    return end != null && !now.toUtc().isBefore(end);
  }

  /// Joins this calendar week's league, Monday to Monday in local time.
  LeagueState join(DateTime now) {
    final local = now.toLocal();
    final monday = DateTime(
      local.year,
      local.month,
      local.day - (local.weekday - DateTime.monday),
    );
    final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
    return LeagueState(
      division: division,
      seed: seed + 1,
      start: monday.toUtc(),
      end: nextMonday.toUtc(),
      lastResult: lastResult,
    );
  }

  /// Adds XP from a lesson or a chest, joining this week's league first if
  /// needed. Call [settle] before, so a finished week is closed first.
  LeagueState addXp(int earned, DateTime now) {
    final current = joined ? this : join(now);
    return current.copyWith(xp: current.xp + earned);
  }

  /// Closes the current week if it has ended, or right now when [force] is
  /// true (the developer menu). The other players' XP stops where it is.
  LeagueState settle(DateTime now, {bool force = false}) {
    if (!joined || !(force || endedAt(now))) return this;
    final rank = standingsAt(now).indexWhere((s) => s.isYou) + 1;
    final next = rank <= division.promoted
        ? division.up
        : rank > leagueSize - division.demoted
        ? division.down
        : division;
    return LeagueState(
      division: next,
      seed: seed,
      lastResult: LeagueResult(
        division: division,
        rank: rank,
        newDivision: next,
      ),
    );
  }

  /// The table at [now], highest XP first. The learner wins ties.
  List<Standing> standingsAt(DateTime now) {
    final progress = progressAt(now);
    final rows =
        [
          Standing(name: 'You', xp: xp, isYou: true),
          for (final rival in leagueRivals(seed, division))
            Standing(
              name: rival.name,
              xp: rival.xpAt(progress),
              avatar: rival.avatar,
            ),
        ]..sort((a, b) {
          final byXp = b.xp.compareTo(a.xp);
          if (byXp != 0) return byXp;
          return (b.isYou ? 1 : 0) - (a.isYou ? 1 : 0);
        });
    return rows;
  }

  LeagueState copyWith({
    Division? division,
    int? xp,
    LeagueResult? lastResult,
  }) => LeagueState(
    division: division ?? this.division,
    seed: seed,
    start: start,
    end: end,
    xp: xp ?? this.xp,
    lastResult: lastResult ?? this.lastResult,
  );

  Map<String, Object?> toJson() => {
    'division': division.name,
    'seed': seed,
    'start': start?.toIso8601String(),
    'end': end?.toIso8601String(),
    'xp': xp,
    'lastResult': lastResult?.toJson(),
  };
}

/// One row of the league table.
@immutable
class Standing {
  const new({
    required this.name,
    required this.xp,
    this.avatar,
    this.isYou = false,
  });

  final String name;
  final int xp;

  /// Null for the learner, whose own avatar is drawn instead.
  final Avatar? avatar;
  final bool isYou;
}

Division _division(Object? name) => Division.values.firstWhere(
  (d) => d.name == name,
  orElse: () => Division.rec,
);

/// Reads a league saved with [LeagueState.toJson]. Anything damaged falls
/// back to a fresh start in Rec.
LeagueState leagueFromJson(Map<String, Object?> json) {
  DateTime? time(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
  final result = json['lastResult'];
  return LeagueState(
    division: _division(json['division']),
    seed: json['seed'] is int ? json['seed']! as int : 0,
    start: time(json['start']),
    end: time(json['end']),
    xp: json['xp'] is int ? json['xp']! as int : 0,
    lastResult: result is Map<String, Object?>
        ? LeagueResult(
            division: _division(result['division']),
            rank: result['rank'] is int ? result['rank']! as int : leagueSize,
            newDivision: _division(result['newDivision']),
            seen: result['seen'] == true,
          )
        : null,
  );
}

/// A simulated friend. Their numbers move with the calendar, so they look
/// active whenever the app is opened.
@immutable
class DemoFriend {
  const new({
    required this.id,
    required this.name,
    required this.preset,
    required this.division,
    required this.streakBase,
    required this.typicalWeekXp,
    this.streakCycle,
  });

  final String id;
  final String name;

  /// Which ready-made avatar they use.
  final int preset;
  final Division division;

  /// Their streak on [_friendsEpoch]; it grows by one each day after.
  final int streakBase;

  /// When set, their streak breaks and restarts every this many days.
  final int? streakCycle;
  final int typicalWeekXp;

  Avatar get avatar => avatarPresets[preset % avatarPresets.length];

  int _daysSinceEpoch(DateTime now) {
    final local = now.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day,
    ).difference(_friendsEpoch).inDays.clamp(0, 100000);
  }

  int streakOn(DateTime now) {
    final days = streakBase + _daysSinceEpoch(now);
    final cycle = streakCycle;
    return cycle == null ? days : days % cycle;
  }

  /// This calendar week's XP so far, from the same model as league players.
  int weekXpOn(DateTime now) {
    final local = now.toLocal();
    final monday = DateTime(
      local.year,
      local.month,
      local.day - (local.weekday - DateTime.monday),
    );
    final weekNumber = monday.difference(_friendsEpoch).inDays ~/ 7;
    final player = _player(
      Random(_stableHash(id) * 31 + weekNumber),
      id,
      name,
      typicalWeekXp,
    );
    final progress = local.difference(monday).inMinutes / (7 * 24 * 60);
    return player.xpAt(progress);
  }

  /// All-time XP: a steady history plus this week.
  int totalXpOn(DateTime now) =>
      typicalWeekXp * (8 + _daysSinceEpoch(now) ~/ 7) + weekXpOn(now);
}

final _friendsEpoch = DateTime(2026, 9, 7);

/// A hash of [text] that is the same on every device and every run, unlike
/// [String.hashCode].
int _stableHash(String text) =>
    text.codeUnits.fold(17, (hash, unit) => (hash * 31 + unit) & 0x3fffffff);

/// The learner's six simulated friends.
const demoFriends = [
  DemoFriend(
    id: 'friend-leah',
    name: 'Leah R.',
    preset: 4,
    division: Division.club,
    streakBase: 21,
    typicalWeekXp: 320,
  ),
  DemoFriend(
    id: 'friend-marcus',
    name: 'Marcus K.',
    preset: 11,
    division: Division.house,
    streakBase: 3,
    streakCycle: 17,
    typicalWeekXp: 180,
  ),
  DemoFriend(
    id: 'friend-anika',
    name: 'Anika S.',
    preset: 23,
    division: Division.varsity,
    streakBase: 40,
    typicalWeekXp: 450,
  ),
  DemoFriend(
    id: 'friend-owen',
    name: 'Owen M.',
    preset: 30,
    division: Division.rec,
    streakBase: 1,
    streakCycle: 9,
    typicalWeekXp: 90,
  ),
  DemoFriend(
    id: 'friend-simone',
    name: 'Simone O.',
    preset: 37,
    division: Division.provincial,
    streakBase: 63,
    typicalWeekXp: 600,
  ),
  DemoFriend(
    id: 'friend-tomas',
    name: 'Tomas L.',
    preset: 45,
    division: Division.club,
    streakBase: 8,
    streakCycle: 30,
    typicalWeekXp: 260,
  ),
];
