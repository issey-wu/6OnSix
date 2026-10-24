import 'package:flutter/material.dart';

/// Colour tokens from docs/design.md. Screens read colours from here or from
/// the [ColorScheme]; no screen hard-codes a colour.
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
  });

  final Color brandRed;
  final Color onBrandRed;
  final Color brandOrange;
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
  final Color selectedBg;

  static const rally = AppTokens(
    brandRed: Color(0xFFE03A1E),
    onBrandRed: Color(0xFFFFF6EE),
    brandOrange: Color(0xFFF7941D),
    brandYellow: Color(0xFFF2F55C),
    onYellowOrange: Color(0xFF3A1C00),
    surfaceMuted: Color(0xFFE8E4DA),
    textSecondary: Color(0xFF7A746A),
    success: Color(0xFF2FA84F),
    successBg: Color(0xFFE3F5E8),
    onSuccess: Color(0xFF1E6B33),
    error: Color(0xFFC2185B),
    errorBg: Color(0xFFFBE3EC),
    onError: Color(0xFF8E1145),
    selectedBg: Color(0xFFFEF1E2),
  );

  static const night = AppTokens(
    brandRed: Color(0xFFE03A1E),
    onBrandRed: Color(0xFFFFF6EE),
    brandOrange: Color(0xFFF7941D),
    brandYellow: Color(0xFFF2F55C),
    onYellowOrange: Color(0xFF3A1C00),
    surfaceMuted: Color(0xFF2A2C3A),
    textSecondary: Color(0xFFA9ADC9),
    success: Color(0xFF3DC463),
    successBg: Color(0xFF16301F),
    onSuccess: Color(0xFF9BE8B0),
    error: Color(0xFFE04882),
    errorBg: Color(0xFF3A1626),
    onError: Color(0xFFF4B3CB),
    selectedBg: Color(0xFF3A2A18),
  );

  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ?? rally;

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(AppTokens? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

abstract final class AppTheme {
  /// Button red: a darker brand red that meets the 4.5:1 contrast minimum
  /// with light text.
  static const buttonRed = Color(0xFFC9341A);

  static final ThemeData light = _build(
    brightness: Brightness.light,
    background: const Color(0xFFFBFAF5),
    surface: const Color(0xFFFFFFFF),
    text: const Color(0xFF2A1A10),
    tokens: AppTokens.rally,
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    background: const Color(0xFF121318),
    surface: const Color(0xFF1E2030),
    text: const Color(0xFFF2F2F5),
    tokens: AppTokens.night,
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
          seedColor: buttonRed,
          brightness: brightness,
        ).copyWith(
          primary: buttonRed,
          onPrimary: tokens.onBrandRed,
          surface: surface,
          onSurface: text,
          error: tokens.error,
        );
    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
      ),
    );
    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
