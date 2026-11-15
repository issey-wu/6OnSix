import 'dart:math';

import 'package:flutter/material.dart';
import 'package:six_on_six/core/domain/avatar.dart';

/// Colours for each avatar option, in the order of the indexes stored in
/// [Avatar].
abstract final class AvatarPalette {
  static const skinTones = [
    Color(0xFFFBE0C8),
    Color(0xFFF1C27D),
    Color(0xFFE0AC69),
    Color(0xFFC68642),
    Color(0xFF8D5524),
    Color(0xFF5C3A1E),
  ];

  static const hairColors = [
    Color(0xFF1F1A17),
    Color(0xFF4A2C1A),
    Color(0xFF8A5A2B),
    Color(0xFFB5482A),
    Color(0xFFE8C468),
    Color(0xFFB8B4AE),
  ];

  static const hairColorNames = [
    'Black',
    'Dark brown',
    'Brown',
    'Auburn',
    'Blonde',
    'Grey',
  ];

  /// Jersey colour and the colour of the number on it.
  static const jerseys = [
    (Color(0xFF800000), Color(0xFFFFFFFF)),
    (Color(0xFFF07A12), Color(0xFFFFFFFF)),
    (Color(0xFF3554B0), Color(0xFFFFFFFF)),
    (Color(0xFFFFD54A), Color(0xFF3A1C00)),
    (Color(0xFF2FA84F), Color(0xFFFFFFFF)),
    (Color(0xFF7A3FB8), Color(0xFFFFFFFF)),
    (Color(0xFF222222), Color(0xFFFFD54A)),
    (Color(0xFFF2F2F2), Color(0xFF800000)),
  ];

  static const jerseyNames = [
    'Maroon',
    'Flame orange',
    'Blue',
    'Yellow',
    'Green',
    'Purple',
    'Black',
    'White',
  ];
}

/// Draws an [Avatar] as a round badge: a player in their jersey.
class AvatarView extends StatelessWidget {
  const new({required this.avatar, this.size = 64, super.key});

  final Avatar avatar;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label:
        'Avatar: ${avatar.hair.label.toLowerCase()} hair, '
        '${AvatarPalette.jerseyNames[avatar.jersey].toLowerCase()} jersey '
        'number ${avatar.number}',
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: AvatarPainter(avatar)),
    ),
  );
}

class AvatarPainter extends CustomPainter {
  new(this.avatar);

  final Avatar avatar;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    Offset p(double x, double y) => Offset(x * s, y * s);
    Rect oval(double cx, double cy, double rx, double ry) => Rect.fromCenter(
      center: p(cx, cy),
      width: rx * 2 * s,
      height: ry * 2 * s,
    );

    final skin = AvatarPalette.skinTones[avatar.skin];
    final hairColor = AvatarPalette.hairColors[avatar.hairColor];
    final (jersey, numberColor) = AvatarPalette.jerseys[avatar.jersey];
    final paint = Paint()..isAntiAlias = true;

    final badge = Rect.fromLTWH(0, 0, s, s);
    canvas
      ..save()
      ..clipPath(Path()..addOval(badge));

    // Background: a pale tint of the jersey.
    paint.color = Color.lerp(jersey, const Color(0xFFFFFFFF), 0.78)!;
    if (avatar.jersey == 7) paint.color = const Color(0xFFE6E1DC);
    canvas.drawRect(badge, paint);

    // Hair behind the head.
    paint.color = hairColor;
    switch (avatar.hair) {
      case HairStyle.long:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(0.26 * s, 0.24 * s, 0.74 * s, 0.74 * s),
            Radius.circular(0.18 * s),
          ),
          paint,
        );
      case HairStyle.afro:
        canvas.drawCircle(p(0.5, 0.38), 0.29 * s, paint);
      case HairStyle.ponytail:
        canvas
          ..drawOval(oval(0.76, 0.46, 0.08, 0.1), paint)
          ..drawOval(oval(0.79, 0.6, 0.06, 0.08), paint);
      case HairStyle.bun:
        canvas.drawCircle(p(0.5, 0.17), 0.085 * s, paint);
      case HairStyle.none:
      case HairStyle.buzz:
      case HairStyle.short:
      case HairStyle.curly:
        break;
    }

    // Body and jersey.
    final body = Path()
      ..moveTo(0.1 * s, 1.05 * s)
      ..lineTo(0.13 * s, 0.86 * s)
      ..quadraticBezierTo(0.16 * s, 0.72 * s, 0.35 * s, 0.7 * s)
      ..lineTo(0.65 * s, 0.7 * s)
      ..quadraticBezierTo(0.84 * s, 0.72 * s, 0.87 * s, 0.86 * s)
      ..lineTo(0.9 * s, 1.05 * s)
      ..close();
    paint.color = Color.lerp(skin, const Color(0xFF000000), 0.12)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0.43 * s, 0.56 * s, 0.57 * s, 0.75 * s),
        Radius.circular(0.04 * s),
      ),
      paint,
    );
    paint.color = jersey;
    canvas.drawPath(body, paint);

    // Collar.
    final collar = Paint()
      ..color = numberColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.022 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(0.4 * s, 0.705 * s)
        ..lineTo(0.5 * s, 0.79 * s)
        ..lineTo(0.6 * s, 0.705 * s),
      collar,
    );

    // Number.
    final number = TextPainter(
      text: TextSpan(
        text: '${avatar.number}',
        style: TextStyle(
          color: numberColor,
          fontFamily: 'Nunito',
          fontSize: 0.13 * s,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    number.paint(
      canvas,
      p(0.5, 0.905) - Offset(number.width / 2, number.height / 2),
    );
    number.dispose();

    // Ears and head.
    paint.color = skin;
    canvas
      ..drawCircle(p(0.3, 0.47), 0.045 * s, paint)
      ..drawCircle(p(0.7, 0.47), 0.045 * s, paint)
      ..drawOval(oval(0.5, 0.45, 0.2, 0.215), paint);

    // Hair on top of the head.
    paint.color = hairColor;
    void top() {
      canvas
        ..drawOval(oval(0.5, 0.3, 0.215, 0.1), paint)
        ..drawRect(Rect.fromLTRB(0.285 * s, 0.3 * s, 0.33 * s, 0.44 * s), paint)
        ..drawRect(
          Rect.fromLTRB(0.67 * s, 0.3 * s, 0.715 * s, 0.44 * s),
          paint,
        );
    }

    switch (avatar.hair) {
      case HairStyle.none:
        break;
      case HairStyle.buzz:
        paint.color = hairColor.withValues(alpha: 0.85);
        canvas.drawOval(oval(0.5, 0.29, 0.2, 0.075), paint);
      case HairStyle.short:
        top();
        // A side-swept fringe.
        canvas.drawPath(
          Path()
            ..moveTo(0.33 * s, 0.32 * s)
            ..quadraticBezierTo(0.5 * s, 0.33 * s, 0.64 * s, 0.4 * s)
            ..lineTo(0.66 * s, 0.3 * s)
            ..close(),
          paint,
        );
      case HairStyle.curly:
      case HairStyle.afro:
        top();
        for (final (x, y) in const [
          (0.31, 0.37),
          (0.33, 0.28),
          (0.41, 0.22),
          (0.5, 0.2),
          (0.59, 0.22),
          (0.67, 0.28),
          (0.69, 0.37),
        ]) {
          canvas.drawCircle(p(x, y), 0.065 * s, paint);
        }
      case HairStyle.ponytail:
      case HairStyle.bun:
      case HairStyle.long:
        top();
    }

    // Headband across the forehead.
    if (avatar.headband) {
      canvas
        ..save()
        ..clipPath(Path()..addOval(oval(0.5, 0.45, 0.212, 0.23)));
      paint.color = avatar.jersey == 7 ? const Color(0xFF800000) : jersey;
      canvas
        ..drawRect(Rect.fromLTRB(0, 0.335 * s, s, 0.385 * s), paint)
        ..restore();
    }

    // Face.
    paint.color = const Color(0xFF2B1410);
    canvas
      ..drawOval(oval(0.43, 0.475, 0.018, 0.026), paint)
      ..drawOval(oval(0.57, 0.475, 0.018, 0.026), paint)
      ..drawArc(
        oval(0.5, 0.525, 0.06, 0.04),
        0.15 * pi,
        0.7 * pi,
        false,
        Paint()
          ..color = const Color(0xFF2B1410)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.018 * s
          ..strokeCap = StrokeCap.round,
      );
    paint.color = const Color(0x59FF6F6F);
    canvas
      ..drawCircle(p(0.38, 0.54), 0.03 * s, paint)
      ..drawCircle(p(0.62, 0.54), 0.03 * s, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(AvatarPainter oldDelegate) => oldDelegate.avatar != avatar;
}
