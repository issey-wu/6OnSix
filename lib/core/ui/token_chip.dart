import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';

/// A round player token such as S, OH1 or L. The libero gets the brand red,
/// the same way a libero wears a different coloured jersey.
class TokenChip extends StatelessWidget {
  const new({required this.label, this.selected = false, super.key});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final isLibero = label == 'L';
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLibero ? AppTheme.buttonRed : tokens.brandYellow,
        border: Border.all(
          color: selected ? tokens.brandOrange : tokens.onYellowOrange,
          width: selected ? 4 : 2,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: isLibero ? tokens.onBrandRed : tokens.onYellowOrange,
        ),
      ),
    );
  }
}
