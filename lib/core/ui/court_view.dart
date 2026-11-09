import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/player_token.dart';

/// Zones in screen order: front row left to right, then back row.
const courtZoneOrder = [4, 3, 2, 5, 6, 1];

/// Where each zone sits, for screen-reader labels.
const courtZoneNames = {
  4: 'front left',
  3: 'front middle',
  2: 'front right',
  5: 'back left',
  6: 'back middle',
  1: 'back right',
};

/// One half of a volleyball court with the net at the top and six zones in
/// FIVB numbering (4-3-2 front, 5-6-1 back). Zone numbers are not drawn,
/// because questions ask the learner to find them.
///
/// [tokens] draws player tokens in zones. [cellBuilder] replaces the default
/// tappable cell, for example with a drop target for drag-and-drop.
class CourtView extends StatelessWidget {
  const new({
    this.selectedZone,
    this.onZoneTap,
    this.tokens = const {},
    this.cellBuilder,
    this.revealZoneNumbers = false,
    this.hintZones = const {},
    super.key,
  });

  final int? selectedZone;
  final ValueChanged<int>? onZoneTap;

  /// Zone to token label.
  final Map<int, String> tokens;
  final Widget Function(BuildContext context, int zone)? cellBuilder;

  /// Whether screen-reader labels include the zone number. Off for tap the
  /// zone questions, where the number is the answer.
  final bool revealZoneNumbers;

  /// Zones lightly highlighted by a hint, such as the whole front row.
  final Set<int> hintZones;

  @override
  Widget build(BuildContext context) {
    final tokensTheme = AppTokens.of(context);
    final line = Theme.of(context).colorScheme.onSurface;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CourtPainter(
                floor: tokensTheme.selectedBg,
                line: line,
                selectedFill: tokensTheme.brandOrange,
                selectedZone: selectedZone,
                hintFill: tokensTheme.brandYellow,
                hintZones: hintZones,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(child: _row(context, courtZoneOrder.sublist(0, 3))),
              Expanded(
                flex: 2,
                child: _row(context, courtZoneOrder.sublist(3)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, List<int> zones) => Row(
    children: [
      for (final zone in zones)
        Expanded(child: cellBuilder?.call(context, zone) ?? _defaultCell(zone)),
    ],
  );

  Widget _defaultCell(int zone) {
    final token = tokens[zone];
    final place = courtZoneNames[zone]!;
    final label = revealZoneNumbers ? 'Zone $zone, $place' : _capital(place);
    return Semantics(
      button: onZoneTap != null,
      selected: zone == selectedZone,
      label: token == null ? label : '$label, $token',
      child: InkWell(
        onTap: onZoneTap == null ? null : () => onZoneTap!(zone),
        child: Center(child: token == null ? null : PlayerToken(label: token)),
      ),
    );
  }
}

String _capital(String s) => s[0].toUpperCase() + s.substring(1);

class _CourtPainter extends CustomPainter {
  new({
    required this.floor,
    required this.line,
    required this.selectedFill,
    required this.selectedZone,
    required this.hintFill,
    required this.hintZones,
  });

  final Color floor;
  final Color line;
  final Color selectedFill;
  final int? selectedZone;
  final Color hintFill;
  final Set<int> hintZones;

  Rect _zoneRect(int zone, Size size) {
    final index = courtZoneOrder.indexOf(zone);
    final col = index % 3;
    final front = index < 3;
    final attackY = size.height / 3;
    return Rect.fromLTRB(
      col * size.width / 3,
      front ? 0 : attackY,
      (col + 1) * size.width / 3,
      front ? attackY : size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final attackY = h / 3;
    final court = Offset.zero & size;
    canvas.drawRect(court, Paint()..color = floor);

    for (final hinted in hintZones) {
      canvas.drawRect(
        _zoneRect(hinted, size),
        Paint()..color = hintFill.withValues(alpha: 0.45),
      );
    }
    final zone = selectedZone;
    if (zone != null) {
      canvas.drawRect(
        _zoneRect(zone, size),
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
      oldDelegate.hintZones.length != hintZones.length ||
      !oldDelegate.hintZones.containsAll(hintZones) ||
      oldDelegate.floor != floor ||
      oldDelegate.line != line;
}
