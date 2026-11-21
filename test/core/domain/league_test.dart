import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/league.dart';

void main() {
  // Wednesday evening, local time.
  final wednesday = DateTime(2026, 11, 18, 20);

  test('a league has 29 other players, the same every time', () {
    final a = leagueRivals(4, Division.club);
    final b = leagueRivals(4, Division.club);
    expect(a, hasLength(leagueSize - 1));
    expect([for (final p in a) p.name], [for (final p in b) p.name]);
    expect([for (final p in a) p.weekXp], [for (final p in b) p.weekXp]);
    expect({for (final p in a) p.name}, hasLength(leagueSize - 1));
  });

  test('higher divisions have stronger players', () {
    int median(Division d) {
      final xp = [
        for (var seed = 1; seed <= 5; seed++)
          for (final p in leagueRivals(seed, d)) p.weekXp,
      ]..sort();
      return xp[xp.length ~/ 2];
    }

    expect(median(Division.olympic), greaterThan(median(Division.rec)));
  });

  test('earning XP joins the Monday to Monday week', () {
    final league = const LeagueState().addXp(20, wednesday);
    expect(league.joined, isTrue);
    expect(league.xp, 20);
    expect(league.seed, 1);
    expect(league.start!.toLocal(), DateTime(2026, 11, 16));
    expect(league.end!.toLocal(), DateTime(2026, 11, 23));
    expect(league.addXp(15, wednesday).xp, 35);
  });

  test("other players' XP only grows as the week goes on", () {
    final league = const LeagueState().addXp(10, wednesday);
    final rival = leagueRivals(league.seed, league.division).first;
    var last = 0;
    for (var p = 0.0; p <= 1; p += 0.05) {
      final xp = rival.xpAt(p);
      expect(xp, greaterThanOrEqualTo(last));
      last = xp;
    }
    expect(rival.xpAt(0), 0);
    expect(rival.xpAt(1), rival.weekXp);
  });

  test('the table has 30 rows, highest XP first', () {
    final rows = const LeagueState()
        .addXp(40, wednesday)
        .standingsAt(wednesday);
    expect(rows, hasLength(leagueSize));
    expect(rows.where((r) => r.isYou), hasLength(1));
    for (var i = 1; i < rows.length; i++) {
      expect(rows[i - 1].xp, greaterThanOrEqualTo(rows[i].xp));
    }
  });

  test('a week only closes once it has ended', () {
    final league = const LeagueState().addXp(10, wednesday);
    expect(identical(league.settle(wednesday), league), isTrue);
    final ended = league.settle(DateTime(2026, 11, 23, 9));
    expect(ended.joined, isFalse);
    expect(ended.xp, 0);
    expect(ended.lastResult, isNotNull);
    expect(ended.lastResult!.seen, isFalse);
  });

  test('a big week promotes, and Rec never demotes', () {
    final monday = DateTime(2026, 11, 16, 9);
    // Ended early on Monday morning, others have barely started.
    final top = const LeagueState()
        .addXp(500, monday)
        .settle(monday, force: true);
    expect(top.lastResult!.rank, 1);
    expect(top.division, Division.house);
    expect(top.lastResult!.promoted, isTrue);

    final last = const LeagueState()
        .addXp(0, monday)
        .settle(DateTime(2026, 11, 23, 9));
    expect(last.division, Division.rec);
  });

  test('finishing at the bottom of a higher division moves down', () {
    final league = const LeagueState(division: Division.club)
        .addXp(5, wednesday)
        .settle(DateTime(2026, 11, 23, 9));
    expect(league.lastResult!.rank, greaterThan(leagueSize - 5));
    expect(league.division, Division.house);
    expect(league.lastResult!.demoted, isTrue);
  });

  test('a saved league reads back, and damaged data starts fresh', () {
    final league = const LeagueState(division: Division.varsity)
        .addXp(25, wednesday)
        .settle(wednesday, force: true);
    final back = leagueFromJson(league.toJson());
    expect(back.division, league.division);
    expect(back.lastResult!.rank, league.lastResult!.rank);
    expect(
      leagueFromJson({'division': 'galactic', 'xp': 'lots'}).division,
      Division.rec,
    );
  });

  test('friends have streaks and weekly XP that move with the calendar', () {
    for (final friend in demoFriends) {
      expect(friend.streakOn(wednesday), greaterThanOrEqualTo(0));
      expect(
        friend.weekXpOn(DateTime(2026, 11, 22, 23)),
        greaterThanOrEqualTo(friend.weekXpOn(DateTime(2026, 11, 16, 1))),
      );
    }
    final steady = demoFriends.first;
    expect(
      steady.streakOn(DateTime(2026, 11, 19)),
      steady.streakOn(DateTime(2026, 11, 18)) + 1,
    );
  });
}
