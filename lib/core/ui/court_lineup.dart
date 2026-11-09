import 'package:flutter/material.dart';
import 'package:six_on_six/core/ui/court_view.dart';
import 'package:six_on_six/core/ui/player_token.dart';

/// A small court with players already in place. Shows the correct
/// arrangement after a wrong drag-and-drop answer.
///
/// Design by Yash Dubey (yash/screens).
class CourtLineup extends StatelessWidget {
  const new({required this.placements, this.tokenSize = 34, super.key});

  /// Token to zone, such as {'S': 1, 'OPP': 4}.
  final Map<String, int> placements;
  final double tokenSize;

  @override
  Widget build(BuildContext context) {
    final byZone = {for (final e in placements.entries) e.value: e.key};
    final description = [
      for (final zone in courtZoneOrder)
        if (byZone[zone] case final token?)
          '${playerRoleName(token)} in zone $zone',
    ].join(', ');
    return Semantics(
      label: 'Correct arrangement: $description',
      excludeSemantics: true,
      child: CourtView(
        cellBuilder: (context, zone) => Center(
          child: switch (byZone[zone]) {
            final token? => PlayerToken(label: token, size: tokenSize),
            null => null,
          },
        ),
      ),
    );
  }
}

/// The correct arrangement, with players popping into place one at a time
/// in [order]. Change [runId] to play it again. Shows everyone at once when
/// the device asks for reduced motion.
class AnimatedLineup extends StatefulWidget {
  const new({
    required this.placements,
    required this.order,
    this.runId = 0,
    this.tokenSize = 40,
    super.key,
  });

  /// Token to zone, such as {'S': 1, 'OPP': 4}.
  final Map<String, int> placements;

  /// The order players appear in.
  final List<String> order;
  final int runId;
  final double tokenSize;

  @override
  State<AnimatedLineup> createState() => _AnimatedLineupState();
}

class _AnimatedLineupState extends State<AnimatedLineup>
    with SingleTickerProviderStateMixin {
  static const _perPlayer = Duration(milliseconds: 550);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _perPlayer * widget.order.length,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _run();
  }

  @override
  void didUpdateWidget(AnimatedLineup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.runId != oldWidget.runId) _run();
  }

  void _run() {
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

  @override
  Widget build(BuildContext context) {
    final byZone = {for (final e in widget.placements.entries) e.value: e.key};
    final description = [
      for (final token in widget.order)
        if (widget.placements[token] case final zone?)
          '${playerRoleName(token)} in zone $zone',
    ].join(', ');
    return Semantics(
      label: 'Correct arrangement: $description',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CourtView(
          cellBuilder: (context, zone) {
            final token = byZone[zone];
            if (token == null) return const SizedBox.shrink();
            final step = widget.order.indexOf(token);
            final t = (_controller.value * widget.order.length - step).clamp(
              0.0,
              1.0,
            );
            return Center(
              child: Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: Curves.easeOutBack.transform(t),
                  child: PlayerToken(label: token, size: widget.tokenSize),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
