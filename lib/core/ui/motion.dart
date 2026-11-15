import 'dart:math';

import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';

// Small animation helpers shared across screens. Every one of them shows
// its final state at once when the phone's Reduce Motion setting is on,
// and none of them loops while Reduce Motion is on, so widget tests (which
// turn it on) settle.

bool _reduced(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Fades and rises [child] into place, after waiting [delay].
class PopIn extends StatelessWidget {
  const new({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 360),
    this.offset = 18,
    this.scale = false,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// How far below its place the child starts, in logical pixels.
  final double offset;

  /// Also grows the child from small to full size, with a little overshoot.
  final bool scale;

  @override
  Widget build(BuildContext context) {
    if (_reduced(context)) return child;
    final total = delay + duration;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutBack),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: scale
              ? Transform.scale(scale: 0.6 + 0.4 * t, child: child)
              : child,
        ),
      ),
      child: child,
    );
  }
}

/// Gently floats [child] up and down, to draw the eye to it.
class Bob extends StatefulWidget {
  const new({required this.child, this.height = 5, super.key});

  final Widget child;
  final double height;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !_reduced(context) && TickerMode.valuesOf(context).enabled;
    if (animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!animate && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        -widget.height * Curves.easeInOut.transform(_controller.value),
      ),
      child: child,
    ),
    child: widget.child,
  );
}

/// Rocks [child] side to side every couple of seconds, like a chest that
/// wants to be opened.
class Wiggle extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !_reduced(context) && TickerMode.valuesOf(context).enabled;
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      // A quick shake in the first quarter, then rest.
      final t = _controller.value;
      final angle = t < 0.25 ? sin(t / 0.25 * pi * 4) * 0.12 : 0.0;
      return Transform.rotate(angle: angle, child: child);
    },
    child: widget.child,
  );
}

/// Counts up from zero to [value], such as the XP earned.
class CountUpText extends StatelessWidget {
  const new({
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    super.key,
  });

  final int value;
  final String prefix;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
    tween: IntTween(begin: _reduced(context) ? value : 0, end: value),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder: (context, n, _) => Text('$prefix$n$suffix', style: style),
  );
}

/// A one-off burst of confetti in the brand colours, drawn behind the
/// lesson complete screen. Nothing is drawn with Reduce Motion on.
class ConfettiBurst extends StatefulWidget {
  const new({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  final List<_Piece> _pieces = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pieces.isNotEmpty || _reduced(context)) return;
    final tokens = AppTokens.of(context);
    final colors = [
      tokens.brandOrange,
      tokens.brandYellow,
      tokens.choice,
      tokens.brandRed,
      tokens.success,
    ];
    final random = Random(6);
    for (var i = 0; i < 70; i++) {
      final angle = -pi / 2 + (random.nextDouble() - 0.5) * pi * 0.9;
      final speed = 0.55 + random.nextDouble() * 0.6;
      _pieces.add(
        _Piece(
          dx: cos(angle) * speed,
          dy: sin(angle) * speed,
          spin: (random.nextDouble() - 0.5) * 14,
          size: 6 + random.nextDouble() * 6,
          color: colors[i % colors.length],
          round: i.isEven,
        ),
      );
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pieces.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_controller, _pieces),
      ),
    );
  }
}

class _Piece {
  const new({
    required this.dx,
    required this.dy,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  final double dx;
  final double dy;
  final double spin;
  final double size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  new(this.animation, this.pieces) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t == 0 || t == 1) return;
    final origin = Offset(size.width / 2, size.height * 0.32);
    final scale = size.shortestSide;
    final paint = Paint();
    for (final p in pieces) {
      // Thrown outwards, then pulled down by gravity.
      final x = origin.dx + p.dx * scale * t;
      final y = origin.dy + p.dy * scale * t + 0.9 * scale * t * t;
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}

/// Fades a tab's screen in, rising slightly, whenever [index] changes.
/// Keeps the same child, so each tab keeps its scroll position and state.
class TabFade extends StatefulWidget {
  const new({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  State<TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<TabFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(TabFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index && !_reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = _curved;
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
