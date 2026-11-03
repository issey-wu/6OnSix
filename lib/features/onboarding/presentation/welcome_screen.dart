import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';

/// First launch only. Get started goes straight into the first lesson, with
/// no questions asked first.
class WelcomeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final course = ref.watch(courseProvider).value;
    final firstNode = course == null || course.path.isEmpty
        ? null
        : course.path.first;

    return Scaffold(
      backgroundColor: tokens.brandRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                '6 On Six',
                style: text.displaySmall?.copyWith(
                  color: tokens.onBrandRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Learn the game. Own the court.',
                style: text.headlineSmall?.copyWith(
                  color: tokens.onBrandRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Quick lessons on rules, positions, and rotations. '
                'Works offline.',
                style: text.bodyLarge?.copyWith(color: tokens.onBrandRed),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.onBrandRed,
                  foregroundColor: AppTheme.buttonRed,
                ),
                onPressed: firstNode == null
                    ? null
                    : () {
                        final router = GoRouter.of(context);
                        unawaited(router.push('/lesson/${firstNode.id}'));
                        ref
                            .read(preferencesProvider.notifier)
                            .markWelcomeSeen();
                      },
                child: const Text('Get started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
