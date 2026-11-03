import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:six_on_six/features/learning_path/presentation/home_screen.dart';
import 'package:six_on_six/features/welcome/presentation/welcome_screen.dart';

Future<void> pumpApp(WidgetTester tester, StoredState state) async {
  // Turns off the looping pulse on the current node so the test can settle.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialStateProvider.overrideWithValue(state),
        progressRepositoryProvider.overrideWithValue(
          InMemoryProgressRepository(state),
        ),
      ],
      child: const SixOnSixApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch shows the welcome screen, then Lesson 1.1', (
    tester,
  ) async {
    await pumpApp(tester, const StoredState());
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('A court of two halves'), findsOneWidget);
  });

  testWidgets('a returning learner opens on the learning path', (tester) async {
    await pumpApp(
      tester,
      const StoredState(settings: AppSettings(welcomeSeen: true)),
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('6 On Six'), findsOneWidget);
    expect(find.text('Court, positions and roles'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Glossary'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('glossary search filters terms and shows a no-match message', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const StoredState(settings: AppSettings(welcomeSeen: true)),
    );
    await tester.tap(find.text('Glossary'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'libero');
    await tester.pumpAndSettle();
    expect(find.text('Libero'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('No terms match'), findsOneWidget);
  });
}
