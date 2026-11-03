import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/core/ui/token_chip.dart';

/// A drag-and-drop court question. Drag tokens from the tray onto zones, or
/// tap a token and then a zone (which also works with a screen reader).
/// Tokens can be moved again or dragged back to the tray.
class DragDropView extends StatefulWidget {
  const new({
    required this.question,
    required this.onChanged,
    required this.onSnap,
    this.locked = false,
    this.showAnswer = false,
    super.key,
  });

  final Question question;

  /// Called with the placements as text (such as "S=1|OPP=4") once every
  /// token is placed, or null while any token is still in the tray.
  final ValueChanged<String?> onChanged;

  /// Called when a token lands in a zone.
  final VoidCallback onSnap;

  final bool locked;

  /// Shows the correct arrangement instead of the learner's.
  final bool showAnswer;

  @override
  State<DragDropView> createState() => _DragDropViewState();
}

class _DragDropViewState extends State<DragDropView> {
  final Map<String, int> _placed = {};
  String? _selected;

  List<String> get _tray =>
      widget.question.tokens.where((t) => !_placed.containsKey(t)).toList();

  void _place(String token, int zone) {
    setState(() {
      _placed
        ..removeWhere((t, z) => z == zone && t != token)
        ..[token] = zone;
      _selected = null;
    });
    widget.onSnap();
    _report();
  }

  void _unplace(String token) {
    setState(() {
      _placed.remove(token);
      _selected = null;
    });
    _report();
  }

  void _report() {
    final tokens = widget.question.tokens;
    widget.onChanged(
      tokens.every(_placed.containsKey)
          ? tokens.map((t) => '$t=${_placed[t]}').join('|')
          : null,
    );
  }

  void _tapZone(int zone) {
    final selected = _selected;
    if (selected != null) {
      _place(selected, zone);
      return;
    }
    final here = _placed.entries.where((e) => e.value == zone);
    if (here.isNotEmpty) setState(() => _selected = here.first.key);
  }

  @override
  Widget build(BuildContext context) {
    final placements = widget.showAnswer ? widget.question.placements : _placed;
    final byZone = {for (final e in placements.entries) e.value: e.key};
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showAnswer)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Correct arrangement',
              style: text.labelLarge?.copyWith(color: tokens.textSecondary),
            ),
          ),
        CourtView(
          cellBuilder: (context, zone) => _zoneCell(zone, byZone[zone]),
        ),
        const SizedBox(height: 16),
        if (!widget.showAnswer)
          DragTarget<String>(
            onAcceptWithDetails: widget.locked
                ? null
                : (details) => _unplace(details.data),
            builder: (context, candidates, rejected) => Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: candidates.isNotEmpty
                    ? tokens.selectedBg
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.surfaceMuted, width: 2),
              ),
              child: _tray.isEmpty
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
                      spacing: 12,
                      runSpacing: 12,
                      children: [for (final t in _tray) _draggable(t)],
                    ),
            ),
          ),
      ],
    );
  }

  Widget _zoneCell(int zone, String? token) {
    final place = courtZoneNames[zone]!;
    return DragTarget<String>(
      onAcceptWithDetails: widget.locked
          ? null
          : (details) => _place(details.data, zone),
      builder: (context, candidates, rejected) => Semantics(
        button: !widget.locked,
        label: 'Zone $zone, $place${token == null ? '' : ', $token'}',
        excludeSemantics: true,
        child: InkWell(
          onTap: widget.locked ? null : () => _tapZone(zone),
          child: Container(
            color: candidates.isNotEmpty
                ? AppTokens.of(context).brandOrange.withValues(alpha: 0.35)
                : null,
            alignment: Alignment.center,
            child: token == null
                ? null
                : (widget.locked || widget.showAnswer)
                ? TokenChip(label: token)
                : _draggable(token),
          ),
        ),
      ),
    );
  }

  Widget _draggable(String token) {
    final chip = TokenChip(label: token, selected: _selected == token);
    if (widget.locked) return chip;
    return Semantics(
      button: true,
      selected: _selected == token,
      label: 'Player $token',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => setState(() {
          _selected = _selected == token ? null : token;
        }),
        child: Draggable<String>(
          data: token,
          feedback: Material(
            type: MaterialType.transparency,
            child: Transform.scale(
              scale: 1.15,
              child: TokenChip(label: token, selected: true),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: chip),
          child: chip,
        ),
      ),
    );
  }
}
