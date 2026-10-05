import 'package:meta/meta.dart';

/// Game-rule parameters, kept in one place.
///
/// The default values are placeholders until the team decides which 4TR1
/// rules survive (see "Open items" in docs/project-context.md). Lockouts are
/// off by default; [errorCap] and [retryCooldown] apply only when
/// [lockoutsEnabled] is true.
@immutable
class GameRules {
  const new({
    this.passThreshold = 0.8,
    this.errorCap = 10,
    this.retryCooldown = const Duration(hours: 1),
    this.lockoutsEnabled = false,
  });

  /// Fraction of correct answers (0 to 1) needed to pass a lesson.
  final double passThreshold;

  /// Maximum wrong answers allowed per 24 hours.
  final int errorCap;

  /// Wait before a failed review can be retried.
  final Duration retryCooldown;

  /// Whether [errorCap] and [retryCooldown] are enforced.
  final bool lockoutsEnabled;

  @override
  bool operator ==(Object other) =>
      other is GameRules &&
      other.passThreshold == passThreshold &&
      other.errorCap == errorCap &&
      other.retryCooldown == retryCooldown &&
      other.lockoutsEnabled == lockoutsEnabled;

  @override
  int get hashCode =>
      Object.hash(passThreshold, errorCap, retryCooldown, lockoutsEnabled);
}
