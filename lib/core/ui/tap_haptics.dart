import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// How strong a tap feels: [light] for most touches, [firm] for the main
/// buttons such as Check and Continue.
enum TapFeel { light, firm }

/// A light haptic for everyday taps (tabs, buttons, rows, answer choices),
/// so the app feels like it heard every touch. The bigger moments, such as
/// a correct answer, have their own feedback in `FeedbackService`.
abstract final class TapHaptics {
  /// Follows the Haptics setting. The app keeps this in step.
  static bool enabled = true;

  static Duration? _lastFrame;

  /// Plays one tap. Taps between the same two frames count as one touch,
  /// so a button inside a tappable card still gives a single buzz.
  static void play([TapFeel feel = TapFeel.light]) {
    if (!enabled) return;
    final frame = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    if (frame == _lastFrame) return;
    _lastFrame = frame;
    unawaited(
      feel == TapFeel.firm
          ? HapticFeedback.lightImpact()
          : HapticFeedback.selectionClick(),
    );
  }
}

/// The usual Material press ripple, plus a haptic tap. Set as the theme's
/// splash factory, every button, tab, list row and card that shows a ripple
/// when pressed also gives a tap; a disabled button shows no ripple, so it
/// stays still.
class HapticSplashFactory extends InteractiveInkFeatureFactory {
  const new({required this.base, this.feel = TapFeel.light});

  /// The ripple drawn, unchanged.
  final InteractiveInkFeatureFactory base;
  final TapFeel feel;

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    TapHaptics.play(feel);
    return base.create(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}
