import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/app_shell.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/features/avatar/presentation/avatar_screen.dart';
import 'package:six_on_six/features/glossary/presentation/glossary_screen.dart';
import 'package:six_on_six/features/glossary/presentation/term_screen.dart';
import 'package:six_on_six/features/goal/presentation/goal_screen.dart';
import 'package:six_on_six/features/learning_path/presentation/home_screen.dart';
import 'package:six_on_six/features/lesson/presentation/lesson_screen.dart';
import 'package:six_on_six/features/profile/presentation/profile_screen.dart';
import 'package:six_on_six/features/profile/presentation/settings_screen.dart';
import 'package:six_on_six/features/quests/presentation/quests_screen.dart';
import 'package:six_on_six/features/welcome/presentation/welcome_screen.dart';

/// The app's map of screens. The welcome screen shows on first launch only;
/// after that the app always opens on the Learn tab.
final routerProvider = Provider<GoRouter>((ref) {
  final welcomeSeen = ref.read(settingsProvider).welcomeSeen;
  final router = GoRouter(
    initialLocation: welcomeSeen ? '/learn' : '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quests',
                builder: (context, state) => const QuestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/glossary',
                builder: (context, state) => const GlossaryScreen(),
                routes: [
                  GoRoute(
                    path: ':termId',
                    builder: (context, state) =>
                        TermScreen(termId: state.pathParameters['termId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/goal',
        pageBuilder: (context, state) => _slideUp(state, const GoalScreen()),
      ),
      GoRoute(
        path: '/avatar',
        pageBuilder: (context, state) => _slideUp(state, const AvatarScreen()),
      ),
      GoRoute(
        path: '/lesson/:nodeId',
        pageBuilder: (context, state) => _slideUp(
          state,
          LessonScreen(nodeId: state.pathParameters['nodeId']!),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Full-screen tasks (a lesson, the goal or the avatar) rise up from the
/// bottom and drop away when closed. Reduce Motion shows them at once.
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
