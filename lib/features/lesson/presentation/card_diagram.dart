import 'dart:math';

import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/core/ui/diagram_paint.dart';
import 'package:six_on_six/core/ui/player_token.dart';
import 'package:six_on_six/features/lesson/presentation/rule_diagrams.dart';

/// A 5-1 starting lineup: the setter across from the opposite, the outside
/// hitters across from each other, and the middles across from each other.
const _lineup = {1: 'S', 2: 'OH1', 3: 'MB1', 4: 'OPP', 5: 'OH2', 6: 'MB2'};

/// The same lineup with the libero in for the back-row middle blocker.
const _liberoLineup = {1: 'S', 2: 'OH1', 3: 'MB1', 4: 'OPP', 5: 'OH2', 6: 'L'};

/// Draws the picture for a teaching card, from a spec such as `court:net`
/// or `zones:1` (see `cardDiagrams` in the course model). Unknown specs draw
/// nothing, so an older app never breaks on newer content.
class CardDiagram extends StatelessWidget {
  const new({required this.spec, super.key});

  final String spec;

  @override
  Widget build(BuildContext context) {
    final [kind, ...rest] = spec.split(':');
    final detail = rest.join(':');
    final picture = switch (kind) {
      'court' => _FullCourt(highlight: detail),
      'zones' => _NumberedZones(highlight: _zonesFor(detail)),
      'roles' => _Lineup(
        tokens: _lineup,
        highlight: {
          for (final MapEntry(key: zone, value: token) in _lineup.entries)
            if (token == detail) zone,
        },
      ),
      'net' => const NetDiagram(),
      'centre' => const CentreLineDiagram(),
      'backrow' => const BackRowAttackDiagram(),
      'serve' => const ServeDiagram(),
      'libero' => const _Lineup(tokens: _liberoLineup, highlight: {6}),
      'rotation' when detail == 'play' => const _RotationPlay(),
      'rotation' => const _Rotation(),
      _ => const SizedBox.shrink(),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: picture,
      ),
    );
  }

  static Set<int> _zonesFor(String detail) => switch (detail) {
    'front' => const {4, 3, 2},
    'back' => const {5, 6, 1},
    _ => {?int.tryParse(detail)},
  };
}

/// "NET" above a half court, so the learner always knows which way is up.
class _NetLabel extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      'NET',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppTokens.of(context).brandRed,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    ),
  );
}

/// The big zone number drawn in a cell.
class _ZoneNumber extends StatelessWidget {
  const new({required this.zone, required this.lit});

  final int zone;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Center(
      child: Text(
        '$zone',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: lit ? tokens.brandRed : tokens.textSecondary,
        ),
      ),
    );
  }
}

class _NumberedZones extends StatelessWidget {
  const new({this.highlight = const {}});

  final Set<int> highlight;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: highlight.isEmpty
        ? 'Half court with zones 4, 3, 2 in the front row and 5, 6, 1 in the '
              'back row'
        : 'Half court with zone${highlight.length > 1 ? 's' : ''} '
              '${highlight.join(', ')} highlighted',
    excludeSemantics: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _NetLabel(),
        CourtView(
          hintZones: highlight,
          cellBuilder: (context, zone) => _ZoneNumber(
            zone: zone,
            lit: highlight.isEmpty || highlight.contains(zone),
          ),
        ),
      ],
    ),
  );
}

class _Lineup extends StatelessWidget {
  const new({required this.tokens, this.highlight = const {}});

  final Map<int, String> tokens;
  final Set<int> highlight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = AppTokens.of(context).textSecondary;
    final places = [
      for (final z in courtZoneOrder) 'zone $z ${playerRoleName(tokens[z]!)}',
    ];
    return Semantics(
      image: true,
      label: 'Starting lineup: ${places.join(', ')}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _NetLabel(),
          CourtView(
            hintZones: highlight,
            cellBuilder: (context, zone) => Stack(
              children: [
                Positioned(
                  left: 6,
                  top: 4,
                  child: Text(
                    '$zone',
                    style: text.labelLarge?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Center(child: PlayerToken(label: tokens[zone]!, size: 44)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final label in {...tokens.values}.map(_short).toSet())
                Text(
                  '$label = ${_roleWord(label)}',
                  style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// OH1 and OH2 are both outside hitters, so the key lists OH once.
  static String _short(String label) => label.replaceAll(RegExp(r'\d'), '');

  static String _roleWord(String short) => switch (short) {
    'S' => 'Setter',
    'OH' => 'Outside hitter',
    'MB' => 'Middle blocker',
    'OPP' => 'Opposite',
    'L' => 'Libero',
    _ => short,
  };
}

class _Rotation extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Semantics(
      image: true,
      label: 'Rotation: zone 2 to 1, 1 to 6, 6 to 5, 5 to 4, 4 to 3 and 3 to 2',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _NetLabel(),
          Stack(
            children: [
              CourtView(
                cellBuilder: (context, zone) =>
                    _ZoneNumber(zone: zone, lit: true),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ArrowsPainter(color: tokens.brandOrange),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Where each zone moves when a team rotates: one zone clockwise.
const _clockwise = {1: 6, 6: 5, 5: 4, 4: 3, 3: 2, 2: 1};

/// The lineup sliding one zone clockwise, the setter moving from zone 1 to
/// zone 6, with a button to play it again. With Reduce Motion on, it shows
/// where everyone ends up.
class _RotationPlay extends StatefulWidget {
  const new();

  @override
  State<_RotationPlay> createState() => _RotationPlayState();
}

class _RotationPlayState extends State<_RotationPlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play();
  }

  void _play() {
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _centre(int zone, Size size) {
    final index = courtZoneOrder.indexOf(zone);
    return Offset(
      (index % 3 + 0.5) * size.width / 3,
      index < 3 ? size.height / 6 : size.height * 2 / 3,
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label:
        'Zones numbered 1 to 6, with zone 1 highlighted. The lineup rotates '
        'one zone clockwise: the setter moves from zone 1 to zone 6 and the '
        'player in zone 2 moves to zone 1 to serve',
    excludeSemantics: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _NetLabel(),
        Stack(
          children: [
            // Zone numbers in the corners, and zone 1 lit up: whoever
            // moves into it serves next.
            CourtView(
              hintZones: const {1},
              cellBuilder: (context, zone) => Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 4),
                  child: Text(
                    '$zone',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: zone == 1
                          ? AppTokens.of(context).brandRed
                          : AppTokens.of(context).textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, box) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = Curves.easeInOutCubic.transform(
                      // Hold still briefly, then move.
                      ((_controller.value - 0.15) / 0.85).clamp(0.0, 1.0),
                    );
                    const size = 40.0;
                    return Stack(
                      children: [
                        for (final MapEntry(key: zone, value: token)
                            in _lineup.entries)
                          Positioned(
                            left:
                                Offset.lerp(
                                  _centre(zone, box.biggest),
                                  _centre(_clockwise[zone]!, box.biggest),
                                  t,
                                )!.dx -
                                size / 2,
                            top:
                                Offset.lerp(
                                  _centre(zone, box.biggest),
                                  _centre(_clockwise[zone]!, box.biggest),
                                  t,
                                )!.dy -
                                size / 2,
                            child: PlayerToken(label: token, size: size),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Zone 1 serves',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTokens.of(context).brandRed,
            fontWeight: FontWeight.w900,
          ),
        ),
        TextButton.icon(
          onPressed: _play,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Play again'),
        ),
      ],
    ),
  );
}

/// Clockwise arrows between zone centres: 2 to 1, 1 to 6, 6 to 5, 5 to 4,
/// 4 to 3 and 3 to 2.
class _ArrowsPainter extends CustomPainter {
  new({required this.color});

  final Color color;

  Offset _centre(int zone, Size size) {
    final index = courtZoneOrder.indexOf(zone);
    final col = index % 3;
    final front = index < 3;
    return Offset(
      (col + 0.5) * size.width / 3,
      front ? size.height / 6 : size.height * 2 / 3,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const steps = [(2, 1), (1, 6), (6, 5), (5, 4), (4, 3), (3, 2)];
    for (final (from, to) in steps) {
      final a = _centre(from, size);
      final b = _centre(to, size);
      // Leave room around the numbers at each end.
      final start = Offset.lerp(a, b, 0.32)!;
      final end = Offset.lerp(a, b, 0.68)!;
      canvas.drawLine(start, end, paint);
      final angle = atan2(end.dy - start.dy, end.dx - start.dx);
      const head = 12.0;
      canvas
        ..drawLine(
          end,
          end - Offset(cos(angle - 0.5), sin(angle - 0.5)) * head,
          paint,
        )
        ..drawLine(
          end,
          end - Offset(cos(angle + 0.5), sin(angle + 0.5)) * head,
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_ArrowsPainter oldDelegate) => oldDelegate.color != color;
}

/// A whole court from above (net across the middle), measured like a
/// technical drawing: each size sits on a dimension line outside the court,
/// with arrows to the two edges it measures. [highlight] is `net`, `attack`
/// or `half`.
class _FullCourt extends StatelessWidget {
  const new({this.highlight = ''});

  final String highlight;

  @override
  Widget build(BuildContext context) {
    final label = switch (highlight) {
      'net' =>
        'Full court, 18 m long and 9 m wide. The net across the middle '
            'splits it into two halves, each 9 m by 9 m',
      'attack' =>
        'Full court with an attack line 3 m from the net on each side',
      'half' => 'Full court with one 9 m by 9 m half shaded',
      _ => 'Full volleyball court, 18 m long and 9 m wide',
    };
    final tokens = AppTokens.of(context);
    final style = Theme.of(context).textTheme.labelLarge!
        .copyWith(fontWeight: FontWeight.w900);
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 0.8,
        child: CustomPaint(
          painter: _FullCourtPainter(
            highlight: highlight,
            floor: tokens.selectedBg,
            line: Theme.of(context).colorScheme.onSurface,
            accent: tokens.brandOrange,
            net: tokens.brandRed,
            style: style,
            muted: tokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FullCourtPainter extends CustomPainter {
  new({
    required this.highlight,
    required this.floor,
    required this.line,
    required this.accent,
    required this.net,
    required this.style,
    required this.muted,
  });

  final String highlight;
  final Color floor;
  final Color line;
  final Color accent;
  final Color net;
  final TextStyle style;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    // The court is 9 wide and 18 long. Room on the left for the length,
    // above for the width, and on the right for the halves and the net.
    const left = 44.0;
    const right = 92.0;
    const top = 34.0;
    const bottom = 8.0;
    final courtWidth = min(
      size.width - left - right,
      (size.height - top - bottom) / 2,
    );
    final courtHeight = courtWidth * 2;
    final x0 = left + (size.width - left - right - courtWidth) / 2;
    final court = Rect.fromLTWH(x0, top, courtWidth, courtHeight);
    final midY = court.center.dy;
    final metre = courtHeight / 18;

    final shape = RRect.fromRectAndRadius(
      court,
      const Radius.circular(courtCorner),
    );
    canvas.drawRRect(shape, Paint()..color = floor);
    if (highlight == 'half') {
      paintSoftCell(
        canvas,
        Rect.fromLTRB(court.left, midY, court.right, court.bottom),
        accent.withValues(alpha: 0.25),
      );
    }
    canvas.drawRRect(
      shape.deflate(1),
      Paint()
        ..color = line.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Attack lines, 3 m either side of the net.
    final attack = Paint()
      ..color = highlight == 'attack' ? accent : line.withValues(alpha: 0.7)
      ..strokeWidth = highlight == 'attack' ? 4 : 2
      ..strokeCap = StrokeCap.round;
    for (final y in [midY - 3 * metre, midY + 3 * metre]) {
      canvas.drawLine(
        Offset(court.left + 1, y),
        Offset(court.right - 1, y),
        attack,
      );
    }

    // The net, a little wider than the court so it reads as a net.
    final netColour = highlight == 'net' ? accent : net;
    paintNetBand(
      canvas,
      Offset(court.left - 8, midY),
      Offset(court.right + 8, midY),
      netColour,
      thickness: highlight == 'net' ? 9 : 7,
    );

    // Dimensions: the width above, the length on the left.
    paintDimension(
      canvas,
      a: court.topLeft,
      b: court.topRight,
      offset: const Offset(0, -18),
      label: '9 m',
      style: style,
      color: muted,
    );
    paintDimension(
      canvas,
      a: court.bottomLeft,
      b: court.topLeft,
      offset: const Offset(-22, 0),
      label: '18 m',
      style: style,
      color: muted,
    );

    // On the right: each half, or each attack zone, measured from the net.
    const rightOffset = Offset(22, 0);
    switch (highlight) {
      case 'net' || 'half':
        for (final (from, to) in [
          (court.topRight, Offset(court.right, midY)),
          (Offset(court.right, midY), court.bottomRight),
        ]) {
          paintDimension(
            canvas,
            a: from,
            b: to,
            offset: rightOffset,
            label: '9 m',
            style: style,
            color: accent,
          );
        }
      case 'attack':
        for (final (from, to) in [
          (Offset(court.right, midY - 3 * metre), Offset(court.right, midY)),
          (Offset(court.right, midY), Offset(court.right, midY + 3 * metre)),
        ]) {
          paintDimension(
            canvas,
            a: from,
            b: to,
            offset: rightOffset,
            label: '3 m',
            style: style,
            color: accent,
          );
        }
        paintLabel(
          canvas,
          'attack line',
          Offset(court.center.dx, midY + 3 * metre + 11),
          style.copyWith(color: accent, fontSize: (style.fontSize ?? 14) - 2),
          background: floor,
        );
    }
    paintLabel(
      canvas,
      'NET',
      Offset(court.right + 66, midY),
      style.copyWith(color: netColour),
    );
  }

  @override
  bool shouldRepaint(_FullCourtPainter oldDelegate) =>
      oldDelegate.highlight != highlight ||
      oldDelegate.floor != floor ||
      oldDelegate.line != line;
}
