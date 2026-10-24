import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/features/learning_path/presentation/home_screen.dart';
import 'package:six_on_six/features/lesson/presentation/lesson_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
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
