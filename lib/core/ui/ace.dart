import 'dart:math';

import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/motion.dart';

// Ace, the 6 On Six eagle, drawn by Yash Dubey. The artwork comes in
// separate parts (three wing shapes, body, head, eyes, brows and two
// beaks), so each part can move on its own: Ace blinks, breathes, glances
// around, talks, waves, cheers, shrugs and droops. His happy eyes, wink,
// blush and tear are drawn on top in colours taken from the artwork.
//
// With Reduce Motion on, Ace holds still in the pose that fits the moment,
// and nothing loops, so widget tests settle.

/// A one-off move Ace makes when he appears, or when [Ace.actionKey]
/// changes.
enum AceAction {
  /// Just stands there, blinking and glancing around.
  none,

  /// Raises a wing and waves hello.
  wave,

  /// Two big jumps with both wings up, laughing.
  cheer,

  /// Pumps a fist and winks.
  fistPump,

  /// One small happy hop.
  hop,

  /// Wings out, head tilted: "oops".
  shrug,

  /// A sigh: he sinks a little, his wings droop and a tear rolls.
  sad,
}

/// Ace's face between moves.
enum AceMood {
  /// Open eyes and a smile.
  happy,

  /// Smiling eyes, a grin and rosy cheeks.
  joyful,

  /// A wink, one brow up and a grin.
  cheeky,

  /// Big eyes and raised brows.
  surprised,

  /// Worried brows, droopy eyes and a tear.
  sad,
}

/// The parts, placed in the artwork's own coordinates. The body is drawn
/// in a [_bodyWidth] wide area, with room either side for the wings; the
/// whole drawing is [_width] by [_height] units.
const _bodyWidth = 600.0;
const _margin = 70.0;
const double _width = _bodyWidth + 2 * _margin;
const _height = 960.0;
const _dir = 'assets/images/ace';

const _body = Rect.fromLTWH(110.2, 385, 483.6, 571.2);
const _head = Rect.fromLTWH(140, 0, 424, 445);
const _eyeL = Rect.fromLTWH(227.7, 128.8, 104.5, 122.4);
const _eyeR = Rect.fromLTWH(384.3, 142.5, 111.3, 125);
const _browL = Rect.fromLTWH(232.4, 69, 108, 67.7);
const _browR = Rect.fromLTWH(369.3, 81, 113, 71);
const _beakClosed = Rect.fromLTWH(203.5, 217.1, 302.9, 215.8);
const _beakOpen = Rect.fromLTWH(215.4, 196.1, 269.1, 267.8);
const _tear = Rect.fromLTWH(236, 226, 34, 50);
const _cheekL = Rect.fromLTWH(186, 236, 62, 34);
const _cheekR = Rect.fromLTWH(476, 250, 62, 34);

/// Points the parts turn around. The body is symmetric about [_mid].
const _mid = 352.0;
const _shoulder = Offset(115, 505);
const _neck = Offset(352, 420);
const _eyeLine = Offset(360, 198);
const _feet = Offset(352, 956);

/// Colours picked from the artwork, for the parts drawn in code.
const _eyeInk = Color(0xFF310D15);
const _blush = Color(0xFFE8464B);

/// A full turn. Raised wing angles add this so the wing swings out and up
/// around his side, not back through his body.
const double _turn = 2 * pi;

/// The three wing drawings, each with the point it turns around (its
/// wrist), in the image's own pixels.
enum _WingShape {
  open('wing', Size(173, 246), Offset(73, 225)),
  rest('wing_rest', Size(194, 261), Offset(92, 18)),
  fist('wing_fist', Size(161, 235), Offset(52, 214));

  new(this.asset, this.pixels, this.wrist);

  final String asset;
  final Size pixels;
  final Offset wrist;

  /// The wings are drawn 1.25 times their image size.
  static const scale = 1.25;
}

/// One wing's shape and angle. Angles are given for his right wing (on the
/// viewer's left) and mirrored for the other.
class _Wing {
  const new(this.shape, this.angle, {this.front = false});

  final _WingShape shape;
  final double angle;

  /// Drawn in front of his body instead of behind it.
  final bool front;
}

const _restWing = _Wing(_WingShape.rest, -0.12);

/// Every image Ace is drawn from, for precaching.
const List<String> aceAssets = [
  '$_dir/wing.png',
  '$_dir/wing_rest.png',
  '$_dir/wing_fist.png',
  '$_dir/body.png',
  '$_dir/head.png',
  '$_dir/eye_l.png',
  '$_dir/eye_r.png',
  '$_dir/brow_l.png',
  '$_dir/brow_r.png',
  '$_dir/beak_closed.png',
  '$_dir/beak_open.png',
  aceSideAsset,
];

/// Ace leaning in from the right edge, seen from the side.
const aceSideAsset = '$_dir/peek.png';

/// How long each move takes.
Duration _length(AceAction action) => switch (action) {
  AceAction.none => Duration.zero,
  AceAction.wave => const Duration(milliseconds: 1700),
  AceAction.cheer => const Duration(milliseconds: 1200),
  AceAction.fistPump => const Duration(milliseconds: 1100),
  AceAction.hop => const Duration(milliseconds: 600),
  AceAction.shrug => const Duration(milliseconds: 1300),
  AceAction.sad => const Duration(milliseconds: 1200),
};

/// Ace the eagle, [height] logical pixels tall.
class Ace extends StatefulWidget {
  const new({
    this.height = 160,
    this.action = AceAction.none,
    this.actionKey = 0,
    this.mood = AceMood.happy,
    this.talkFor = Duration.zero,
    this.facing = 0,
    this.semanticLabel = 'Ace the eagle',
    super.key,
  });

  final double height;

  /// Played once when Ace first appears, and again whenever [actionKey]
  /// changes.
  final AceAction action;
  final int actionKey;
  final AceMood mood;

  /// How long his beak moves as if speaking, from the same moments as
  /// [action].
  final Duration talkFor;

  /// Turns his face a little: -1 towards the viewer's left, 1 towards the
  /// right, such as towards his speech bubble.
  final double facing;
  final String semanticLabel;

  /// Width of Ace for a given [height].
  static double widthFor(double height) => height * _width / _height;

  @override
  State<Ace> createState() => _AceState();
}

class _AceState extends State<Ace> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );
  late final AnimationController _move = AnimationController(vsync: this);
  late final AnimationController _talk = AnimationController(vsync: this);
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        !TickerMode.valuesOf(context).enabled;
    final first = !_idle.isAnimating && _move.value == 0 && !_still;
    _still = still;
    if (still) {
      _idle
        ..stop()
        ..value = 0;
      _move.stop();
      _talk.stop();
      return;
    }
    if (!_idle.isAnimating) _idle.repeat();
    if (first) _play();
  }

  @override
  void didUpdateWidget(Ace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actionKey != widget.actionKey ||
        oldWidget.action != widget.action) {
      _play();
    }
  }

  void _play() {
    if (_still) return;
    final length = _length(widget.action);
    if (length > Duration.zero) {
      _move.duration = length;
      _move.forward(from: 0);
    }
    if (widget.talkFor > Duration.zero) {
      _talk.duration = widget.talkFor;
      _talk.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _move.dispose();
    _talk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: Ace.widthFor(height),
        height: height,
        child: FittedBox(
          child: SizedBox(
            width: _width,
            height: _height,
            child: AnimatedBuilder(
              animation: Listenable.merge([_idle, _move, _talk]),
              builder: (context, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: _margin,
                    top: 0,
                    width: _bodyWidth,
                    height: _height,
                    child: _rig(_pose()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The face and wings for [mood], before any move.
  _Pose _base(AceMood mood) {
    final pose = _Pose()..turn = widget.facing;
    switch (mood) {
      case AceMood.happy:
        // Brows a touch up, so his resting face looks friendly.
        pose.brow = -6;
      case AceMood.joyful:
        pose
          ..eyeStyle = _Eyes.smiling
          ..beak = _Beak.grin
          ..blush = 1
          ..brow = -8;
      case AceMood.cheeky:
        pose
          ..eyeStyle = _Eyes.wink
          ..beak = _Beak.grin
          ..browRaise = -18
          ..head = -0.05;
      case AceMood.surprised:
        pose
          ..eyeSize = 1.12
          ..brow = -18
          ..beak = _Beak.grin;
      case AceMood.sad:
        pose
          ..brow = -10
          ..browTilt = 0.38
          ..head = 0.12
          ..eyes = 0.8
          ..tear = 1
          ..left = const _Wing(_WingShape.rest, -0.25)
          ..right = const _Wing(_WingShape.rest, -0.25);
    }
    return pose;
  }

  _Pose _pose() {
    final action = widget.action;
    final pose = _base(widget.mood);

    if (_still) {
      // One clear pose for the moment, with no movement.
      _apply(pose, action, 0.5, still: true);
      return pose;
    }

    // Breathing, a slow sway, a glance aside and a blink now and then.
    final i = _idle.value;
    pose
      ..stretch = 1 + 0.012 * sin(2 * pi * i * 2)
      ..head += 0.02 * sin(2 * pi * i + 1);
    final glance = sin(((i - 0.3) / 0.25).clamp(0.0, 1.0) * pi);
    pose.look += 10 * glance * (widget.facing >= 0 ? 1 : -1);
    for (final blink in const [0.12, 0.62, 0.68]) {
      if (i > blink && i < blink + 0.03) {
        pose.eyes *= 0.12 + 0.88 * (1 - sin((i - blink) / 0.03 * pi));
      }
    }

    final t = _move.value;
    if (_move.isAnimating || (t > 0 && t < 1)) _apply(pose, action, t);

    // Speaking: the beak opens and shuts a few times a second.
    final k = _talk.value;
    if (_talk.isAnimating && k < 1) {
      final open = (k * widget.talkFor.inMilliseconds / 130).floor().isEven;
      if (pose.beak == _Beak.closed && open) pose.beak = _Beak.grin;
      if (pose.beak == _Beak.grin && !open) pose.beak = _Beak.closed;
    }
    return pose;
  }

  /// Moves [pose] to point [t] (0 to 1) of [action]. When [still], [t] is
  /// ignored and the move's most telling pose is used.
  void _apply(_Pose pose, AceAction action, double t, {bool still = false}) {
    switch (action) {
      case AceAction.none:
        break;
      case AceAction.wave:
        // Up, three waves, then back down.
        final up = still ? 1.0 : _ramp(t, 0, 0.16) * (1 - _ramp(t, 0.82, 1));
        final waving = !still && t > 0.16 && t < 0.82
            ? 0.27 * sin((t - 0.16) / 0.66 * 3 * 2 * pi)
            : 0.0;
        if (up > 0.02) {
          pose.left = _Wing(
            _WingShape.open,
            2.8 + (_turn - 0.45 - 2.8) * up + waving,
          );
        }
        pose
          ..head += 0.07 * up
          ..turn += 0.3 * up
          ..beak = up > 0.5 ? _Beak.grin : pose.beak
          ..eyeStyle = up > 0.5 && pose.eyeStyle == _Eyes.open
              ? _Eyes.smiling
              : pose.eyeStyle
          ..blush = max(pose.blush, up * 0.7)
          ..brow += -8 * up;
      case AceAction.cheer:
        final hops = still || t >= 0.8 ? 0.0 : sin(t / 0.8 * 2 * pi).abs();
        final up = still ? 1.0 : _ramp(t, 0, 0.1) * (1 - _ramp(t, 0.85, 1));
        final flap = still ? 0.0 : 0.3 * sin(t * 8 * pi);
        if (up > 0.02) {
          final angle = 2.8 + (_turn - 0.4 - 2.8) * up;
          pose
            ..left = _Wing(_WingShape.open, angle + flap)
            ..right = _Wing(_WingShape.open, angle - flap);
        }
        pose
          ..jump = -90 * hops
          ..squash = !still && hops < 0.15 && t < 0.85 ? 0.94 : 1
          ..beak = up > 0.3 ? _Beak.laugh : pose.beak
          ..eyeStyle = up > 0.3 ? _Eyes.smiling : pose.eyeStyle
          ..blush = max(pose.blush, up)
          ..brow += -14 * up
          ..head += still ? 0 : -0.06 * sin(t * 4 * pi);
      case AceAction.fistPump:
        final up = still ? 1.0 : _ramp(t, 0, 0.18) * (1 - _ramp(t, 0.85, 1));
        final pump = still ? 0.0 : 0.25 * sin(((t - 0.18) / 0.6) * 3 * pi);
        if (up > 0.02) {
          pose.right = _Wing(
            _WingShape.fist,
            2.6 + (_turn - 0.55 - 2.6) * up + (t > 0.18 && t < 0.78 ? pump : 0),
            front: up > 0.6,
          );
        }
        pose
          ..jump = still ? 0 : -20 * sin(t * pi)
          ..lean = 0.05 * up
          ..turn -= 0.3 * up
          ..beak = up > 0.3 ? _Beak.grin : pose.beak
          ..eyeStyle = up > 0.3 ? _Eyes.wink : pose.eyeStyle
          ..browRaise = -16 * up
          ..blush = max(pose.blush, up * 0.6);
      case AceAction.hop:
        final hop = still ? 0.0 : sin(t * pi);
        pose
          ..jump = -50 * hop
          ..beak = still || (t > 0.15 && t < 0.8) ? _Beak.grin : pose.beak
          ..brow += -8 * (still ? 1 : hop);
      case AceAction.shrug:
        final out = still ? 1.0 : _ramp(t, 0, 0.25) * (1 - _ramp(t, 0.8, 1));
        if (out > 0.02) {
          final angle = 2.8 + (_turn - 1.45 - 2.8) * out;
          pose
            ..left = _Wing(_WingShape.open, angle)
            ..right = _Wing(_WingShape.open, angle);
        }
        pose
          ..jump = -8 * out
          ..head += 0.14 * out
          ..brow += -14 * out
          ..browTilt = pose.browTilt + 0.12 * out
          ..look -= 8 * out
          ..beak = _Beak.closed;
      case AceAction.sad:
        final sigh = still ? 0.0 : sin(t * pi);
        pose
          ..jump = 14 * sigh
          ..squash = 1 - 0.04 * sigh
          ..head += 0.1 * (still ? 1 : _ramp(t, 0, 0.5))
          ..eyes *= 1 - 0.25 * sigh
          ..tearDrop = 40 * (still ? 0.6 : _ramp(t, 0.2, 1))
          ..left = const _Wing(_WingShape.rest, -0.25)
          ..right = const _Wing(_WingShape.rest, -0.25);
    }
  }

  static double _ramp(double t, double from, double to) =>
      Curves.easeInOut.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

  Widget _rig(_Pose pose) {
    // Shifting the face parts sideways turns his head a little.
    final face = pose.turn * 18;
    final eyesAt = face + pose.look;
    return Transform(
      transform: Matrix4.identity()
        ..translateByDouble(0, pose.jump, 0, 1)
        ..translateByDouble(_feet.dx, _feet.dy, 0, 1)
        ..rotateZ(pose.lean)
        ..scaleByDouble(1 / pose.squash.clamp(0.9, 1.1), pose.squash, 1, 1)
        ..translateByDouble(-_feet.dx, -_feet.dy, 0, 1),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!pose.left.front) _wing(pose.left, mirrored: false),
          if (!pose.right.front) _wing(pose.right, mirrored: true),
          _part('body', _body, scaleY: pose.stretch, pivot: _feet),
          if (pose.left.front) _wing(pose.left, mirrored: false),
          if (pose.right.front) _wing(pose.right, mirrored: true),
          _group(
            angle: pose.head,
            pivot: _neck,
            children: [
              _part('head', _head),
              if (pose.blush > 0)
                for (final cheek in [_cheekL, _cheekR])
                  _drawn(cheek.translate(face, 0), _BlushPainter(pose.blush)),
              ..._eyes(pose, eyesAt),
              _part(
                'brow_l',
                _browL.translate(face, pose.brow),
                angle: -pose.browTilt,
              ),
              _part(
                'brow_r',
                _browR.translate(face, pose.brow + pose.browRaise),
                angle: pose.browTilt,
              ),
              switch (pose.beak) {
                _Beak.closed => _part(
                  'beak_closed',
                  _beakClosed.translate(face, 0),
                ),
                // A smaller open beak, hinged at the top.
                _Beak.grin => _part(
                  'beak_open',
                  _beakOpen.translate(face, 0),
                  scaleY: 0.8,
                  pivot: _beakOpen.topCenter.translate(face, 0),
                ),
                _Beak.laugh => _part('beak_open', _beakOpen.translate(face, 0)),
              },
              if (pose.tear > 0)
                _drawn(
                  _tear.translate(face, pose.tearDrop),
                  _TearPainter(AppTokens.of(context).choice),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _eyes(_Pose pose, double dx) {
    final left = _eyeL.translate(dx, 0);
    final right = _eyeR.translate(dx, 0);
    Widget open(String name, Rect rect) => _part(
      name,
      Rect.fromCenter(
        center: rect.center,
        width: rect.width * pose.eyeSize,
        height: rect.height * pose.eyeSize,
      ),
      scaleY: pose.eyes,
      pivot: Offset(rect.center.dx, _eyeLine.dy),
    );
    Widget smiling(Rect rect) => _drawn(rect, const _SmilingEyePainter());
    return switch (pose.eyeStyle) {
      _Eyes.open => [open('eye_l', left), open('eye_r', right)],
      _Eyes.smiling => [smiling(left), smiling(right)],
      _Eyes.wink => [open('eye_l', left), smiling(right)],
    };
  }

  Widget _wing(_Wing wing, {required bool mirrored}) {
    final shape = wing.shape;
    const k = _WingShape.scale;
    final size = Size(shape.pixels.width * k, shape.pixels.height * k);
    final wrist = Offset(shape.wrist.dx * k, shape.wrist.dy * k);
    // Line the wrist up with the shoulder, then mirror for the other side.
    var rect = (_shoulder - wrist) & size;
    var pivot = _shoulder;
    var angle = wing.angle;
    if (mirrored) {
      rect = Rect.fromLTWH(
        2 * _mid - rect.right,
        rect.top,
        rect.width,
        rect.height,
      );
      pivot = Offset(2 * _mid - _shoulder.dx, _shoulder.dy);
      angle = -angle;
    }
    return Positioned.fromRect(
      rect: rect,
      child: Transform(
        origin: pivot - rect.topLeft,
        transform: Matrix4.rotationZ(angle),
        child: Transform.flip(
          flipX: mirrored,
          child: Image.asset(
            '$_dir/${shape.asset}.png',
            fit: BoxFit.fill,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }

  /// Several parts that move together, turned around [pivot].
  Widget _group({
    required Offset pivot,
    required List<Widget> children,
    double angle = 0,
  }) => Positioned.fill(
    child: Transform(
      origin: pivot,
      transform: Matrix4.rotationZ(angle),
      child: Stack(clipBehavior: Clip.none, children: children),
    ),
  );

  /// A part drawn in code at [rect].
  Widget _drawn(Rect rect, CustomPainter painter) => Positioned.fromRect(
    rect: rect,
    child: CustomPaint(painter: painter),
  );

  /// One image part at [rect], turned by [angle] around [pivot] (its own
  /// centre when null).
  Widget _part(
    String name,
    Rect rect, {
    double angle = 0,
    double scaleY = 1,
    Offset? pivot,
  }) => Positioned.fromRect(
    rect: rect,
    child: Transform(
      origin: (pivot ?? rect.center) - rect.topLeft,
      transform: Matrix4.identity()
        ..rotateZ(angle)
        ..scaleByDouble(1, scaleY, 1, 1),
      child: Image.asset(
        '$_dir/$name.png',
        fit: BoxFit.fill,
        gaplessPlayback: true,
      ),
    ),
  );
}

enum _Eyes { open, smiling, wink }

enum _Beak { closed, grin, laugh }

/// Where every part sits at one moment.
class _Pose {
  double jump = 0;
  double squash = 1;
  double stretch = 1;
  double lean = 0;
  _Wing left = _restWing;
  _Wing right = _restWing;
  double head = 0;

  /// How far his face is turned, from -1 to 1.
  double turn = 0;

  /// How far his eyes look sideways, in units.
  double look = 0;

  /// 1 is open; smaller squashes the eyes, as in a blink.
  double eyes = 1;
  double eyeSize = 1;
  _Eyes eyeStyle = _Eyes.open;
  double brow = 0;
  double browTilt = 0;

  /// Lifts his left brow (on the viewer's right) on its own.
  double browRaise = 0;
  _Beak beak = _Beak.closed;
  double blush = 0;

  /// 1 shows a tear under his right eye; [tearDrop] slides it down.
  double tear = 0;
  double tearDrop = 0;
}

/// Eyes closed in a happy curve, like an upside-down U.
class _SmilingEyePainter extends CustomPainter {
  const new();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final arc = Path()
      ..moveTo(w * 0.08, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.12, w * 0.92, h * 0.62);
    canvas.drawPath(
      arc,
      Paint()
        ..color = _eyeInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.16
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SmilingEyePainter oldDelegate) => false;
}

/// A soft rosy patch on a cheek.
class _BlushPainter extends CustomPainter {
  const new(this.amount);

  final double amount;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Offset.zero & size,
      Paint()
        ..color = _blush.withValues(alpha: 0.38 * amount)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_BlushPainter oldDelegate) => oldDelegate.amount != amount;
}

/// A teardrop, round at the bottom and pointed at the top.
class _TearPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final drop = Path()
      ..moveTo(w / 2, 0)
      ..cubicTo(w * 0.62, h * 0.3, w, h * 0.5, w, h * 0.7)
      ..arcToPoint(Offset(0, h * 0.7), radius: Radius.circular(w / 2))
      ..cubicTo(0, h * 0.5, w * 0.38, h * 0.3, w / 2, 0)
      ..close();
    canvas
      ..drawPath(drop, Paint()..color = color.withValues(alpha: 0.85))
      ..drawCircle(
        Offset(w * 0.36, h * 0.68),
        w * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
  }

  @override
  bool shouldRepaint(_TearPainter oldDelegate) => oldDelegate.color != color;
}

/// Which side of the bubble its tail points out of.
enum BubbleTail { left, right, bottom }

/// A speech bubble for Ace, with a tail pointing back at him. It pops in
/// with a little bounce.
class SpeechBubble extends StatelessWidget {
  const new({
    required this.text,
    this.tail = BubbleTail.left,
    this.maxWidth = 240,
    this.delay = const Duration(milliseconds: 120),
    this.tailAt = 0.5,
    super.key,
  });

  final String text;
  final BubbleTail tail;
  final double maxWidth;
  final Duration delay;

  /// For a bottom tail, how far across the bubble it sits, from 0 (left)
  /// to 1 (right).
  final double tailAt;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final theme = Theme.of(context);
    const tailSize = 12.0;
    final padding = switch (tail) {
      BubbleTail.left => const EdgeInsets.fromLTRB(14 + tailSize, 10, 14, 12),
      BubbleTail.right => const EdgeInsets.fromLTRB(14, 10, 14 + tailSize, 12),
      BubbleTail.bottom => const EdgeInsets.fromLTRB(14, 10, 14, 12 + tailSize),
    };
    return PopIn(
      delay: delay,
      scale: true,
      offset: 0,
      child: Semantics(
        liveRegion: true,
        label: 'Ace says: $text',
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: theme.colorScheme.surface,
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13),
                  offset: const Offset(0, 3),
                ),
              ],
              shape: _BubbleBorder(
                tail: tail,
                tailSize: tailSize,
                tailAt: tailAt,
                side: BorderSide(color: tokens.surfaceMuted, width: 2),
              ),
            ),
            child: Padding(
              padding: padding,
              child: Text(
                text,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleBorder extends ShapeBorder {
  const new({
    required this.tail,
    required this.tailSize,
    this.tailAt = 0.5,
    this.side,
  });

  final BubbleTail tail;
  final double tailSize;
  final double tailAt;
  final BorderSide? side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final s = tailSize;
    final body = switch (tail) {
      BubbleTail.left => Rect.fromLTRB(
        rect.left + s,
        rect.top,
        rect.right,
        rect.bottom,
      ),
      BubbleTail.right => Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.right - s,
        rect.bottom,
      ),
      BubbleTail.bottom => Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.right,
        rect.bottom - s,
      ),
    };
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(16)));
    // The tail sits low on the side, nearer Ace's head.
    final tailPath = switch (tail) {
      BubbleTail.left =>
        Path()
          ..moveTo(body.left + 1, body.bottom - 14 - s)
          ..lineTo(rect.left, body.bottom - 10)
          ..lineTo(body.left + 1, body.bottom - 12)
          ..close(),
      BubbleTail.right =>
        Path()
          ..moveTo(body.right - 1, body.bottom - 14 - s)
          ..lineTo(rect.right, body.bottom - 10)
          ..lineTo(body.right - 1, body.bottom - 12)
          ..close(),
      BubbleTail.bottom => _bottomTail(body, rect.bottom, s),
    };
    return Path.combine(PathOperation.union, path, tailPath);
  }

  Path _bottomTail(Rect body, double tip, double s) {
    final x = (body.left + body.width * tailAt).clamp(
      body.left + 20,
      body.right - 20,
    );
    return Path()
      ..moveTo(x - s, body.bottom - 1)
      ..lineTo(x - s * 0.4, tip)
      ..lineTo(x + s * 0.3, body.bottom - 1)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final side = this.side;
    if (side == null || side.style == BorderStyle.none) return;
    canvas.drawPath(getOuterPath(rect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => this;
}

/// Ace with a speech bubble beside him (or above him, with [above]).
/// He does [action] and moves his beak while the bubble pops in.
class AceSays extends StatelessWidget {
  const new({
    required this.text,
    this.action = AceAction.hop,
    this.mood = AceMood.happy,
    this.aceHeight = 120,
    this.bubbleWidth = 220,
    this.above = false,
    this.actionKey = 0,
    super.key,
  });

  final String text;
  final AceAction action;
  final AceMood mood;
  final double aceHeight;
  final double bubbleWidth;

  /// Puts the bubble above Ace instead of to his right.
  final bool above;
  final int actionKey;

  /// Roughly how long it takes to say [text].
  static Duration talkTime(String text) =>
      Duration(milliseconds: (text.length * 45).clamp(500, 1800));

  @override
  Widget build(BuildContext context) {
    final ace = Ace(
      height: aceHeight,
      action: action,
      mood: mood,
      actionKey: actionKey,
      talkFor: talkTime(text),
      // He looks towards his bubble.
      facing: above ? 0 : 0.6,
    );
    final bubble = SpeechBubble(
      key: ValueKey('ace-says-$actionKey-$text'),
      text: text,
      tail: above ? BubbleTail.bottom : BubbleTail.left,
      maxWidth: bubbleWidth,
    );
    if (above) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [bubble, const SizedBox(height: 2), ace],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ace,
        const SizedBox(width: 2),
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(top: aceHeight * 0.06),
            child: bubble,
          ),
        ),
      ],
    );
  }
}

/// Ace leans in from the right edge of the space he is given, says
/// [text] in a bubble to his left, and slides back out of sight after a few
/// seconds. Give him a new [key] to play again.
///
/// For a [AceMood.sad] moment he rises from below instead, so his face can
/// show it; otherwise he is drawn from the side, leaning round the edge.
/// With Reduce Motion on he simply appears and stays until removed.
class AcePeek extends StatefulWidget {
  const new({
    required this.text,
    this.action = AceAction.cheer,
    this.mood = AceMood.happy,
    this.aceHeight = 130,
    super.key,
  });

  final String text;
  final AceAction action;
  final AceMood mood;
  final double aceHeight;

  @override
  State<AcePeek> createState() => _AcePeekState();
}

class _AcePeekState extends State<AcePeek> with SingleTickerProviderStateMixin {
  // In, a few seconds on screen, then out.
  static const _in = 0.1;
  static const _out = 0.88;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        if (t >= 1) return const SizedBox.shrink();
        final shown = t < _in
            ? Curves.easeOutBack.transform(t / _in)
            : t > _out
            ? 1 - Curves.easeIn.transform((t - _out) / (1 - _out))
            : 1.0;
        final h = widget.aceHeight;
        final side = widget.mood != AceMood.sad;
        // The side view is 318 by 473 pixels; show its top three quarters.
        final sideWidth = h * 0.72 * 318 / 473 / 0.75;
        final bubbleRight = side ? sideWidth * 0.92 : Ace.widthFor(h) * 0.8;
        // A gentle bob while he is out.
        final bob = _still ? 0.0 : 3 * sin(t * 6 * pi);
        return ClipRect(
          child: SizedBox(
            height: h * 0.72,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomRight,
              children: [
                if (side)
                  Positioned(
                    right: -(1 - shown) * sideWidth,
                    top: bob,
                    width: sideWidth,
                    child: Transform.rotate(
                      angle: -0.06 * shown,
                      alignment: Alignment.bottomRight,
                      child: Semantics(
                        image: true,
                        label: 'Ace the eagle',
                        child: Image.asset(
                          aceSideAsset,
                          fit: BoxFit.fitWidth,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: -h * 0.04,
                    bottom: -h * 0.3 - (1 - shown) * h,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Ace(
                        height: h,
                        action: widget.action,
                        mood: widget.mood,
                        talkFor: AceSays.talkTime(widget.text),
                        facing: -0.6,
                      ),
                    ),
                  ),
                if (shown > 0.6)
                  Positioned(
                    right: bubbleRight,
                    top: 0,
                    child: Opacity(
                      opacity: ((shown - 0.6) / 0.4).clamp(0.0, 1.0),
                      child: SpeechBubble(
                        text: widget.text,
                        tail: BubbleTail.right,
                        maxWidth: 210,
                        delay: Duration.zero,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
