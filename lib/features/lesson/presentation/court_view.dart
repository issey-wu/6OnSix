import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';

/// One half of a volleyball court with the net at the top and six tappable
/// zones in FIVB numbering (4-3-2 front, 5-6-1 back). Zone numbers are not
/// drawn, because questions ask the learner to find them.
class CourtView extends StatelessWidget {
  const new({required this.selectedZone, required this.onZoneTap, super.key});

  final int? selectedZone;
  final ValueChanged<int>? onZoneTap;

  static const _frontRow = [4, 3, 2];
  static const _backRow = [5, 6, 1];

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final line = Theme.of(context).colorScheme.onSurface;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CourtPainter(
                floor: tokens.selectedBg,
                line: line,
                selectedFill: tokens.brandOrange,
                selectedZone: selectedZone,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(child: _row(_frontRow)),
              Expanded(flex: 2, child: _row(_backRow)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<int> zones) => Row(
    children: [
      for (final zone in zones)
        Expanded(
          child: Semantics(
            button: true,
            selected: zone == selectedZone,
            label: 'Court zone',
            child: InkWell(
              onTap: onZoneTap == null ? null : () => onZoneTap!(zone),
              child: const SizedBox.expand(),
            ),
          ),
        ),
    ],
  );
}

class _CourtPainter extends CustomPainter {
  new({
    required this.floor,
    required this.line,
    required this.selectedFill,
    required this.selectedZone,
  });

  final Color floor;
  final Color line;
  final Color selectedFill;
  final int? selectedZone;

  static const _zoneCells = {
    4: (0, 0),
    3: (1, 0),
    2: (2, 0),
    5: (0, 1),
    6: (1, 1),
    1: (2, 1),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final attackY = h / 3;
    final court = Offset.zero & size;
    canvas.drawRect(court, Paint()..color = floor);

    final zone = selectedZone;
    if (zone != null) {
      final (col, row) = _zoneCells[zone]!;
      final top = row == 0 ? 0.0 : attackY;
      final bottom = row == 0 ? attackY : h;
      canvas.drawRect(
        Rect.fromLTRB(col * w / 3, top, (col + 1) * w / 3, bottom),
        Paint()..color = selectedFill.withValues(alpha: 0.75),
      );
    }

    final thin = Paint()
      ..color = line.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(i * w / 3, 0), Offset(i * w / 3, h), thin);
    }
    final lines = Paint()
      ..color = line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas
      ..drawRect(court.deflate(1), lines)
      ..drawLine(Offset(0, attackY), Offset(w, attackY), lines)
      ..drawLine(Offset.zero, Offset(w, 0), lines..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(_CourtPainter oldDelegate) =>
      oldDelegate.selectedZone != selectedZone ||
      oldDelegate.floor != floor ||
      oldDelegate.line != line;
}
