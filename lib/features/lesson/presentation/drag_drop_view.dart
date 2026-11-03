import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/features/lesson/presentation/court_view.dart';

/// FIVB zone layout with the net at the top.
const _frontRow = [4, 3, 2];
const _backRow = [5, 6, 1];

const _zoneNames = {
  1: 'back right',
  2: 'front right',
  3: 'front middle',
  4: 'front left',
  5: 'back left',
  6: 'back middle',
};

const _tokenNames = {
  'S': 'Setter',
  'OH1': 'Outside hitter 1',
  'OH2': 'Outside hitter 2',
  'MB1': 'Middle blocker 1',
  'MB2': 'Middle blocker 2',
  'OPP': 'Opposite',
  'L': 'Libero',
};

String _tokenName(String token) => _tokenNames[token] ?? token;

/// A drag-and-drop rotation question: the court with a tray of player
/// tokens below it. Drag a token onto a zone, or tap a token and then a
/// zone. Dropping on a taken zone swaps the two players. Drag a token back
/// to the tray to take it off the court.
///
/// Calls [onChanged] with the placement in [Question.encodePlacements] form
/// once every token is on the court, and with null while any token is still
/// in the tray. Grading is exact placement, done by the lesson screen.
class DragDropView extends StatefulWidget {
  const new({
    required this.question,
    required this.onChanged,
    this.locked = false,
    this.haptics = true,
    super.key,
  });

  final Question question;
  final ValueChanged<String?> onChanged;

  /// True after Check: tokens stay where they are but can't be moved.
  final bool locked;

  /// Whether a token snapping into a zone gives a light haptic tap.
  final bool haptics;

  @override
  State<DragDropView> createState() => _DragDropViewState();
}

class _DragDropViewState extends State<DragDropView> {
  late final List<String> _trayOrder;
  final Map<String, int> _placed = {};
  String? _picked;

  @override
  void initState() {
    super.initState();
    _trayOrder = widget.question.placements.keys.toList()..shuffle(Random());
  }

  void _place(String token, int zone) {
    if (widget.locked) return;
    final from = _placed[token];
    String? occupant;
    for (final entry in _placed.entries) {
      if (entry.value == zone && entry.key != token) occupant = entry.key;
    }
    setState(() {
      if (occupant != null) {
        if (from == null) {
          _placed.remove(occupant);
        } else {
          _placed[occupant] = from;
        }
      }
      _placed[token] = zone;
      _picked = null;
    });
    if (widget.haptics) unawaited(HapticFeedback.selectionClick());
    _report();
  }

  void _unplace(String token) {
    if (widget.locked || !_placed.containsKey(token)) return;
    setState(() {
      _placed.remove(token);
      _picked = null;
    });
    _report();
  }

  void _pick(String token) {
    if (widget.locked) return;
    final picked = _picked;
    final zone = _placed[token];
    // With a player already picked, tapping a player on the court means
    // "put mine here", so the two swap.
    if (picked != null && picked != token && zone != null) {
      _place(picked, zone);
      return;
    }
    setState(() => _picked = picked == token ? null : token);
  }

  void _report() {
    final complete = _placed.length == widget.question.placements.length;
    widget.onChanged(complete ? Question.encodePlacements(_placed) : null);
  }

  @override
  Widget build(BuildContext context) {
    final byZone = {for (final e in _placed.entries) e.value: e.key};
    final tray = [
      for (final t in _trayOrder)
        if (!_placed.containsKey(t)) t,
    ];
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              const Positioned.fill(
                child: ExcludeSemantics(
                  child: CourtView(selectedZone: null, onZoneTap: null),
                ),
              ),
              Column(
                children: [
                  Expanded(child: _row(_frontRow, byZone)),
                  Expanded(flex: 2, child: _row(_backRow, byZone)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _tray(context, tray),
      ],
    );
  }

  Widget _row(List<int> zones, Map<int, String> byZone) => Row(
    children: [
      for (final zone in zones) Expanded(child: _zone(zone, byZone[zone])),
    ],
  );

  Widget _zone(int zone, String? token) {
    final tokens = AppTokens.of(context);
    final picked = _picked;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !widget.locked,
      onAcceptWithDetails: (details) => _place(details.data, zone),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        return Semantics(
          button: !widget.locked,
          label:
              'Zone $zone, ${_zoneNames[zone]}, '
              '${token == null ? 'empty' : _tokenName(token)}',
          child: InkWell(
            key: ValueKey('zone-$zone'),
            onTap: widget.locked || picked == null
                ? null
                : () => _place(picked, zone),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hovering
                    ? tokens.brandOrange.withValues(alpha: 0.35)
                    : null,
                border: hovering
                    ? Border.all(color: tokens.brandOrange, width: 3)
                    : null,
              ),
              child: token == null ? null : _token(token),
            ),
          ),
        );
      },
    );
  }

  Widget _tray(BuildContext context, List<String> tray) {
    final tokens = AppTokens.of(context);
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !widget.locked,
      onAcceptWithDetails: (details) => _unplace(details.data),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        final picked = _picked;
        return Semantics(
          label: 'Player tray',
          child: InkWell(
            key: const ValueKey('tray'),
            borderRadius: BorderRadius.circular(16),
            onTap: picked == null ? null : () => _unplace(picked),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 76),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hovering ? tokens.selectedBg : null,
                border: Border.all(
                  color: hovering ? tokens.brandOrange : tokens.surfaceMuted,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: tray.isEmpty
                  ? Center(
                      child: Text(
                        'All players placed',
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                    )
                  : Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [for (final t in tray) _token(t)],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _token(String token) {
    final chip = PlayerToken(label: token, selected: _picked == token);
    if (widget.locked) return chip;
    return Draggable<String>(
      key: ValueKey('token-$token'),
      data: token,
      onDragStarted: () => setState(() => _picked = null),
      feedback: Material(
        type: MaterialType.transparency,
        child: PlayerToken(label: token, lifted: true),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: GestureDetector(onTap: () => _pick(token), child: chip),
    );
  }
}

/// A round player token with a short role label, such as "OH1".
class PlayerToken extends StatelessWidget {
  const new({
    required this.label,
    this.selected = false,
    this.lifted = false,
    this.size = 48,
    super.key,
  });

  final String label;
  final bool selected;
  final bool lifted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final libero = label == 'L';
    return Semantics(
      label: '${_tokenName(label)}${selected ? ', selected' : ''}',
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // The libero wears a contrasting jersey, so its token does too.
            color: libero ? scheme.onSurface : tokens.brandOrange,
            border: selected
                ? Border.all(color: AppTheme.buttonRed, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: lifted ? 0.3 : 0.12),
                blurRadius: lifted ? 12 : 2,
                offset: Offset(0, lifted ? 6 : 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: size * 0.27,
              fontWeight: FontWeight.w800,
              color: libero ? scheme.surface : tokens.onYellowOrange,
            ),
          ),
        ),
      ),
    );
  }
}

/// A court showing players already in place. Used to show the correct
/// arrangement after a wrong drag-and-drop answer.
class CourtLineup extends StatelessWidget {
  const new({required this.placements, this.tokenSize = 34, super.key});

  final Map<String, int> placements;
  final double tokenSize;

  @override
  Widget build(BuildContext context) {
    final byZone = {for (final e in placements.entries) e.value: e.key};
    final description = [
      for (final zone in [..._frontRow, ..._backRow])
        if (byZone[zone] != null) '${_tokenName(byZone[zone]!)} in zone $zone',
    ].join(', ');
    Widget row(List<int> zones) => Row(
      children: [
        for (final zone in zones)
          Expanded(
            child: Center(
              child: byZone[zone] == null
                  ? null
                  : PlayerToken(label: byZone[zone]!, size: tokenSize),
            ),
          ),
      ],
    );
    return Semantics(
      label: 'Correct arrangement: $description',
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              const Positioned.fill(
                child: CourtView(selectedZone: null, onZoneTap: null),
              ),
              Column(
                children: [
                  Expanded(child: row(_frontRow)),
                  Expanded(flex: 2, child: row(_backRow)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
