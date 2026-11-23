import 'dart:math';

import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/core/ui/diagram_paint.dart';

// Diagrams for the rules: the net and its antennae, the centre line, a
// back-row attack and the serve. Each keeps to the few labels the card
// needs, in the app's colours.

/// The colours and text style every rule diagram draws with.
class _Ink {
  new(BuildContext context)
    : tokens = AppTokens.of(context),
      line = Theme.of(context).colorScheme.onSurface,
      surface = Theme.of(context).colorScheme.surface,
      dark = Theme.of(context).brightness == Brightness.dark,
      label = Theme.of(context).textTheme.labelLarge!
          .copyWith(fontWeight: FontWeight.w900),
      small = Theme.of(context).textTheme.labelMedium!
          .copyWith(fontWeight: FontWeight.w800);

  final AppTokens tokens;
  final Color line;
  final Color surface;

  /// True in the dark theme, where the deep brand red needs lifting to
  /// stand out.
  final bool dark;
  final TextStyle label;
  final TextStyle small;
}

Widget _picture(
  BuildContext context, {
  required String description,
  required double aspectRatio,
  required CustomPainter painter,
}) => Semantics(
  image: true,
  label: description,
  excludeSemantics: true,
  child: AspectRatio(
    aspectRatio: aspectRatio,
    child: CustomPaint(painter: painter),
  ),
);

/// The net from the side of the court: the antennae at each sideline, the
/// space between them where the ball must cross, and the net itself.
class NetDiagram extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _picture(
    context,
    description:
        'The net seen from the side. An antenna stands at each end of the '
        'net. The ball must cross above the net, between the two antennae. '
        'Touching the net while playing the ball is a fault.',
    aspectRatio: 1.25,
    painter: _NetPainter(_Ink(context)),
  );
}

class _NetPainter extends CustomPainter {
  new(this.ink);

  final _Ink ink;

  @override
  void paint(Canvas canvas, Size size) {
    final t = ink.tokens;
    final w = size.width;
    final h = size.height;
    final floorTop = h - 20;
    final left = w * 0.2;
    final right = w * 0.8;
    final netTop = h * 0.52;
    final netBottom = h * 0.72;
    final antennaTop = h * 0.32;
    final round = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // The floor: a soft strip of court. Above the net, where the ball may
    // cross: between the antennae and on up past them, so the space fades
    // out rather than stopping at a hard edge.
    final space = Rect.fromLTRB(left, 4, right, netTop - 4);
    canvas
      ..drawRRect(
        RRect.fromLTRBR(4, floorTop, w - 4, h - 4, const Radius.circular(8)),
        Paint()..color = t.brandOrange.withValues(alpha: 0.16),
      )
      ..drawRect(
        space,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              t.success.withValues(alpha: 0.24),
              t.success.withValues(alpha: 0.02),
            ],
          ).createShader(space),
      );
    // Outside the antennae the ball is out: the same fade, in red. It also
    // fades towards the outer edge and just above the net, so it has no
    // hard corners.
    for (final (side, outerLeft) in [
      (Rect.fromLTRB(0, 4, left, netTop - 2), true),
      (Rect.fromLTRB(right, 4, w, netTop - 2), false),
    ]) {
      canvas
        ..saveLayer(side, Paint())
        ..drawRect(
          side,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                t.error.withValues(alpha: 0),
                t.error.withValues(alpha: 0.16),
                t.error.withValues(alpha: 0),
              ],
              stops: const [0, 0.3, 1],
            ).createShader(side),
        )
        ..drawRect(
          side,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = LinearGradient(
              begin: outerLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: outerLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: const [Colors.transparent, Colors.black],
              stops: const [0, 0.7],
            ).createShader(side),
        )
        ..restore();
    }
    final dashed = Paint()
      ..color = t.success.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final x in [left, right]) {
      for (var y = antennaTop - 8; y > 8; y -= 9) {
        canvas.drawLine(Offset(x, y), Offset(x, max(y - 4, 6)), dashed);
      }
    }
    paintLabel(
      canvas,
      'ball crosses here',
      Offset(w / 2, h * 0.13),
      ink.label.copyWith(color: t.success),
    );

    // Posts, with rounded ends and a small foot each.
    for (final x in [left - 16, right + 16]) {
      canvas
        ..drawLine(
          Offset(x, floorTop + 4),
          Offset(x, netTop - 6),
          round
            ..color = ink.line.withValues(alpha: 0.75)
            ..strokeWidth = 7,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, floorTop + 5),
              width: 22,
              height: 7,
            ),
            const Radius.circular(4),
          ),
          Paint()..color = ink.line.withValues(alpha: 0.75),
        );
    }

    // The net: a light diamond mesh, a cord along the bottom, cables out
    // to the posts and a band along the top.
    final net = Rect.fromLTRB(left, netTop, right, netBottom);
    final mesh = Paint()
      ..color = ink.line.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    canvas
      ..save()
      ..clipRect(net);
    final height = net.height;
    for (var x = net.left - height; x <= net.right; x += 10) {
      canvas
        ..drawLine(Offset(x, net.top), Offset(x + height, net.bottom), mesh)
        ..drawLine(Offset(x + height, net.top), Offset(x, net.bottom), mesh);
    }
    canvas.restore();
    final cord = Paint()
      ..color = ink.line.withValues(alpha: 0.55)
      ..strokeWidth = 1.5;
    canvas
      ..drawLine(Offset(left, netBottom), Offset(right, netBottom), cord)
      ..drawLine(Offset(left - 16, netTop), Offset(left, netTop), cord)
      ..drawLine(Offset(right, netTop), Offset(right + 16, netTop), cord)
      ..drawLine(Offset(left - 16, netBottom), Offset(left, netBottom), cord)
      ..drawLine(Offset(right, netBottom), Offset(right + 16, netBottom), cord)
      ..drawRRect(
        RRect.fromLTRBR(
          left,
          netTop - 4,
          right,
          netTop + 5,
          const Radius.circular(4),
        ),
        Paint()..color = t.brandRed,
      );

    // The antennae: rounded red and white rods at each end of the net.
    for (final x in [left, right]) {
      canvas
        ..drawLine(
          Offset(x, antennaTop),
          Offset(x, netBottom),
          round
            ..color = ink.line.withValues(alpha: 0.45)
            ..strokeWidth = 7.5,
        )
        ..drawLine(
          Offset(x, antennaTop),
          Offset(x, netBottom),
          round
            ..color = Colors.white
            ..strokeWidth = 5,
        );
      const stripes = 7;
      final step = (netBottom - antennaTop) / stripes;
      for (var i = 0; i < stripes; i += 2) {
        canvas.drawLine(
          Offset(x, antennaTop + i * step),
          Offset(x, antennaTop + (i + 1) * step),
          round
            ..color = t.error
            ..strokeWidth = 5,
        );
      }
    }

    // One ball crossing in the space, and one going round the outside.
    final inBall = Offset(w * 0.4, h * 0.33);
    paintVolleyball(canvas, inBall, 14, ink.line);
    paintBadge(
      canvas,
      inBall + const Offset(13, -12),
      ok: true,
      colour: t.success,
    );
    final outBall = Offset((right + w) / 2 + 4, h * 0.3);
    paintVolleyball(canvas, outBall, 14, ink.line);
    paintBadge(
      canvas,
      outBall + const Offset(13, -12),
      ok: false,
      colour: t.error,
    );
    paintLabel(
      canvas,
      'out',
      outBall + const Offset(0, 27),
      ink.small.copyWith(color: t.error),
    );

    // Point out one antenna and the net.
    final leader = Paint()
      ..color = ink.line.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    final antennaNote = Offset(left / 2 + 2, antennaTop - 6);
    canvas.drawLine(
      antennaNote + const Offset(10, 8),
      Offset(left - 4, antennaTop + 8),
      leader,
    );
    paintLabel(
      canvas,
      'antenna',
      antennaNote,
      ink.small.copyWith(color: ink.line),
    );
    final netNote = Offset(w / 2, netBottom + (floorTop - netBottom) * 0.5);
    canvas.drawLine(
      netNote - const Offset(0, 9),
      Offset(w / 2, netBottom - 6),
      leader,
    );
    paintLabel(
      canvas,
      'net: no touching while playing',
      netNote,
      ink.small.copyWith(color: ink.line),
    );
  }

  @override
  bool shouldRepaint(_NetPainter oldDelegate) => false;
}

/// The centre line under the net, seen from above, with one foot that is
/// allowed (part of it still on the line) and one that is a fault (all of
/// it over).
class CentreLineDiagram extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _picture(
    context,
    description:
        'The centre line under the net, seen from above. A foot that '
        'crosses the line but still has part of it on the line is allowed. '
        'A foot that is completely over the line is a fault.',
    aspectRatio: 1.3,
    painter: _CentrePainter(_Ink(context)),
  );
}

class _CentrePainter extends CustomPainter {
  new(this.ink);

  final _Ink ink;

  /// A shoe seen from above, toe pointing up, [length] long: wider at the
  /// toe than the heel.
  Path _shoe(Offset heel, double length) {
    final w = length * 0.42;
    final toe = heel - Offset(0, length);
    return Path()
      ..moveTo(heel.dx - w * 0.32, heel.dy - w * 0.25)
      ..quadraticBezierTo(
        heel.dx,
        heel.dy + w * 0.12,
        heel.dx + w * 0.32,
        heel.dy - w * 0.25,
      )
      ..quadraticBezierTo(
        heel.dx + w * 0.55,
        toe.dy + length * 0.45,
        heel.dx + w * 0.5,
        toe.dy + w * 0.5,
      )
      ..quadraticBezierTo(heel.dx + w * 0.45, toe.dy, toe.dx, toe.dy)
      ..quadraticBezierTo(
        heel.dx - w * 0.5,
        toe.dy,
        heel.dx - w * 0.5,
        toe.dy + w * 0.5,
      )
      ..quadraticBezierTo(
        heel.dx - w * 0.5,
        toe.dy + length * 0.45,
        heel.dx - w * 0.32,
        heel.dy - w * 0.25,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = ink.tokens;
    final w = size.width;
    final h = size.height;
    final lineY = h * 0.5;

    // The two sides of the floor, each fading away from the line, inside
    // one rounded shape.
    final area = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final theirs = Rect.fromLTRB(0, 0, w, lineY);
    final yours = Rect.fromLTRB(0, lineY, w, h);
    canvas
      ..save()
      ..clipRRect(area)
      ..drawRect(
        theirs,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              t.surfaceMuted.withValues(alpha: 0.8),
              t.surfaceMuted.withValues(alpha: 0.15),
            ],
          ).createShader(theirs),
      )
      ..drawRect(
        yours,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.selectedBg, t.selectedBg.withValues(alpha: 0.25)],
          ).createShader(yours),
      )
      ..restore();
    paintLabel(
      canvas,
      'Their side',
      Offset(w / 2, 16),
      ink.small.copyWith(color: t.textSecondary),
    );
    paintLabel(
      canvas,
      'Your side',
      Offset(w / 2, h - 16),
      ink.small.copyWith(color: t.textSecondary),
    );

    // The net's shadow just above the centre line, then the line itself.
    final dash = Paint()
      ..color = t.brandRed.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var x = 14.0; x < w - 14; x += 12) {
      canvas.drawLine(Offset(x, lineY - 10), Offset(x + 5, lineY - 10), dash);
    }
    canvas.drawLine(
      Offset(10, lineY),
      Offset(w - 10, lineY),
      Paint()
        ..color = ink.line.withValues(alpha: 0.8)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    paintLabel(
      canvas,
      'centre line (net above)',
      Offset(w / 2, lineY + 19),
      ink.small.copyWith(color: ink.line),
    );

    // Allowed: the heel still on the line. A fault: all of it over.
    final foot = h * 0.3;
    final ok = Offset(w * 0.27, lineY + 5);
    final bad = Offset(w * 0.73, lineY - 9);
    for (final (heel, colour, allowed, caption) in [
      (ok, t.success, true, 'allowed'),
      (bad, t.error, false, 'fault'),
    ]) {
      final shape = _shoe(heel, foot);
      canvas
        ..drawPath(
          shape.shift(const Offset(1.5, 2.5)),
          Paint()..color = ink.line.withValues(alpha: 0.1),
        )
        ..drawPath(
          shape,
          Paint()..color = Color.lerp(colour, Colors.white, 0.6)!,
        )
        ..drawPath(
          shape,
          Paint()
            ..color = colour
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeJoin = StrokeJoin.round,
        );
      paintVerdict(
        canvas,
        caption,
        Offset(heel.dx, heel.dy - foot - 13),
        ink.label.copyWith(color: colour),
        ok: allowed,
      );
    }
  }

  @override
  bool shouldRepaint(_CentrePainter oldDelegate) => false;
}

/// Half a court with the attack line: a back-row player may attack only by
/// jumping from behind it.
class BackRowAttackDiagram extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _picture(
    context,
    description:
        'Half a court with the net at the top and the attack line 3 m from '
        'it. A back-row player jumps to attack from behind the attack line, '
        'which is allowed. Jumping from in front of it is not.',
    aspectRatio: 1,
    painter: _BackRowPainter(_Ink(context)),
  );
}

class _BackRowPainter extends CustomPainter {
  new(this.ink);

  final _Ink ink;

  @override
  void paint(Canvas canvas, Size size) {
    final t = ink.tokens;
    final court = Rect.fromLTWH(16, 24, size.width - 32, size.height - 30);
    final attackY = court.top + court.height / 3;
    paintSoftHalfCourt(
      canvas,
      court,
      floor: t.selectedBg,
      line: ink.line,
      net: t.brandRed,
    );
    paintSoftCell(
      canvas,
      Rect.fromLTRB(court.left, attackY, court.right, court.bottom),
      t.brandYellow.withValues(alpha: 0.3),
    );
    canvas.drawLine(
      Offset(court.left + 1, attackY),
      Offset(court.right - 1, attackY),
      Paint()
        ..color = t.brandOrange
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    paintNetBand(
      canvas,
      Offset(court.left - 8, court.top),
      Offset(court.right + 8, court.top),
      t.brandRed,
    );
    paintLabel(
      canvas,
      'NET',
      Offset(court.center.dx, court.top - 14),
      ink.label.copyWith(color: t.brandRed, letterSpacing: 2),
    );
    paintLabel(
      canvas,
      'attack line',
      Offset(court.left + 44, attackY - 12),
      ink.small.copyWith(color: t.brandOrange),
    );
    paintLabel(
      canvas,
      'back row',
      Offset(court.right - 42, court.bottom - 16),
      ink.small.copyWith(color: t.textSecondary),
    );

    // Allowed: take off behind the line. Drawn like the player tokens on
    // the other court diagrams, with a soft shadow.
    final good = Offset(court.left + court.width * 0.36, attackY + 36);
    final bad = Offset(court.left + court.width * 0.72, attackY - 38);
    const r = 18.0;
    canvas
      ..drawCircle(
        good + const Offset(0, 2),
        r,
        Paint()..color = ink.line.withValues(alpha: 0.15),
      )
      ..drawCircle(good, r, Paint()..color = t.brandOrange);
    paintLabel(
      canvas,
      'OH',
      good,
      ink.small.copyWith(color: t.onYellowOrange, fontWeight: FontWeight.w900),
    );
    final arrow = Paint()
      ..color = t.success
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final from = good - const Offset(0, r + 5);
    final to = Offset(good.dx, attackY + 8);
    canvas.drawLine(from, to, arrow);
    paintArrowhead(canvas, to - const Offset(0, 2), -pi / 2, arrow);
    paintVerdict(
      canvas,
      'jump from here',
      good + const Offset(0, r + 15),
      ink.small.copyWith(color: t.success),
      ok: true,
    );

    // Not allowed: take off in front of it.
    final dashed = Paint()
      ..color = t.error
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(bad, r, Paint()..color = t.error.withValues(alpha: 0.08));
    for (var a = 0.0; a < 2 * pi; a += pi / 6) {
      canvas.drawArc(
        Rect.fromCircle(center: bad, radius: r),
        a,
        pi / 12,
        false,
        dashed,
      );
    }
    paintVerdict(
      canvas,
      'not from here',
      bad + const Offset(0, r + 13),
      ink.small.copyWith(color: t.error),
      ok: false,
    );
  }

  @override
  bool shouldRepaint(_BackRowPainter oldDelegate) => false;
}

/// Half a court with zone 1 lit up, the end line labelled, and the server
/// standing behind it in the service zone.
class ServeDiagram extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _picture(
    context,
    description:
        'Half a court with the net at the top and zone 1, the right back, '
        'highlighted. The server stands behind the end line, in the service '
        'zone, without touching the line.',
    aspectRatio: 0.72,
    painter: _ServePainter(_Ink(context)),
  );
}

class _ServePainter extends CustomPainter {
  new(this.ink);

  final _Ink ink;

  @override
  void paint(Canvas canvas, Size size) {
    final t = ink.tokens;
    final side = size.width - 32;
    final court = Rect.fromLTWH(16, 24, side, side);
    final attackY = court.top + side / 3;
    paintSoftHalfCourt(
      canvas,
      court,
      floor: t.selectedBg,
      line: ink.line,
      net: t.brandRed,
      attackY: attackY,
      corner: 8,
    );

    // Zone numbers, with zone 1 lit up.
    for (final (i, zone) in courtZoneOrder.indexed) {
      final col = i % 3;
      final front = i < 3;
      final cell = Rect.fromLTRB(
        court.left + col * side / 3,
        front ? court.top : attackY,
        court.left + (col + 1) * side / 3,
        front ? attackY : court.bottom,
      );
      if (zone == 1) {
        paintSoftCell(canvas, cell, t.brandYellow.withValues(alpha: 0.6));
      }
      paintLabel(
        canvas,
        '$zone',
        cell.center,
        ink.label.copyWith(
          fontSize: 22,
          color: zone == 1 ? t.brandRed : t.textSecondary,
        ),
      );
    }
    paintLabel(
      canvas,
      'NET',
      Offset(court.center.dx, court.top - 14),
      ink.label.copyWith(color: t.brandRed, letterSpacing: 2),
    );

    // The end line, drawn heavier, with the service zone behind it.
    final service = Rect.fromLTRB(
      court.left,
      court.bottom + 8,
      court.right,
      size.height - 2,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(service, const Radius.circular(12)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              t.surfaceMuted.withValues(alpha: 0.7),
              t.surfaceMuted.withValues(alpha: 0.1),
            ],
          ).createShader(service),
      )
      ..drawLine(
        Offset(court.left + 2, court.bottom - 1),
        Offset(court.right - 2, court.bottom - 1),
        Paint()
          ..color = t.brandOrange
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    paintLabel(
      canvas,
      'end line',
      Offset(court.left + side * 0.18, court.bottom + 20),
      ink.small.copyWith(color: t.brandOrange),
    );

    // The server, behind zone 1 and clear of the line.
    // Drawn in the team's colours, like the player tokens, rather than as
    // a dark silhouette.
    final kit = ink.dark ? Color.lerp(t.brandRed, t.error, 0.55)! : t.brandRed;
    final figure = service.height * 0.62;
    final feet = Offset(court.left + side * 5 / 6, service.bottom - 10);
    paintServer(
      canvas,
      feet,
      figure,
      body: kit,
      jersey: t.brandOrange,
      shorts: kit,
      line: ink.line,
    );
    paintLabel(
      canvas,
      'server',
      Offset(feet.dx - figure * 0.66, feet.dy - figure * 0.55),
      ink.small.copyWith(color: kit),
    );
  }

  @override
  bool shouldRepaint(_ServePainter oldDelegate) => false;
}
