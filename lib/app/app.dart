import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/reminders.dart';
import 'package:six_on_six/app/router.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/user_state.dart';
import 'package:six_on_six/core/ui/tap_haptics.dart';

class SixOnSixApp extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SixOnSixApp> createState() => _SixOnSixAppState();
}

class _SixOnSixAppState extends ConsumerState<SixOnSixApp> {
  @override
  void initState() {
    super.initState();
    // Books practice reminders now, and again whenever they need changing.
    ref.read(reminderSyncProvider);
    // Everyday tap haptics follow the Haptics setting.
    ref.listenManual(
      settingsProvider.select((s) => s.hapticsOn),
      (_, on) => TapHaptics.enabled = on,
      fireImmediately: true,
    );
    // A streak freeze covers any days missed since the app was last used.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(progressProvider.notifier).checkStreakFreezes();
      ref.read(leagueProvider.notifier).settle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    return MaterialApp.router(
      title: '6 On Six',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (theme) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      routerConfig: ref.watch(routerProvider),
    );
  }
}
