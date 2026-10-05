import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/app/logger.dart';

const _logger = AppLogger('bootstrap');

/// Starts the app: routes uncaught errors to the logger, then runs the
/// widget tree inside the Riverpod [ProviderScope].
void bootstrap() {
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

  runApp(const ProviderScope(child: SixOnSixApp()));
}
