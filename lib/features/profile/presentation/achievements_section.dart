import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/achievements.dart';
import 'package:six_on_six/core/ui/badge_art.dart';
import 'package:six_on_six/core/ui/components.dart';

/// The Achievements part of the Profile tab: every badge, its level, and a
/// tap for what the next level takes.
class AchievementsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider).value;
    if (course == null) return const SizedBox.shrink();
    final stats = AchievementStats.from(
      progress: ref.watch(progressProvider),
      motivation: ref.watch(motivationProvider),
      course: course,
    );
    final achievements = achievementsFor(course);
    final text = Theme.of(context).textTheme;
    final earned = achievements.where((a) => stats.levelOf(a) > 0).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Achievements',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Text(
              '$earned of ${achievements.length} earned',
              style: text.bodyMedium?.copyWith(
                color: AppTokens.of(context).textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            const perRow = 4;
            const gap = 10.0;
            final width = (box.maxWidth - gap * (perRow - 1)) / perRow;
            return Wrap(
              spacing: gap,
              runSpacing: 14,
              children: [
                for (final a in achievements)
                  SizedBox(
                    width: width,
                    child: _BadgeTile(
                      achievement: a,
                      stats: stats,
                      size: width * 0.86,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const new({
    required this.achievement,
    required this.stats,
    required this.size,
  });

  final Achievement achievement;
  final AchievementStats stats;
  final double size;

  @override
  Widget build(BuildContext context) {
    final level = stats.levelOf(achievement);
    final tokens = AppTokens.of(context);
    return Semantics(
      button: true,
      label:
          '${achievement.title}, '
          '${level == 0 ? 'not earned yet' : 'level $level of 4'}',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('badge-${achievement.kind.name}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => unawaited(showBadgeSheet(context, achievement, stats)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              BadgeArt(kind: achievement.kind, level: level, size: size),
              const SizedBox(height: 6),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
              ),
              Text(
                level == 0 ? 'Locked' : 'Level $level',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: tokens.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sheet with one badge: its level, and how close the next level is.
Future<void> showBadgeSheet(
  BuildContext context,
  Achievement achievement,
  AchievementStats stats,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final level = stats.levelOf(achievement);
    final count = stats.countOf(achievement.kind);
    final maxed = level >= achievement.levels.length;
    final target = maxed ? achievement.levels.last : achievement.levels[level];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: BadgeArt(kind: achievement.kind, level: level, size: 96),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            level == 0 ? 'Not earned yet' : 'Level $level of 4',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            maxed
                ? 'Every level earned. Nice work!'
                : 'Next: ${achievement.goalFor(level + 1)}.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ShineBar(
            value: (count / target).clamp(0, 1).toDouble(),
            color: tokens.brandOrange,
            track: tokens.surfaceMuted,
            semanticsLabel: 'Badge progress',
          ),
          const SizedBox(height: 6),
          Text(
            '${count.clamp(0, target)} of $target',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('badge-ok'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  },
);
