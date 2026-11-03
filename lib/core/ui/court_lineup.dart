import 'package:flutter/material.dart';
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/core/ui/player_token.dart';

/// A small court with players already in place. Shows the correct
/// arrangement after a wrong drag-and-drop answer.
///
/// Design by Yash Dubey (yash/screens).
class CourtLineup extends StatelessWidget {
  const new({required this.placements, this.tokenSize = 34, super.key});

  /// Token to zone, such as {'S': 1, 'OPP': 4}.
  final Map<String, int> placements;
  final double tokenSize;

  @override
  Widget build(BuildContext context) {
    final byZone = {for (final e in placements.entries) e.value: e.key};
    final description = [
      for (final zone in courtZoneOrder)
        if (byZone[zone] case final token?)
          '${playerRoleName(token)} in zone $zone',
    ].join(', ');
    return Semantics(
      label: 'Correct arrangement: $description',
      excludeSemantics: true,
      child: CourtView(
        cellBuilder: (context, zone) => Center(
          child: switch (byZone[zone]) {
            final token? => PlayerToken(label: token, size: tokenSize),
            null => null,
          },
        ),
      ),
    );
  }
}
