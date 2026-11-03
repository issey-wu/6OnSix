import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/features/glossary/presentation/glossary_screen.dart';
import 'package:six_on_six/features/learning_path/presentation/home_screen.dart';
import 'package:six_on_six/features/lesson/presentation/lesson_screen.dart';
import 'package:six_on_six/features/onboarding/presentation/welcome_screen.dart';
import 'package:six_on_six/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('a new install opens on the welcome screen, with no tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SixOnSixApp()));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Learn the game. Own the court.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Get started goes straight into the first lesson', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SixOnSixApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('A court of two halves'), findsOneWidget);
  });

  testWidgets('after the welcome, the app has Learn, Glossary and Profile', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(preferencesProvider.notifier).markWelcomeSeen();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SixOnSixApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hey there'), findsOneWidget);
    expect(find.text('Court, positions and roles'), findsOneWidget);
    expect(find.text('The court'), findsOneWidget);

    await tester.tap(find.text('Glossary'));
    await tester.pumpAndSettle();
    expect(find.byType(GlossaryScreen), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Player'), findsOneWidget);
  });
}
