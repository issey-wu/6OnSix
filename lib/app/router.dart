import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/main_shell.dart';
import 'package:six_on_six/features/glossary/presentation/glossary_screen.dart';
import 'package:six_on_six/features/glossary/presentation/term_screen.dart';
import 'package:six_on_six/features/learning_path/presentation/home_screen.dart';
import 'package:six_on_six/features/lesson/presentation/lesson_screen.dart';
import 'package:six_on_six/features/profile/presentation/profile_screen.dart';
import 'package:six_on_six/features/settings/presentation/settings_screen.dart';

/// The app's map of screens. Learn, Glossary and Profile are tabs that keep
/// their own history; the lesson player sits above them, so the bottom
/// navigation bar is hidden inside a lesson.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/glossary',
                name: 'glossary',
                builder: (context, state) => const GlossaryScreen(),
                routes: [
                  GoRoute(
                    path: ':termId',
                    name: 'term',
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
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    name: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/lesson/:nodeId',
        name: 'lesson',
        builder: (context, state) =>
            LessonScreen(nodeId: state.pathParameters['nodeId']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
