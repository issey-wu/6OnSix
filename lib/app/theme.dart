import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Colour tokens for the Flame Court look, taken from the app icon: maroon,
/// flame orange, and the volleyball's yellow and blue. Screens read colours
/// from here or from the [ColorScheme]; no screen hard-codes a colour.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const new({
    required this.brandRed,
    required this.onBrandRed,
    required this.brandOrange,
    required this.brandYellow,
    required this.onYellowOrange,
    required this.surfaceMuted,
    required this.textSecondary,
    required this.success,
    required this.successBg,
    required this.onSuccess,
    required this.error,
    required this.errorBg,
    required this.onError,
    required this.selectedBg,
    required this.choice,
    required this.choiceBg,
  });

  /// Maroon, the app icon's background. Unit banners and headings.
  final Color brandRed;
  final Color onBrandRed;

  /// Flame orange: the streak, progress and the current lesson.
  final Color brandOrange;

  /// Volleyball yellow: finished lessons and rewards.
  final Color brandYellow;
  final Color onYellowOrange;
  final Color surfaceMuted;
  final Color textSecondary;
  final Color success;
  final Color successBg;
  final Color onSuccess;
  final Color error;
  final Color errorBg;
  final Color onError;

  /// A warm orange tint behind hints, banners and highlighted cards.
  final Color selectedBg;

  /// Volleyball blue, for the answer the learner has picked.
  final Color choice;
  final Color choiceBg;

  static const flameCourt = AppTokens(
    brandRed: Color(0xFF800000),
    onBrandRed: Color(0xFFFFF6EE),
    brandOrange: Color(0xFFF07A12),
    brandYellow: Color(0xFFFFD54A),
    onYellowOrange: Color(0xFF3A1C00),
    surfaceMuted: Color(0xFFEEE2D8),
    textSecondary: Color(0xFF7D6A62),
    success: Color(0xFF2FA84F),
    successBg: Color(0xFFE3F5E8),
    onSuccess: Color(0xFF1E6B33),
    error: Color(0xFFD7263D),
    errorBg: Color(0xFFFDE6E8),
    onError: Color(0xFF9B1426),
    selectedBg: Color(0xFFFFF0E0),
    choice: Color(0xFF3554B0),
    choiceBg: Color(0xFFE9EEFF),
  );

  static const flameCourtNight = AppTokens(
    brandRed: Color(0xFF9A1414),
    onBrandRed: Color(0xFFFFF6EE),
    brandOrange: Color(0xFFFF8A1F),
    brandYellow: Color(0xFFFFD54A),
    onYellowOrange: Color(0xFF3A1C00),
    surfaceMuted: Color(0xFF3A2C2B),
    textSecondary: Color(0xFFBBA9A5),
    success: Color(0xFF3DC463),
    successBg: Color(0xFF16301F),
    onSuccess: Color(0xFF9BE8B0),
    error: Color(0xFFFF5A6E),
    errorBg: Color(0xFF3A161C),
    onError: Color(0xFFFFB3BD),
    selectedBg: Color(0xFF3A2616),
    choice: Color(0xFF9BB0FF),
    choiceBg: Color(0xFF232B4D),
  );

  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ?? flameCourt;

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(AppTokens? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// A rounded rectangle with a thicker bottom edge, so buttons and cards look
/// like chunky keys that press down. The edge is a darker band inside the
/// shape: [ledgeColor] when set, otherwise the outline colour, or a shade of
/// whatever fill is underneath.
class LedgeBorder extends OutlinedBorder {
  const new({this.radius = 16, this.ledge = 4, this.ledgeColor, super.side});

  final double radius;

  /// Height of the bottom edge, in logical pixels.
  final double ledge;
  final Color? ledgeColor;

  static const _shade = Color(0x38000000);

  RRect _rrect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect).deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final rrect = _rrect(rect);
    if (ledge > 0) {
      final color =
          ledgeColor ?? (side.style == BorderStyle.none ? _shade : side.color);
      canvas
        ..save()
        ..clipRRect(rrect)
        ..drawRect(
          Rect.fromLTRB(
            rect.left,
            rect.bottom - ledge,
            rect.right,
            rect.bottom,
          ),
          Paint()..color = color,
        )
        ..restore();
    }
    if (side.style != BorderStyle.none && side.width > 0) {
      canvas.drawRRect(rrect.deflate(side.width / 2), side.toPaint());
    }
  }

  @override
  LedgeBorder copyWith({
    BorderSide? side,
    double? radius,
    double? ledge,
    Color? ledgeColor,
  }) => LedgeBorder(
    side: side ?? this.side,
    radius: radius ?? this.radius,
    ledge: ledge ?? this.ledge,
    ledgeColor: ledgeColor ?? this.ledgeColor,
  );

  @override
  LedgeBorder scale(double t) => LedgeBorder(
    side: side.scale(t),
    radius: radius * t,
    ledge: ledge * t,
    ledgeColor: ledgeColor,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is LedgeBorder) return _lerpBetween(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is LedgeBorder) return _lerpBetween(this, b, t);
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is LedgeBorder &&
      other.side == side &&
      other.radius == radius &&
      other.ledge == ledge &&
      other.ledgeColor == ledgeColor;

  @override
  int get hashCode => Object.hash(side, radius, ledge, ledgeColor);
}

LedgeBorder _lerpBetween(LedgeBorder a, LedgeBorder b, double t) => LedgeBorder(
  side: BorderSide.lerp(a.side, b.side, t),
  radius: lerpDouble(a.radius, b.radius, t)!,
  ledge: lerpDouble(a.ledge, b.ledge, t)!,
  ledgeColor: Color.lerp(a.ledgeColor, b.ledgeColor, t),
);

/// [duration], or zero when the phone's Reduce Motion setting is on.
Duration motion(BuildContext context, Duration duration) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false
    ? Duration.zero
    : duration;

abstract final class AppTheme {
  /// Flame orange for main buttons, a shade darker than the brand orange so
  /// the bold button labels keep a 3:1 contrast with white text.
  static const primary = Color(0xFFE8650A);

  static const fontFamily = 'Nunito';

  static final ThemeData light = _build(
    brightness: Brightness.light,
    background: const Color(0xFFFFFAF4),
    surface: const Color(0xFFFFFFFF),
    text: const Color(0xFF2B1410),
    tokens: AppTokens.flameCourt,
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    background: const Color(0xFF161112),
    surface: const Color(0xFF231B1B),
    text: const Color(0xFFF6ECEA),
    tokens: AppTokens.flameCourtNight,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required AppTokens tokens,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: tokens.choice,
          surface: surface,
          onSurface: text,
          error: tokens.error,
        );
    final base = ThemeData(
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      extensions: [tokens],
    );
    final type = _bolder(base.textTheme)
        .apply(bodyColor: text, displayColor: text);
    final outline = BorderSide(color: tokens.surfaceMuted, width: 2);

    // Main buttons sit on a darker edge that shrinks while pressed, and the
    // label moves down with it.
    final pressable = ButtonStyle(
      animationDuration: const Duration(milliseconds: 70),
      shape: WidgetStateProperty.resolveWith(
        (states) =>
            LedgeBorder(ledge: states.contains(WidgetState.pressed) ? 1 : 4),
      ),
      padding: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? const EdgeInsets.fromLTRB(20, 15, 20, 13)
            : const EdgeInsets.fromLTRB(20, 12, 20, 16),
      ),
    );

    return base.copyWith(
      textTheme: type,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: type.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          disabledBackgroundColor: tokens.surfaceMuted,
          disabledForegroundColor: tokens.textSecondary,
          textStyle: type.labelLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ).merge(pressable),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: text,
              textStyle: type.labelLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ).merge(
              ButtonStyle(
                animationDuration: const Duration(milliseconds: 70),
                side: WidgetStatePropertyAll(outline),
                shape: WidgetStateProperty.resolveWith(
                  (states) => LedgeBorder(
                    side: outline,
                    ledge: states.contains(WidgetState.pressed) ? 2 : 4,
                  ),
                ),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: type.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: LedgeBorder(side: outline),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.selectedBg,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? tokens.brandOrange
                : tokens.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => type.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? tokens.brandOrange
                : tokens.textSecondary,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: type.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: type.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: background,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: type.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        selectedColor: tokens.choiceBg,
        side: outline,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.selectedBg,
        hintStyle: type.titleMedium?.copyWith(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: outline,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: outline,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.choice, width: 2.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.brandOrange,
        linearTrackColor: tokens.surfaceMuted,
      ),
    );
  }

  /// Nunito reads best a little heavier than Material's defaults.
  static TextTheme _bolder(TextTheme t) => t.copyWith(
    displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w900),
    headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
    headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
    titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    bodyLarge: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    bodyMedium: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    bodySmall: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}
