import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/app_shell.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/features/glossary/presentation/glossary_screen.dart';
import 'package:six_on_six/features/glossary/presentation/term_screen.dart';
import 'package:six_on_six/features/learning_path/presentation/home_screen.dart';
import 'package:six_on_six/features/lesson/presentation/lesson_screen.dart';
import 'package:six_on_six/features/profile/presentation/profile_screen.dart';
import 'package:six_on_six/features/profile/presentation/settings_screen.dart';
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
        path: '/lesson/:nodeId',
        builder: (context, state) =>
            LessonScreen(nodeId: state.pathParameters['nodeId']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
