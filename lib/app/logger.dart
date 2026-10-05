import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// The project's logger. Use this instead of `print`.
///
/// Debug builds log every level; release builds log warnings and errors only.
class AppLogger {
  const new(this.name);

  final String name;

  void debug(String message) => _log(LogLevel.debug, message);

  void info(String message) => _log(LogLevel.info, message);

  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode && level.index < LogLevel.warning.index) return;
    final buffer = StringBuffer(
      '[${level.name.toUpperCase()}] $name: $message',
    );
    if (error != null) buffer.write('\n  error: $error');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    debugPrint(buffer.toString());
  }
}
