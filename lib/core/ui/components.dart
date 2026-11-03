import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';

// Shared building blocks used across screens. Every colour comes from the
// theme tokens, so restyling a component here restyles it everywhere.

/// A large, full-width answer card for multiple choice and true or false.
class OptionTile extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    this.centered = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected
              ? tokens.selectedBg
              : Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: selected ? tokens.brandOrange : tokens.surfaceMuted,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The panel that slides up after Check.
class FeedbackPanel extends StatelessWidget {
  const new({
    required this.correct,
    required this.title,
    required this.explanation,
    required this.onContinue,
    this.note,
    this.extra,
    super.key,
  });

  final bool correct;
  final String title;
  final String explanation;
  final String? note;
  final VoidCallback onContinue;

  /// Shown under the title, such as the correct court arrangement.
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final fg = correct ? tokens.onSuccess : tokens.onError;
    final note = this.note;
    final extra = this.extra;
    return Container(
      width: double.infinity,
      color: correct ? tokens.successBg : tokens.errorBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(correct ? Icons.check_circle : Icons.cancel, color: fg),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (extra != null) ...[
              const SizedBox(height: 8),
              Center(child: extra),
            ],
            const SizedBox(height: 6),
            Text(explanation, style: text.bodyMedium?.copyWith(color: fg)),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(
                'League note: $note',
                style: text.bodySmall?.copyWith(color: fg),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: correct ? tokens.success : tokens.error,
              ),
              onPressed: onContinue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small card with a big number and a label, used on the lesson complete
/// and profile screens.
class StatCard extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Card(
        child: Semantics(
          label: '$label: $value',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                if (icon != null) Icon(icon, color: iconColor),
                Text(
                  value,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: text.labelMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The brand-red card that opens each unit on the learning path.
class UnitHeader extends StatelessWidget {
  const new({
    required this.number,
    required this.title,
    required this.description,
    super.key,
  });

  final int number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      header: true,
      child: Container(
        margin: const EdgeInsets.only(top: 16, bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.buttonRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UNIT $number',
              style: text.labelLarge?.copyWith(color: tokens.onBrandRed),
            ),
            Text(
              title,
              style: text.titleLarge?.copyWith(
                color: tokens.onBrandRed,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              description,
              style: text.bodyMedium?.copyWith(color: tokens.onBrandRed),
            ),
          ],
        ),
      ),
    );
  }
}

/// A streak flame and number. Greyed out when the streak is zero.
class StreakBadge extends StatelessWidget {
  const new({required this.streak, super.key});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Semantics(
      label: '$streak day streak',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: streak > 0 ? tokens.brandOrange : tokens.textSecondary,
          ),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
