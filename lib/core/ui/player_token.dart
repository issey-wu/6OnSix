import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';

/// Full role names for player tokens, for screen readers.
const playerRoleNames = {
  'S': 'Setter',
  'OH1': 'Outside hitter 1',
  'OH2': 'Outside hitter 2',
  'MB1': 'Middle blocker 1',
  'MB2': 'Middle blocker 2',
  'OPP': 'Opposite',
  'L': 'Libero',
};

/// The full role name for a token such as "OH1", or the token itself.
String playerRoleName(String token) => playerRoleNames[token] ?? token;

/// A round player token with a short role label, such as "OH1".
///
/// Design by Yash Dubey (yash/screens). The libero wears a contrasting
/// jersey, so its token does too. [lifted] adds a deeper shadow while the
/// token is being dragged.
class PlayerToken extends StatelessWidget {
  const new({
    required this.label,
    this.selected = false,
    this.lifted = false,
    this.size = 48,
    super.key,
  });

  final String label;
  final bool selected;
  final bool lifted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final libero = label == 'L';
    return Semantics(
      label: '${playerRoleName(label)}${selected ? ', selected' : ''}',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: libero ? scheme.onSurface : tokens.brandOrange,
          border: selected
              ? Border.all(color: AppTheme.buttonRed, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: lifted ? 0.3 : 0.12),
              blurRadius: lifted ? 12 : 2,
              offset: Offset(0, lifted ? 6 : 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: size * 0.27,
            fontWeight: FontWeight.w800,
            color: libero ? scheme.surface : tokens.onYellowOrange,
          ),
        ),
      ),
    );
  }
}
