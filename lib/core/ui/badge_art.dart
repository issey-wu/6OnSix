import 'dart:math';

import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/achievements.dart';

/// Each badge's picture. Drawn in code for now, so Yash's artwork can
/// replace this one widget later without touching anything else.
const Map<AchievementKind, IconData> _pictures = {
  AchievementKind.streak: Icons.local_fire_department_rounded,
  AchievementKind.xp: Icons.bolt_rounded,
  AchievementKind.lessons: Icons.school_rounded,
  AchievementKind.perfect: Icons.verified_rounded,
  AchievementKind.units: Icons.emoji_events_rounded,
  AchievementKind.quests: Icons.redeem_rounded,
  AchievementKind.words: Icons.menu_book_rounded,
  AchievementKind.weak: Icons.fitness_center_rounded,
};

/// How tall a medal is for its width: the ribbon sits above the medal.
const medalAspect = 1.2;

/// An achievement badge as a medal on a ribbon in the team colours. The
/// level sets the metal: bronze, silver, gold, then a flame champion medal
/// at level 4. Grey until the first level.
class BadgeArt extends StatelessWidget {
  const new({
    required this.kind,
    required this.level,
    this.size = 72,
    super.key,
  });

  final AchievementKind kind;

  /// Levels reached, from 0 (locked) to 4.
  final int level;

  /// The medal's width. It is [medalAspect] times as tall.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size * medalAspect,
      child: CustomPaint(
        painter: _MedalPainter(
          picture: _pictures[kind]!,
          level: level,
          tokens: AppTokens.of(context),
        ),
      ),
    ),
  );
}

class _MedalPainter extends CustomPainter {
  new({required this.picture, required this.level, required this.tokens});

  final IconData picture;
  final int level;
  final AppTokens tokens;

  /// The face colour, the rim and raised edge, and the engraved picture.
  (Color, Color, Color) get _metal {
    final t = tokens;
    return switch (level) {
      <= 0 => (
        t.surfaceMuted,
        Color.lerp(t.surfaceMuted, t.textSecondary, 0.35)!,
        t.textSecondary,
      ),
      1 => (
        const Color(0xFFE3955A),
        const Color(0xFFA35A26),
        const Color(0xFF7A3E14),
      ),
      2 => (
        const Color(0xFFC9CED6),
        const Color(0xFF8A919C),
        const Color(0xFF5E6672),
      ),
      3 => (
        const Color(0xFFF7C736),
        const Color(0xFFC08A00),
        const Color(0xFF8A6200),
      ),
      _ => (t.brandOrange, t.brandRed, Colors.white),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = tokens;
    final w = size.width;
    final r = w * 0.38;
    final centre = Offset(w / 2, size.height - r - w * 0.06);
    final (face, edge, mark) = _metal;
    final locked = level <= 0;

    // The ribbon: two strips in the team colours, meeting behind the medal.
    final strip = w * 0.2;
    final ribbons = [
      (
        Offset(w * 0.28, strip / 2),
        Offset(w * 0.5 + strip * 0.2, centre.dy - r * 0.4),
        locked ? t.surfaceMuted : t.brandRed,
      ),
      (
        Offset(w * 0.72, strip / 2),
        Offset(w * 0.5 - strip * 0.2, centre.dy - r * 0.4),
        locked
            ? Color.lerp(t.surfaceMuted, t.textSecondary, 0.2)!
            : t.brandOrange,
      ),
    ];
    for (final (from, to, colour) in ribbons) {
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = colour
          ..strokeWidth = strip
          ..strokeCap = StrokeCap.round,
      );
    }

    // A raised edge like the app's buttons, the rim, then the face, lit
    // from the top left. The champion medal glows like a flame.
    final light = Rect.fromCircle(
      center: centre - Offset(r * 0.2, r * 0.25),
      radius: r * 1.1,
    );
    canvas
      ..drawCircle(centre + Offset(0, w * 0.05), r, Paint()..color = edge)
      ..drawCircle(centre, r, Paint()..color = edge)
      ..drawCircle(
        centre,
        r * 0.86,
        Paint()
          ..shader =
              (level >= 4
                      ? RadialGradient(
                          colors: [t.brandYellow, t.brandOrange, t.brandRed],
                          stops: const [0, 0.55, 1],
                        )
                      : RadialGradient(
                          colors: [Color.lerp(face, Colors.white, 0.35)!, face],
                        ))
                  .createShader(light),
      );

    // Faint volleyball seams across the face.
    final seam = Paint()
      ..color = Colors.white.withValues(alpha: locked ? 0.25 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05;
    final faceRadius = r * 0.86;
    for (var i = 0; i < 3; i++) {
      final angle = -pi / 2 + i * 2 * pi / 3;
      final rim = centre + Offset(cos(angle), sin(angle)) * faceRadius;
      final bend =
          centre +
          Offset(cos(angle + 0.9), sin(angle + 0.9)) * faceRadius * 0.55;
      canvas.drawPath(
        Path()
          ..moveTo(centre.dx, centre.dy)
          ..quadraticBezierTo(bend.dx, bend.dy, rim.dx, rim.dy),
        seam,
      );
    }

    // The badge's picture, engraved in a darker shade of the metal.
    final icon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(picture.codePoint),
        style: TextStyle(
          fontFamily: picture.fontFamily,
          package: picture.fontPackage,
          fontSize: r,
          color: mark,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    icon.paint(canvas, centre - Offset(icon.width / 2, icon.height / 2));
    icon.dispose();
  }

  @override
  bool shouldRepaint(_MedalPainter oldDelegate) =>
      oldDelegate.picture != picture ||
      oldDelegate.level != level ||
      oldDelegate.tokens != tokens;
}
