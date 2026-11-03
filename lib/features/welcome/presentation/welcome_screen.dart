import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';

/// First launch only. Get started opens the first lesson directly, with no
/// sign-up or questionnaire.
class WelcomeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider).value;
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: tokens.brandYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_volleyball,
                  size: 84,
                  color: AppTheme.buttonRed,
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text.rich(
                  const TextSpan(
                    text: '6 On ',
                    children: [
                      TextSpan(
                        text: 'Six',
                        style: TextStyle(color: AppTheme.buttonRed),
                      ),
                    ],
                  ),
                  style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Learn the game. Own the court.',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Quick lessons on rules, positions, and rotations. '
                'Works offline.',
                style: text.bodyLarge?.copyWith(color: tokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: course == null
                    ? null
                    : () {
                        final settings = ref.read(settingsProvider);
                        ref
                            .read(settingsProvider.notifier)
                            .update(settings.copyWith(welcomeSeen: true));
                        context.go('/learn');
                        unawaited(
                          context.push('/lesson/${course.path.first.id}'),
                        );
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
