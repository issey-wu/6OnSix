import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/league.dart';
import 'package:six_on_six/core/ui/avatar_view.dart';
import 'package:six_on_six/core/ui/components.dart';
import 'package:six_on_six/core/ui/motion.dart';

/// Badge colour for each division, lowest first: bronze, silver, gold,
/// sapphire, ruby, emerald, and amethyst for Olympic.
const divisionColors = [
  Color(0xFFC98A4B),
  Color(0xFF9AA5B1),
  Color(0xFFE2B53B),
  Color(0xFF3554B0),
  Color(0xFFD7263D),
  Color(0xFF2FA84F),
  Color(0xFF7A3FB8),
];

/// This week's league table against 29 simulated players, and the
/// learner's simulated friends. Everyone here is labelled as a demo player.
class LeagueScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  final GlobalKey _youKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _arrive());
  }

  /// Closes a finished week, shows its results once, then scrolls the
  /// learner's row into view.
  Future<void> _arrive() async {
    if (!mounted) return;
    ref.read(leagueProvider.notifier).settle();
    final result = ref.read(leagueProvider).lastResult;
    if (result != null && !result.seen) {
      ref.read(leagueProvider.notifier).markResultSeen();
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (context) => _ResultSheet(result: result),
      );
    }
    if (!mounted) return;
    final duration = motion(context, const Duration(milliseconds: 400));
    final you = _youKey.currentContext;
    if (you != null && you.mounted) {
      await Scrollable.ensureVisible(
        you,
        alignment: 0.4,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final league = ref.watch(leagueProvider);
    final now = ref.watch(clockProvider).now();
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(league.division.title),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: _DemoTag()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _DivisionLadder(current: league.division),
          const SizedBox(height: 12),
          if (league.joined) ...[
            Text(
              _endsIn(league, now),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              _zonesNote(league.division),
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: 12),
            ..._table(league, now),
          ] else
            _JoinCard(division: league.division),
          const SizedBox(height: 28),
          Semantics(
            header: true,
            child: Text(
              'Friends',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          for (final friend in demoFriends)
            _FriendRow(friend: friend, now: now),
        ],
      ),
    );
  }

  List<Widget> _table(LeagueState league, DateTime now) {
    final rows = league.standingsAt(now);
    final division = league.division;
    final rowsOut = <Widget>[];
    for (final (index, row) in rows.indexed) {
      final rank = index + 1;
      if (division.demoted > 0 && rank == leagueSize - division.demoted + 1) {
        rowsOut.add(const _ZoneLine(up: false));
      }
      rowsOut.add(
        _StandingRow(
          key: row.isYou ? _youKey : null,
          rank: rank,
          standing: row,
          zone: rank <= division.promoted
              ? _Zone.up
              : rank > leagueSize - division.demoted
              ? _Zone.down
              : _Zone.stay,
        ),
      );
      if (division.promoted > 0 && rank == division.promoted) {
        rowsOut.add(const _ZoneLine(up: true));
      }
    }
    return rowsOut;
  }

  static String _endsIn(LeagueState league, DateTime now) {
    final left = league.end!.difference(now.toUtc());
    if (left.inDays >= 1) {
      return 'Ends in ${left.inDays} ${left.inDays == 1 ? 'day' : 'days'}';
    }
    return 'Ends in ${left.inHours} h ${left.inMinutes % 60} min';
  }

  static String _zonesNote(Division division) => switch (division) {
    Division.rec => 'Top ${division.promoted} move up to ${division.up.label}.',
    Division.olympic =>
      'The top division. Bottom ${division.demoted} move down.',
    _ =>
      'Top ${division.promoted} move up. Bottom ${division.demoted} move '
          'down.',
  };
}

/// A small tag saying the players here are simulated.
class _DemoTag extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Semantics(
      label: 'Demo community: these players are simulated',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tokens.choiceBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 16, color: tokens.choice),
            const SizedBox(width: 4),
            Text(
              'Demo community',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: tokens.choice, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

/// The seven division badges in a row, the current one large.
class _DivisionLadder extends StatelessWidget {
  const new({required this.current});

  final Division current;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Division ${current.index + 1} of 7: ${current.label}',
    excludeSemantics: true,
    child: SizedBox(
      height: 76,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final division in Division.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: DivisionBadge(
                division: division,
                size: division == current ? 64 : 34,
                locked: division.index > current.index,
              ),
            ),
        ],
      ),
    ),
  );
}

/// A division's shield badge in its colour; grey when not yet reached.
class DivisionBadge extends StatelessWidget {
  const new({
    required this.division,
    this.size = 40,
    this.locked = false,
    super.key,
  });

  final Division division;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final color = locked ? tokens.surfaceMuted : divisionColors[division.index];
    return AnimatedContainer(
      duration: motion(context, const Duration(milliseconds: 300)),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.3)!,
            offset: Offset(0, size / 14),
          ),
        ],
      ),
      child: Icon(
        locked ? Icons.lock : Icons.shield_rounded,
        size: size * 0.55,
        color: locked ? tokens.textSecondary : Colors.white,
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const new({required this.division});

  final Division division;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 23),
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: LedgeBorder(
          side: BorderSide(color: AppTokens.of(context).surfaceMuted, width: 2),
        ),
      ),
      child: Column(
        children: [
          Text(
            "Join this week's league",
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Finish a lesson to join a ${division.label} league with 29 '
            'other players. Earn XP all week to move up.',
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('league-start'),
            onPressed: () => context.go('/learn'),
            child: const Text('Start a lesson'),
          ),
        ],
      ),
    );
  }
}

enum _Zone { up, stay, down }

class _ZoneLine extends StatelessWidget {
  const new({required this.up});

  final bool up;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final color = up ? tokens.success : tokens.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: color, thickness: 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(
                  up
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  up ? 'PROMOTION ZONE' : 'DEMOTION ZONE',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Divider(color: color, thickness: 2)),
        ],
      ),
    );
  }
}

class _StandingRow extends ConsumerWidget {
  const new({
    required this.rank,
    required this.standing,
    required this.zone,
    super.key,
  });

  final int rank;
  final Standing standing;
  final _Zone zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final you = standing.isYou;
    final myName = ref.watch(nameProvider);
    final name = you ? (myName ?? 'You') : standing.name;
    final avatar = you ? ref.watch(avatarProvider) : standing.avatar;
    final rankColor = switch (zone) {
      _Zone.up => tokens.success,
      _Zone.down => tokens.error,
      _Zone.stay => tokens.textSecondary,
    };
    return Semantics(
      label:
          '$rank. ${you ? 'You' : name}, ${standing.xp} XP'
          '${zone == _Zone.up ? ', promotion zone' : ''}'
          '${zone == _Zone.down ? ', demotion zone' : ''}',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: you
            ? ShapeDecoration(
                color: tokens.choiceBg,
                shape: LedgeBorder(
                  radius: 14,
                  ledge: 3,
                  side: BorderSide(color: tokens.choice, width: 2),
                ),
              )
            : null,
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (avatar != null)
              AvatarView(avatar: avatar, size: 44)
            else
              CircleAvatar(
                radius: 22,
                backgroundColor: tokens.brandYellow,
                child: Text(
                  name[0].toUpperCase(),
                  style: text.titleMedium?.copyWith(
                    color: tokens.onYellowOrange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                you && myName != null ? '$name (you)' : name,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: you ? tokens.choice : null,
                ),
              ),
            ),
            Text(
              '${standing.xp} XP',
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: you ? tokens.choice : tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const new({required this.friend, required this.now});

  final DemoFriend friend;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    return Semantics(
      button: true,
      label:
          '${friend.name}, ${friend.streakOn(now)} day streak, '
          '${friend.weekXpOn(now)} XP this week',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey(friend.id),
        borderRadius: BorderRadius.circular(14),
        onTap: () => unawaited(context.push('/league/friend/${friend.id}')),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              AvatarView(avatar: friend.avatar, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${friend.division.label} · '
                      '${friend.weekXpOn(now)} XP this week',
                      style: text.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StreakBadge(streak: friend.streakOn(now)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: tokens.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown once after a league week ends.
class _ResultSheet extends StatelessWidget {
  const new({required this.result});

  final LeagueResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    final (title, body) = result.promoted
        ? (
            'Promoted!',
            'You finished ${_ordinal(result.rank)} and moved up to '
                '${result.newDivision.label}.',
          )
        : result.demoted
        ? (
            'Moved down',
            'You finished ${_ordinal(result.rank)}, so you play in '
                '${result.newDivision.label} this week. Earn more XP to '
                'climb back.',
          )
        : (
            'Week complete',
            'You finished ${_ordinal(result.rank)} and stay in '
                '${result.newDivision.label}.',
          );
    return Stack(
      children: [
        if (result.promoted) const Positioned.fill(child: ConfettiBurst()),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: PopIn(
                  scale: true,
                  offset: 0,
                  child: DivisionBadge(division: result.newDivision, size: 88),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: tokens.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('league-result-ok'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _ordinal(int n) {
  final suffix = n % 100 >= 11 && n % 100 <= 13
      ? 'th'
      : switch (n % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
  return '$n$suffix';
}
