import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/league.dart';
import 'package:six_on_six/core/ui/avatar_view.dart';
import 'package:six_on_six/core/ui/components.dart';
import 'package:six_on_six/features/league/presentation/league_screen.dart';

/// A simulated friend's profile: avatar, streak, XP, division, and the
/// lessons they did most recently.
class FriendScreen extends ConsumerWidget {
  const new({required this.friendId, super.key});

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friend = demoFriends.where((f) => f.id == friendId).firstOrNull;
    if (friend == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Friend not found')),
      );
    }
    final now = ref.watch(clockProvider).now();
    final course = ref.watch(courseProvider).value;
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);
    final streak = friend.streakOn(now);

    // Three recent lessons, picked from the course by the friend and day,
    // so they change from day to day but stay put within a day.
    final lessons = course?.path.where((n) => n.lesson != null).toList();
    final local = now.toLocal();
    final dayNumber = DateTime(
      local.year,
      local.month,
      local.day,
    ).difference(DateTime(2026)).inDays;
    final recent = [
      if (lessons != null && lessons.isNotEmpty)
        for (final (ago, label) in [
          // No lesson today means no streak today.
          if (streak > 0) (0, 'Today'),
          (1, 'Yesterday'),
          (2, '2 days ago'),
        ])
          (
            label,
            lessons[(friend.preset * 7 + (dayNumber - ago) * 3) %
                    lessons.length]
                .title,
          ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(friend.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(child: AvatarView(avatar: friend.avatar, size: 132)),
          const SizedBox(height: 12),
          Text(
            friend.name,
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Demo community player',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              StatCard(
                label: 'Day streak',
                value: '$streak',
                icon: Icons.local_fire_department,
                iconColor: streak > 0
                    ? tokens.brandOrange
                    : tokens.textSecondary,
              ),
              StatCard(
                label: 'Total XP',
                value: '${friend.totalXpOn(now)}',
                icon: Icons.bolt,
                iconColor: tokens.brandOrange,
              ),
            ],
          ),
          Row(
            children: [
              StatCard(
                label: 'This week',
                value: '${friend.weekXpOn(now)} XP',
                icon: Icons.calendar_today_outlined,
                iconColor: tokens.choice,
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        DivisionBadge(division: friend.division, size: 30),
                        const SizedBox(height: 6),
                        Text(
                          friend.division.label,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Division',
                          style: text.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                'Recent lessons',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            for (final (day, title) in recent)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: tokens.brandYellow,
                  child: Icon(
                    Icons.check_rounded,
                    color: tokens.onYellowOrange,
                  ),
                ),
                title: Text(
                  title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(day),
              ),
          ],
        ],
      ),
    );
  }
}
