import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/router.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/avatar.dart';
import 'package:six_on_six/core/domain/tips.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:six_on_six/core/ui/avatar_view.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = const Size(2400, 4800);
  addTearDown(tester.view.resetPhysicalSize);
  const state = StoredState(
    settings: AppSettings(welcomeSeen: true, tipsSeen: Tips.all),
  );
  final container = ProviderContainer(
    overrides: [
      initialStateProvider.overrideWithValue(state),
      progressRepositoryProvider.overrideWithValue(
        InMemoryProgressRepository(state),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SixOnSixApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the profile offers to create an avatar, and a ready-made one '
      'is saved', (tester) async {
    final container = await _pump(tester);
    container.read(routerProvider).go('/profile');
    await tester.pumpAndSettle();
    expect(find.text('Create your avatar'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('create-avatar')));
    expect(find.text('Your avatar'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('preset-3')));
    await _tap(tester, find.byKey(const ValueKey('save-avatar')));

    expect(container.read(avatarProvider), avatarPresets[3]);
    expect(find.text('Create your avatar'), findsNothing);
    expect(find.byType(AvatarView), findsOneWidget);
  });

  testWidgets('build your own changes each part of the avatar', (tester) async {
    final container = await _pump(tester);
    container.read(routerProvider).go('/profile');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('edit-avatar')));
    await _tap(tester, find.text('Build your own'));

    await _tap(tester, find.byKey(const ValueKey('skin-5')));
    await _tap(tester, find.byKey(const ValueKey('hair-bun')));
    await _tap(tester, find.byKey(const ValueKey('hair-color-4')));
    await _tap(tester, find.byKey(const ValueKey('jersey-2')));
    await _tap(tester, find.byKey(const ValueKey('number-up')));
    await _tap(tester, find.byKey(const ValueKey('headband')));
    await _tap(tester, find.byKey(const ValueKey('save-avatar')));

    final first = avatarPresets.first;
    expect(
      container.read(avatarProvider),
      Avatar(
        skin: 5,
        hair: HairStyle.bun,
        hairColor: 4,
        jersey: 2,
        number: first.number + 1,
        headband: !first.headband,
      ),
    );
  });
}
