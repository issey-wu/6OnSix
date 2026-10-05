import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/core/domain/clock.dart';
import 'package:six_on_six/core/domain/game_rules.dart';

/// The time source for all app logic. Override in tests to control time.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Game-rule parameters. Override to change rules (e.g. for user testing).
final gameRulesProvider = Provider<GameRules>((ref) => const GameRules());
