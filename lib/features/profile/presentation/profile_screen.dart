import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/avatar_view.dart';
import 'package:six_on_six/core/ui/components.dart';
import 'package:six_on_six/core/ui/dialogs.dart';
import 'package:six_on_six/features/profile/presentation/achievements_section.dart';

/// The Profile tab: name, streak, XP, lessons and units completed, and
/// progress for each unit.
class ProfileScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider).value;
    final progress = ref.watch(progressProvider);
    final name = ref.watch(nameProvider);
    final avatar = ref.watch(avatarProvider);
    final streak = progress.streakOn(ref.watch(clockProvider).now().toLocal());
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;

    final units = course?.units ?? const [];
    final lessons = [for (final u in units) ...u.lessons];
    final lessonsDone = lessons
        .where((l) => progress.completed.contains(l.id))
        .length;
    final unitsDone = units
        .where((u) => progress.completed.contains(u.reviewId))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => unawaited(context.push('/profile/settings')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: avatar == null ? 'Create your avatar' : 'Edit avatar',
                excludeSemantics: true,
                child: InkResponse(
                  key: const ValueKey('edit-avatar'),
                  onTap: () => unawaited(context.push('/avatar')),
                  radius: 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (avatar != null)
                        AvatarView(avatar: avatar, size: 84)
                      else
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: tokens.brandYellow,
                          child: Text(
                            (name ?? 'Player')[0].toUpperCase(),
                            style: text.headlineMedium?.copyWith(
                              color: tokens.onYellowOrange,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: tokens.brandOrange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            avatar == null
                                ? Icons.add_rounded
                                : Icons.edit_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Name: ${name ?? 'Player'}. Double tap to edit.',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => unawaited(_editName(context, ref, name)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name ?? 'Player',
                                  style: text.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  name == null
                                      ? 'Tap to add your name'
                                      : 'Tap to edit',
                                  style: text.bodySmall?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_rounded, color: tokens.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (avatar == null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('create-avatar'),
              onPressed: () => unawaited(context.push('/avatar')),
              icon: const Icon(Icons.face_retouching_natural_rounded),
              label: const Text('Create your avatar'),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              StatCard(
                label: 'Day streak',
                value: '$streak',
                icon: Icons.local_fire_department_rounded,
                iconColor: streak > 0
                    ? tokens.brandOrange
                    : tokens.textSecondary,
              ),
              StatCard(
                label: 'Total XP',
                value: '${progress.xp}',
                icon: Icons.bolt_rounded,
                iconColor: tokens.brandOrange,
              ),
            ],
          ),
          Row(
            children: [
              StatCard(
                label: 'Lessons',
                value: '$lessonsDone / ${lessons.length}',
                icon: Icons.check_circle_rounded,
                iconColor: tokens.success,
              ),
              StatCard(
                label: 'Units',
                value: '$unitsDone / ${units.length}',
                icon: Icons.emoji_events_rounded,
                iconColor: tokens.brandOrange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const AchievementsSection(),
          const SizedBox(height: 24),
          Text(
            'Units',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final (i, unit) in units.indexed)
            Builder(
              builder: (context) {
                final nodes = [...unit.lessons.map((l) => l.id), unit.reviewId];
                final done = nodes.where(progress.completed.contains).length;
                final share = nodes.isEmpty ? 0.0 : done / nodes.length;
                return Semantics(
                  label:
                      'Unit ${i + 1}, ${unit.title}: '
                      '$done of ${nodes.length} done',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit ${i + 1}: ${unit.title}',
                          style: text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ChunkyBar(value: share, height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final result = await textSheet(
      context,
      title: 'Your name',
      initial: current ?? '',
      hint: 'Player',
    );
    if (result != null) ref.read(nameProvider.notifier).set(result);
  }
}
