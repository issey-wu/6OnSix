import 'dart:math';

import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/core/ui/player_token.dart';

/// A drag-and-drop court question: the court with a tray of player tokens
/// below it.
///
/// - Drag a token onto a zone, or tap a token and then a zone.
/// - Dropping on a taken zone swaps the two players. With a player picked,
///   tapping a player on the court swaps them too.
/// - Drag a token back to the tray, or pick it and tap the tray, to take it
///   off the court.
///
/// Screen readers get the same moves through the zones and the tray.
/// Interaction design by Yash Dubey (yash/screens).
class DragDropView extends StatefulWidget {
  const new({
    required this.question,
    required this.onChanged,
    required this.onSnap,
    this.locked = false,
    this.hint = false,
    this.random,
    super.key,
  });

  final Question question;

  /// Called with the placements as text (such as "S=1|OPP=4", in token
  /// order) once every token is placed, or null while any token is still in
  /// the tray.
  final ValueChanged<String?> onChanged;

  /// Called when a token lands in a zone.
  final VoidCallback onSnap;

  /// True after Check: tokens stay where they are but can't be moved.
  final bool locked;

  /// Set to true by the hint button: one player not yet in the right zone
  /// is placed there and fixed.
  final bool hint;

  /// Shuffles the tray. Pass a seeded one for repeatable tests.
  final Random? random;

  @override
  State<DragDropView> createState() => _DragDropViewState();
}

class _DragDropViewState extends State<DragDropView> {
  late final List<String> _trayOrder;
  final Map<String, int> _placed = {};
  final Set<String> _fixed = {};
  String? _picked;

  @override
  void initState() {
    super.initState();
    _trayOrder = [...widget.question.tokens]..shuffle(widget.random);
  }

  @override
  void didUpdateWidget(DragDropView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hint && !oldWidget.hint) {
      // After this frame, so the parent can safely rebuild when it hears
      // about the new placement.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyHint();
      });
    }
  }

  void _applyHint() {
    final placements = widget.question.placements;
    final token = widget.question.tokens
        .where((t) => _placed[t] != placements[t])
        .firstOrNull;
    if (token == null) return;
    _fixed.add(token);
    _place(token, placements[token]!, force: true);
  }

  String? _occupant(int zone) {
    for (final MapEntry(key: token, value: z) in _placed.entries) {
      if (z == zone) return token;
    }
    return null;
  }

  void _place(String token, int zone, {bool force = false}) {
    if (widget.locked) return;
    if (_fixed.contains(token) && !force) return;
    final from = _placed[token];
    final occupant = _occupant(zone);
    if (occupant != null && occupant != token && _fixed.contains(occupant)) {
      return;
    }
    setState(() {
      if (occupant != null && occupant != token) {
        // The player already there swaps to where the new one came from,
        // or back to the tray.
        if (from == null) {
          _placed.remove(occupant);
        } else {
          _placed[occupant] = from;
        }
      }
      _placed[token] = zone;
      _picked = null;
    });
    widget.onSnap();
    _report();
  }

  void _unplace(String token) {
    if (widget.locked || _fixed.contains(token)) return;
    if (!_placed.containsKey(token)) return;
    setState(() {
      _placed.remove(token);
      _picked = null;
    });
    _report();
  }

  void _pick(String token) {
    if (widget.locked || _fixed.contains(token)) return;
    final picked = _picked;
    final zone = _placed[token];
    if (picked != null && picked != token && zone != null) {
      _place(picked, zone);
      return;
    }
    setState(() => _picked = picked == token ? null : token);
  }

  void _tapZone(int zone) {
    final picked = _picked;
    if (picked != null) {
      _place(picked, zone);
    } else if (_occupant(zone) case final token?) {
      _pick(token);
    }
  }

  void _report() {
    final tokens = widget.question.tokens;
    widget.onChanged(
      tokens.every(_placed.containsKey)
          ? tokens.map((t) => '$t=${_placed[t]}').join('|')
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tray = [
      for (final t in _trayOrder)
        if (!_placed.containsKey(t)) t,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CourtView(cellBuilder: (context, zone) => _zone(zone, _occupant(zone))),
        const SizedBox(height: 16),
        _tray(tray),
      ],
    );
  }

  Widget _zone(int zone, String? token) {
    final tokens = AppTokens.of(context);
    final place = courtZoneNames[zone]!;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !widget.locked,
      onAcceptWithDetails: (details) => _place(details.data, zone),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        return Semantics(
          container: true,
          button: !widget.locked,
          label:
              'Zone $zone, $place, '
              '${token == null ? 'empty' : playerRoleName(token)}',
          onTap: widget.locked ? null : () => _tapZone(zone),
          excludeSemantics: true,
          child: InkWell(
            key: ValueKey('zone-$zone'),
            onTap: widget.locked ? null : () => _tapZone(zone),
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

  Widget _tray(List<String> tray) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !widget.locked,
      onAcceptWithDetails: (details) => _unplace(details.data),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        final picked = _picked;
        final unplace = picked == null || !_placed.containsKey(picked)
            ? null
            : () => _unplace(picked);
        return Semantics(
          container: true,
          label: 'Player tray',
          onTap: unplace,
          child: InkWell(
            key: const ValueKey('tray'),
            borderRadius: BorderRadius.circular(16),
            onTap: unplace,
            child: Container(
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
                        style: text.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                        ),
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
    if (widget.locked || _fixed.contains(token)) return chip;
    return Semantics(
      container: true,
      button: true,
      selected: _picked == token,
      label: playerRoleName(token),
      onTap: () => _pick(token),
      excludeSemantics: true,
      child: Draggable<String>(
        key: ValueKey('token-$token'),
        data: token,
        onDragStarted: () => setState(() => _picked = null),
        feedback: Material(
          type: MaterialType.transparency,
          child: PlayerToken(label: token, lifted: true),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: chip),
        child: GestureDetector(onTap: () => _pick(token), child: chip),
      ),
    );
  }
}
