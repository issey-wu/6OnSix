import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/motion.dart';

/// The app icon artwork, a flaming volleyball by Yash Dubey.
const appLogoAsset = 'assets/images/app_logo.png';

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
              PopIn(
                scale: true,
                duration: const Duration(milliseconds: 600),
                child: Bob(
                  child: Semantics(
                    image: true,
                    label: '6 On Six logo, a flaming volleyball',
                    child: Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: tokens.brandRed.withValues(alpha: 0.22),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(34),
                        child: Image.asset(appLogoAsset, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              PopIn(
                delay: const Duration(milliseconds: 200),
                child: Semantics(
                  header: true,
                  child: Text.rich(
                    TextSpan(
                      text: '6 On ',
                      children: [
                        TextSpan(
                          text: 'Six',
                          style: TextStyle(color: tokens.brandOrange),
                        ),
                      ],
                    ),
                    style: text.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: tokens.brandRed,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              PopIn(
                delay: const Duration(milliseconds: 320),
                child: Text(
                  'Learn the game. Own the court.',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              PopIn(
                delay: const Duration(milliseconds: 420),
                child: Text(
                  'Quick lessons on rules, positions, and rotations. '
                  'Works offline.',
                  style: text.bodyLarge?.copyWith(color: tokens.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              PopIn(
                delay: const Duration(milliseconds: 560),
                offset: 40,
                child: FilledButton(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
