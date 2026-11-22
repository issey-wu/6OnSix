import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/app/tips.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/ui/ace.dart';
import 'package:six_on_six/core/ui/ace_lines.dart';
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
              const PopIn(
                scale: true,
                duration: Duration(milliseconds: 600),
                child: AceSays(
                  text: aceHello,
                  action: AceAction.wave,
                  aceHeight: 200,
                  bubbleWidth: 300,
                  above: true,
                ),
              ),
              const SizedBox(height: 24),
              PopIn(
                delay: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      image: true,
                      label: '6 On Six logo, a flaming volleyball',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          appLogoAsset,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
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
                  ],
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
              const SizedBox(height: 4),
              TextButton(
                key: const ValueKey('skip-tutorial'),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: course == null
                    ? null
                    : () async {
                        if (!await confirmSkipTutorial(context)) return;
                        final settings = ref.read(settingsProvider);
                        ref
                            .read(settingsProvider.notifier)
                            .update(
                              settings.copyWith(
                                welcomeSeen: true,
                                tipsSeen: Tips.all,
                              ),
                            );
                        if (context.mounted) context.go('/learn');
                      },
                child: const Text("I've played before. Skip the tutorial"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
