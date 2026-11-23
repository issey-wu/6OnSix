import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/ace.dart';

// The first-run guide. A coach mark darkens the whole screen except one
// part, and Ace explains that part in a speech bubble. Tapping the lit-up
// part both closes the mark and uses the part (tap an answer, tap Check),
// so the guide never costs the learner extra taps. "Got it" closes the
// mark; "Skip tutorial" (after a confirmation) turns off every tip.

/// Darkens the screen around [target] and has Ace say [text] beside it.
/// Completes when the learner taps "Got it" or the lit-up part, or with
/// false when they tap "Skip tutorial".
Future<bool> showCoachMark(
  BuildContext context, {
  required GlobalKey target,
  required String text,
  AceMood mood = AceMood.happy,
  AceAction action = AceAction.hop,
  double padding = 6,
  // The ring sits [padding] outside the target, so its corners are the
  // target's (16, the app's usual card and button corner) plus [padding].
  // Matching radii would look pinched at the corners.
  double radius = 16 + 6,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final done = Completer<bool>();
  late final OverlayEntry entry;
  void close({required bool keepGoing}) {
    if (done.isCompleted) return;
    entry.remove();
    done.complete(keepGoing);
  }

  entry = OverlayEntry(
    builder: (context) => _CoachMark(
      target: target,
      text: text,
      mood: mood,
      action: action,
      padding: padding,
      radius: radius,
      onDone: () => close(keepGoing: true),
      onSkip: () => close(keepGoing: false),
    ),
  );
  overlay.insert(entry);
  // If the target goes away (the screen closes), so does the mark.
  return done.future;
}

class _CoachMark extends StatefulWidget {
  const new({
    required this.target,
    required this.text,
    required this.mood,
    required this.action,
    required this.padding,
    required this.radius,
    required this.onDone,
    required this.onSkip,
  });

  final GlobalKey target;
  final String text;
  final AceMood mood;
  final AceAction action;
  final double padding;
  final double radius;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  State<_CoachMark> createState() => _CoachMarkState();
}

class _CoachMarkState extends State<_CoachMark> {
  Rect? _hole;
  bool _shown = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _track();
    // Fade in on the next frame.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  /// Follows the target as it moves (a panel sliding up, a list
  /// scrolling), checking once per frame while frames are being drawn.
  void _track() {
    if (!mounted) return;
    final hole = _measure();
    if (hole == null && _hole != null && !_closing) {
      // The target has gone, such as when the screen closed.
      _closing = true;
      widget.onDone();
      return;
    }
    if (hole != _hole) setState(() => _hole = hole);
    SchedulerBinding.instance.addPostFrameCallback((_) => _track());
  }

  Rect? _measure() {
    final target = widget.target.currentContext?.findRenderObject();
    final overlay = context.findRenderObject();
    if (target is! RenderBox ||
        overlay is! RenderBox ||
        !target.attached ||
        !target.hasSize ||
        !overlay.hasSize) {
      return null;
    }
    final topLeft = target.localToGlobal(Offset.zero, ancestor: overlay);
    return (topLeft & target.size).inflate(widget.padding);
  }

  void _done() {
    if (_closing) return;
    _closing = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final hole = _hole;
    final size = MediaQuery.sizeOf(context);
    final tokens = AppTokens.of(context);
    final padding = MediaQuery.paddingOf(context);
    // Ace and his bubble sit on whichever side of the hole has more room.
    final below = hole == null || hole.center.dy < size.height / 2;
    final card = _GuideCard(
      text: widget.text,
      mood: widget.mood,
      action: widget.action,
      onDone: _done,
    );
    // "Skip tutorial" always sits in a top corner, or in a bottom corner
    // when the lit-up part is at the top, such as the hint button.
    const skipRoom = 56.0;
    final skipAtTop = hole == null || hole.top > padding.top + skipRoom + 8;
    final skip = _SkipButton(
      onSkip: () {
        if (_closing) return;
        _closing = true;
        widget.onSkip();
      },
    );
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: motion(context, const Duration(milliseconds: 220)),
      child: Stack(
        children: [
          Positioned.fill(
            child: _Spotlight(
              hole: hole,
              radius: widget.radius,
              onHoleTap: _done,
              child: CustomPaint(
                painter: _ScrimPainter(
                  hole: hole,
                  radius: widget.radius,
                  ring: tokens.brandYellow,
                ),
              ),
            ),
          ),
          if (hole != null)
            // Centred in the open space beside the hole, clear of the
            // parts around it.
            Positioned(
              left: 12,
              right: 12,
              top: below
                  ? hole.bottom + 12
                  : padding.top + 12 + (skipAtTop ? skipRoom : 0),
              bottom: below
                  ? padding.bottom + 12 + (skipAtTop ? 0 : skipRoom)
                  : size.height - hole.top + 12,
              child: Center(child: SingleChildScrollView(child: card)),
            ),
          Positioned(
            right: 12,
            top: skipAtTop ? padding.top + 10 : null,
            bottom: skipAtTop ? null : padding.bottom + 10,
            child: skip,
          ),
        ],
      ),
    );
  }
}

/// "Skip tutorial", in the same place on every tip.
class _SkipButton extends StatelessWidget {
  const new({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: OutlinedButton.icon(
      key: const ValueKey('tips-skip'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70, width: 2),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: const StadiumBorder(),
      ),
      onPressed: onSkip,
      icon: const Icon(Icons.skip_next_rounded, size: 20),
      label: const Text('Skip tutorial'),
    ),
  );
}

/// Ace, his bubble, and the Got it button.
class _GuideCard extends StatelessWidget {
  const new({
    required this.text,
    required this.mood,
    required this.action,
    required this.onDone,
  });

  final String text;
  final AceMood mood;
  final AceAction action;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AceSays(
          key: ValueKey(text),
          text: text,
          action: action,
          mood: mood,
          aceHeight: 96,
          bubbleWidth: 250,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Spacer(),
            FilledButton(
              key: const ValueKey('tips-ok'),
              style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
              onPressed: onDone,
              child: const Text('Got it'),
            ),
          ],
        ),
      ],
    ),
  );
}

/// The dark layer with a rounded hole, ringed in yellow.
class _ScrimPainter extends CustomPainter {
  const new({required this.hole, required this.radius, required this.ring});

  final Rect? hole;
  final double radius;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final hole = this.hole;
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.7);
    if (hole == null) {
      canvas.drawPath(screen, scrim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole, Radius.circular(radius));
    canvas
      ..drawPath(
        Path.combine(PathOperation.difference, screen, Path()..addRRect(rrect)),
        scrim,
      )
      ..drawRRect(
        rrect,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_ScrimPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.ring != ring;
}

/// Blocks taps everywhere except the hole. A tap in the hole goes through
/// to the part underneath, and also tells the mark it can close.
class _Spotlight extends SingleChildRenderObjectWidget {
  const new({
    required this.hole,
    required this.radius,
    required this.onHoleTap,
    super.child,
  });

  final Rect? hole;
  final double radius;
  final VoidCallback onHoleTap;

  @override
  _RenderSpotlight createRenderObject(BuildContext context) =>
      _RenderSpotlight(hole: hole, radius: radius, onHoleTap: onHoleTap);

  @override
  void updateRenderObject(BuildContext context, _RenderSpotlight renderObject) {
    renderObject
      ..hole = hole
      ..radius = radius
      ..onHoleTap = onHoleTap;
  }
}

class _RenderSpotlight extends RenderProxyBox {
  new({required this.hole, required this.radius, required this.onHoleTap});

  Rect? hole;
  double radius;
  VoidCallback onHoleTap;

  bool _inHole(Offset position) {
    final hole = this.hole;
    return hole != null &&
        RRect.fromRectAndRadius(
          hole,
          Radius.circular(radius),
        ).contains(position);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (_inHole(position)) {
      // Listen in, but let the hit carry on to the screen underneath.
      result.add(BoxHitTestEntry(this, position));
      return false;
    }
    // Everywhere else the dark layer takes the tap and nothing happens.
    super.hitTest(result, position: position);
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerUpEvent && _inHole(entry.localPosition)) {
      // After the tap has reached the part underneath.
      SchedulerBinding.instance.addPostFrameCallback((_) => onHoleTap());
    }
  }
}
