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

/// A simple standing person, [height] tall, with their feet at [feet].
void paintStickFigure(
  Canvas canvas,
  Offset feet,
  double height,
  Color color, {
  bool armUp = false,
}) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = height * 0.07
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final head = height * 0.11;
  final hip = feet - Offset(0, height * 0.45);
  final neck = feet - Offset(0, height * 0.78);
  canvas
    ..drawCircle(neck - Offset(0, head), head, Paint()..color = color)
    ..drawLine(neck, hip, paint)
    ..drawLine(hip, feet + Offset(-height * 0.14, 0), paint)
    ..drawLine(hip, feet + Offset(height * 0.14, 0), paint)
    ..drawLine(
      neck + Offset(0, height * 0.06),
      neck + Offset(-height * 0.2, height * 0.22),
      paint,
    )
    ..drawLine(
      neck + Offset(0, height * 0.06),
      armUp
          ? neck + Offset(height * 0.16, -height * 0.18)
          : neck + Offset(height * 0.2, height * 0.22),
      paint,
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
