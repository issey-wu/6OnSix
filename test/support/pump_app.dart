import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/router.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/clock.dart';
import 'package:six_on_six/core/domain/user_state.dart';

/// Opens the whole app with [state] and the real course, with Reduce Motion
/// on, at [location].
Future<ProviderContainer> pumpWholeApp(
  WidgetTester tester, {
  required StoredState state,
  String? location,
  Clock? clock,
  Size size = const Size(1170, 2532),
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      initialStateProvider.overrideWithValue(state),
      progressRepositoryProvider.overrideWithValue(
        InMemoryProgressRepository(state),
      ),
      if (clock != null) clockProvider.overrideWithValue(clock),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SixOnSixApp()),
  );
  await tester.pumpAndSettle();
  if (location != null) {
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }
  return container;
}
