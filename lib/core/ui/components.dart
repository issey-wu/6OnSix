import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/motivation.dart';
import 'package:six_on_six/core/ui/motion.dart';

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
    final edge = selected ? tokens.choice : tokens.surfaceMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Semantics(
        button: true,
        selected: selected,
        child: TweenAnimationBuilder<double>(
          // A small bounce when picked.
          key: ValueKey(selected),
          tween: Tween(begin: selected ? 0.95 : 1, end: 1),
          duration: motion(context, const Duration(milliseconds: 260)),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Material(
            color: selected
                ? tokens.choiceBg
                : Theme.of(context).colorScheme.surface,
            animationDuration: motion(
              context,
              const Duration(milliseconds: 120),
            ),
            shape: LedgeBorder(
              radius: 14,
              side: BorderSide(color: edge, width: 2),
            ),
            child: InkWell(
              customBorder: const LedgeBorder(radius: 14),
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                alignment: centered ? Alignment.center : Alignment.centerLeft,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? tokens.choice : null,
                  ),
                ),
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
    this.onShowMeHow,
    super.key,
  });

  final bool correct;
  final String title;
  final String explanation;
  final String? note;
  final VoidCallback onContinue;

  /// Shown under the title, such as the correct court arrangement.
  final Widget? extra;

  /// Opens the step-by-step explanation. The button is hidden when null.
  final VoidCallback? onShowMeHow;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final fg = correct ? tokens.onSuccess : tokens.onError;
    final note = this.note;
    final extra = this.extra;
    final onShowMeHow = this.onShowMeHow;
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
                PopIn(
                  scale: true,
                  offset: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: correct ? tokens.success : tokens.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      correct ? Icons.check_rounded : Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      title,
                      style: text.titleLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w900,
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
            if (onShowMeHow != null) ...[
              OutlinedButton.icon(
                key: const ValueKey('show-me-how'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: fg,
                  side: BorderSide(color: fg, width: 1.5),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: onShowMeHow,
                icon: const Icon(Icons.school_outlined),
                label: const Text('Show me how'),
              ),
              const SizedBox(height: 8),
            ],
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
    this.countTo,
    this.prefix = '',
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  /// When set, the number counts up to this instead of showing [value].
  final int? countTo;

  /// Shown before a counted number, such as "+".
  final String prefix;

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
                if (countTo case final count?)
                  CountUpText(
                    value: count,
                    prefix: prefix,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  )
                else
                  Text(
                    value,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
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
    required this.title,
    required this.description,
    this.number,
    super.key,
  });

  /// The unit number. Null for the final review section.
  final int? number;
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
        decoration: ShapeDecoration(
          color: tokens.brandRed,
          shape: const LedgeBorder(radius: 18, ledge: 5),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 19),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number == null ? 'ALL UNITS' : 'UNIT $number',
                    style: text.labelLarge?.copyWith(
                      color: tokens.onBrandRed.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    title,
                    style: text.titleLarge?.copyWith(
                      color: tokens.onBrandRed,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: text.bodyMedium?.copyWith(color: tokens.onBrandRed),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              number == null ? Icons.military_tech : Icons.sports_volleyball,
              size: 40,
              color: tokens.brandYellow,
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

/// Today's XP against the daily goal, as a labelled bar.
class DailyGoalBar extends StatelessWidget {
  const new({required this.xp, required this.goal, super.key});

  final int xp;
  final DailyGoal goal;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final met = xp >= goal.xp;
    final label = met ? 'Daily goal met!' : 'Daily goal: $xp of ${goal.xp} XP';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: met ? tokens.success : null,
            ),
          ),
          const SizedBox(height: 6),
          ChunkyBar(
            value: xp / goal.xp,
            color: met ? tokens.success : tokens.brandOrange,
          ),
        ],
      ),
    );
  }
}

/// A small ring that fills toward today's goal, with the XP inside.
class GoalRing extends StatelessWidget {
  const new({required this.xp, required this.goal, this.onTap, super.key});

  final int xp;
  final DailyGoal goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final met = xp >= goal.xp;
    return Semantics(
      button: onTap != null,
      label: met
          ? 'Daily goal met, $xp XP today'
          : 'Daily goal, $xp of ${goal.xp} XP today',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(
          dimension: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: (xp / goal.xp).clamp(0.0, 1.0),
                strokeWidth: 4,
                color: met ? tokens.success : tokens.brandOrange,
                backgroundColor: tokens.surfaceMuted,
              ),
              Icon(
                met ? Icons.check : Icons.flag,
                size: 16,
                color: met ? tokens.success : tokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thick rounded progress bar with a shine along the top of the fill. The
/// fill eases to each new value.
class ChunkyBar extends StatelessWidget {
  const new({
    required this.value,
    this.color,
    this.height = 14,
    this.semanticsLabel,
    super.key,
  });

  /// From 0 to 1. Values outside are clamped.
  final double value;
  final Color? color;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final fill = color ?? tokens.brandOrange;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: motion(context, const Duration(milliseconds: 600)),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => ShineBar(
        value: v,
        color: fill,
        track: tokens.surfaceMuted,
        height: height,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}

/// Draws one frame of a rounded progress bar with a shine. Uses a
/// [LinearProgressIndicator] underneath, for screen readers and tests.
class ShineBar extends StatelessWidget {
  const new({
    required this.value,
    required this.color,
    required this.track,
    this.height = 14,
    this.semanticsLabel,
    super.key,
  });

  final double value;
  final Color color;
  final Color track;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: Stack(
      children: [
        LinearProgressIndicator(
          value: value,
          minHeight: height,
          color: color,
          backgroundColor: track,
          semanticsLabel: semanticsLabel,
        ),
        Positioned(
          left: height / 2,
          right: 0,
          top: height * 0.22,
          height: height * 0.22,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value - 0.04).clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
