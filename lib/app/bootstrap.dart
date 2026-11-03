import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/logger.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/core/data/database.dart';
import 'package:six_on_six/core/data/drift_progress_repository.dart';
import 'package:six_on_six/core/data/in_memory_progress_repository.dart';
import 'package:six_on_six/core/domain/clock.dart';
import 'package:six_on_six/core/domain/progress_repository.dart';
import 'package:six_on_six/core/domain/user_state.dart';

const _logger = AppLogger('bootstrap');

/// Starts the app: routes uncaught errors to the logger, loads saved
/// progress from the device, then runs the widget tree inside the Riverpod
/// [ProviderScope].
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    _logger.error(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
    // Keeps the debug red screen and console dump.
    FlutterError.presentError(details);
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stackTrace) {
    _logger.error('Uncaught error', error: error, stackTrace: stackTrace);
    return true;
  };

  ProgressRepository repository;
  StoredState initial;
  try {
    repository = DriftProgressRepository(
      openAppDatabase(),
      clock: const SystemClock(),
    );
    initial = await repository.load();
  } on Object catch (error, stackTrace) {
    // The app still works without saving rather than failing to start.
    _logger.error(
      'Could not open the progress database',
      error: error,
      stackTrace: stackTrace,
    );
    repository = InMemoryProgressRepository();
    initial = const StoredState();
  }

  runApp(
    ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repository),
        initialStateProvider.overrideWithValue(initial),
      ],
      child: const SixOnSixApp(),
    ),
  );
}
