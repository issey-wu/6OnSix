import 'dart:math';

import 'package:flutter/material.dart';

// Drawing helpers shared by the teaching diagrams: labels, arrowheads and
// dimension lines in the style of a technical drawing, so a size is always
// clearly tied to the two edges it measures.

/// Draws [text] centred on [centre], turned by [angle] radians.
void paintLabel(
  Canvas canvas,
  String text,
  Offset centre,
  TextStyle style, {
  double angle = 0,
  Color? background,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  canvas
    ..save()
    ..translate(centre.dx, centre.dy)
    ..rotate(angle);
  if (background != null) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: painter.width + 8,
          height: painter.height + 2,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = background,
    );
  }
  painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  canvas.restore();
  painter.dispose();
}

/// The size [label] would take up, for leaving a gap around it.
Size labelSize(String label, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}

/// A filled arrowhead at [tip], pointing along [angle].
void paintArrowhead(
  Canvas canvas,
  Offset tip,
  double angle,
  Paint paint, {
  double length = 7,
}) {
  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(
      tip.dx - length * cos(angle - 0.4),
      tip.dy - length * sin(angle - 0.4),
    )
    ..lineTo(
      tip.dx - length * cos(angle + 0.4),
      tip.dy - length * sin(angle + 0.4),
    )
    ..close();
  canvas.drawPath(path, Paint()..color = paint.color);
}

/// A dimension measuring from [a] to [b] (two points on the drawing's
/// edges), drawn [offset] away from them: thin extension lines out from
/// each point, a line between them with an arrowhead at each end, and
/// [label] in a gap in the middle of that line.
void paintDimension(
  Canvas canvas, {
  required Offset a,
  required Offset b,
  required Offset offset,
  required String label,
  required TextStyle style,
  required Color color,
}) {
  final thin = Paint()
    ..color = color
    ..strokeWidth = 1.2;
  final direction = offset / offset.distance;
  // Extension lines start just clear of the drawing and run a little past
  // the dimension line.
  for (final point in [a, b]) {
    canvas.drawLine(
      point + direction * 3,
      point + offset + direction * 4,
      thin,
    );
  }
  final start = a + offset;
  final end = b + offset;
  final angle = atan2(end.dy - start.dy, end.dx - start.dx);
  final along = (end - start) / (end - start).distance;
  final size = labelSize(label, style);
  final vertical = (end.dx - start.dx).abs() < (end.dy - start.dy).abs();
  final gap = size.width / 2 + 4;
  final mid = (start + end) / 2;
  final length = (end - start).distance;
  if (length > gap * 2 + 8) {
    canvas
      ..drawLine(start, mid - along * gap, thin)
      ..drawLine(mid + along * gap, end, thin);
  }
  paintArrowhead(canvas, end, angle, thin);
  paintArrowhead(canvas, start, angle + pi, thin);
  paintLabel(
    canvas,
    label,
    mid,
    style.copyWith(color: color),
    angle: vertical ? -pi / 2 : 0,
  );
}

/// A Material icon drawn at [centre], such as a tick or a cross.
void paintIcon(
  Canvas canvas,
  IconData icon,
  Offset centre,
  double size,
  Color color,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: size,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, centre - Offset(painter.width / 2, painter.height / 2));
  painter.dispose();
}

/// [text] with a tick (when [ok]) or a cross in front of it, centred on
/// [centre].
void paintVerdict(
  Canvas canvas,
  String text,
  Offset centre,
  TextStyle style, {
  required bool ok,
}) {
  final size = labelSize(text, style);
  final icon = (style.fontSize ?? 14) + 4;
  final width = size.width + icon + 3;
  final left = centre.dx - width / 2;
  paintIcon(
    canvas,
    ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
    Offset(left + icon / 2, centre.dy),
    icon,
    style.color ?? Colors.black,
  );
  paintLabel(
    canvas,
    text,
    Offset(left + icon + 3 + size.width / 2, centre.dy),
    style,
  );
}

// The soft court style shared by every court diagram: rounded corners,
// lines a little lighter than the text, the net as a rounded red band and
// highlights as rounded tiles, so the diagrams match the rest of the app.

/// Corner radius of a court's back corners.
const courtCorner = 12.0;

/// Half a court seen from above, with the net along the top of [court].
/// [attackY] draws the attack line there, in [attackColor] when given.
/// [netOverhang] lets the net run a little past the sidelines.
void paintSoftHalfCourt(
  Canvas canvas,
  Rect court, {
  required Color floor,
  required Color line,
  required Color net,
  double? attackY,
  Color? attackColor,
  double attackWidth = 2,
  double netOverhang = 8,
  double corner = courtCorner,
}) {
  final shape = RRect.fromRectAndCorners(
    court,
    bottomLeft: Radius.circular(corner),
    bottomRight: Radius.circular(corner),
  );
  canvas
    ..drawRRect(shape, Paint()..color = floor)
    ..drawRRect(
      shape.deflate(1),
      Paint()
        ..color = line.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  if (attackY != null) {
    canvas.drawLine(
      Offset(court.left + 1, attackY),
      Offset(court.right - 1, attackY),
      Paint()
        ..color = attackColor ?? line.withValues(alpha: 0.7)
        ..strokeWidth = attackWidth
        ..strokeCap = StrokeCap.round,
    );
  }
  paintNetBand(
    canvas,
    Offset(court.left - netOverhang, court.top),
    Offset(court.right + netOverhang, court.top),
    net,
  );
}

/// The net seen from above: a rounded band from [from] to [to].
void paintNetBand(
  Canvas canvas,
  Offset from,
  Offset to,
  Color colour, {
  double thickness = 7,
}) => canvas.drawRRect(
  RRect.fromLTRBR(
    min(from.dx, to.dx),
    from.dy - thickness / 2,
    max(from.dx, to.dx),
    from.dy + thickness / 2,
    Radius.circular(thickness / 2),
  ),
  Paint()..color = colour,
);

/// A zone lit up as a rounded tile, set in a little from [cell]'s edges.
void paintSoftCell(Canvas canvas, Rect cell, Color colour) => canvas.drawRRect(
  RRect.fromRectAndRadius(cell.deflate(5), const Radius.circular(10)),
  Paint()..color = colour,
);

/// A volleyball of [radius] at [centre]: a white ball with three seams and
/// a soft shadow.
void paintVolleyball(Canvas canvas, Offset centre, double radius, Color line) {
  final outline = Paint()
    ..color = line.withValues(alpha: 0.8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.2, radius * 0.11);
  canvas
    ..drawCircle(
      centre + Offset(radius * 0.1, radius * 0.15),
      radius,
      Paint()..color = line.withValues(alpha: 0.12),
    )
    ..drawCircle(centre, radius, Paint()..color = Colors.white)
    ..drawCircle(centre, radius, outline);
  outline.strokeWidth = max(1, radius * 0.085);
  for (var i = 0; i < 3; i++) {
    final angle = -pi / 2 + i * 2 * pi / 3;
    final edge = centre + Offset(cos(angle), sin(angle)) * radius;
    final bend =
        centre + Offset(cos(angle + 0.9), sin(angle + 0.9)) * radius * 0.55;
    canvas.drawPath(
      Path()
        ..moveTo(centre.dx, centre.dy)
        ..quadraticBezierTo(bend.dx, bend.dy, edge.dx, edge.dy),
      outline,
    );
  }
}

/// A tick or a cross in a small white circle, at [centre].
void paintBadge(
  Canvas canvas,
  Offset centre, {
  required bool ok,
  required Color colour,
  double size = 18,
}) {
  canvas.drawCircle(centre, size * 0.44, Paint()..color = Colors.white);
  paintIcon(
    canvas,
    ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
    centre,
    size,
    colour,
  );
}

/// A player seen from behind, about to serve overhand: the ball tossed up
/// in one hand and the hitting arm drawn back. [height] runs from the feet
/// to the top of the head; the ball sits above that. Drawn with chunky,
/// rounded proportions and curved limbs, like the app's characters:
/// [body] for the head and limbs, [jersey] and [shorts] for the kit.
void paintServer(
  Canvas canvas,
  Offset feet,
  double height, {
  required Color body,
  required Color jersey,
  required Color shorts,
  required Color line,
}) {
  final h = height;
  Offset at(double x, double y) => feet + Offset(x * h, -y * h);
  final limb = Paint()
    ..color = body
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  // A limb that bends smoothly through [joint] rather than at a point.
  Path curve(Offset from, Offset joint, Offset to) => Path()
    ..moveTo(from.dx, from.dy)
    ..quadraticBezierTo(joint.dx, joint.dy, to.dx, to.dy);
  final fill = Paint()..color = body;

  // A soft shadow on the floor.
  canvas.drawOval(
    Rect.fromCenter(center: feet, width: h * 0.55, height: h * 0.09),
    Paint()..color = line.withValues(alpha: 0.12),
  );

  // Legs, one knee a little bent as if about to step in, with round feet.
  limb.strokeWidth = h * 0.12;
  canvas
    ..drawPath(curve(at(-0.07, 0.32), at(-0.11, 0.17), at(-0.1, 0.04)), limb)
    ..drawPath(curve(at(0.07, 0.32), at(0.14, 0.18), at(0.1, 0.04)), limb)
    ..drawOval(
      Rect.fromCenter(
        center: at(-0.11, 0.025),
        width: h * 0.15,
        height: h * 0.08,
      ),
      fill,
    )
    ..drawOval(
      Rect.fromCenter(
        center: at(0.11, 0.025),
        width: h * 0.15,
        height: h * 0.08,
      ),
      fill,
    );

  // Arms, behind the jersey: the tossing arm reaching up, the hitting arm
  // drawn back with the elbow out and the hand by the head.
  limb.strokeWidth = h * 0.095;
  final tossHand = at(-0.19, 0.97);
  final hitHand = at(0.25, 0.88);
  canvas
    ..drawPath(curve(at(-0.13, 0.62), at(-0.22, 0.78), tossHand), limb)
    ..drawPath(curve(at(0.13, 0.62), at(0.34, 0.68), hitHand), limb)
    ..drawCircle(tossHand, h * 0.06, fill)
    ..drawCircle(hitHand, h * 0.06, fill);

  // Shorts, then the jersey over them: rounded, a little wider at the
  // shoulders.
  final top = at(0, 0.67);
  final bottom = at(0, 0.37);
  final r = h * 0.07;
  final torso = Path()
    ..moveTo(top.dx - h * 0.17 + r, top.dy)
    ..lineTo(top.dx + h * 0.17 - r, top.dy)
    ..quadraticBezierTo(
      top.dx + h * 0.17,
      top.dy,
      top.dx + h * 0.17,
      top.dy + r,
    )
    ..lineTo(bottom.dx + h * 0.14, bottom.dy - r)
    ..quadraticBezierTo(
      bottom.dx + h * 0.14,
      bottom.dy,
      bottom.dx + h * 0.14 - r,
      bottom.dy,
    )
    ..lineTo(bottom.dx - h * 0.14 + r, bottom.dy)
    ..quadraticBezierTo(
      bottom.dx - h * 0.14,
      bottom.dy,
      bottom.dx - h * 0.14,
      bottom.dy - r,
    )
    ..lineTo(top.dx - h * 0.17, top.dy + r)
    ..quadraticBezierTo(
      top.dx - h * 0.17,
      top.dy,
      top.dx - h * 0.17 + r,
      top.dy,
    )
    ..close();
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(at(-0.15, 0.42), at(0.15, 0.27)),
        Radius.circular(h * 0.05),
      ),
      Paint()..color = shorts,
    )
    ..drawPath(torso, Paint()..color = jersey)
    // The head, seen from behind: big and round.
    ..drawCircle(at(0, 0.8), h * 0.135, fill);

  // The ball, just above the tossing hand.
  paintVolleyball(canvas, at(-0.19, 1.1), h * 0.1, line);
}
