import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/core/ui/ace.dart';
import 'package:six_on_six/core/ui/coach_mark.dart';
import 'package:six_on_six/core/ui/dialogs.dart';

/// One first-run tip: what Ace says and the part of the screen it lights up.
class Tip {
  const new(
    this.id,
    this.target,
    this.text, {
    this.action = AceAction.hop,
    this.mood = AceMood.joyful,
  });

  final String id;
  final GlobalKey target;
  final String text;
  final AceAction action;
  final AceMood mood;
}

/// True when the screen at [path] is the one showing, with nothing (a
/// lesson, the goal screen) on top of it.
bool showingPath(BuildContext context, String path) =>
    GoRouter.of(context).routerDelegate.currentConfiguration.uri.path == path;

/// Shows each tip in [tips] the learner hasn't seen yet, one after another,
/// while the screen at [path] stays on top. Stops if they skip the tutorial.
Future<void> showTips(
  BuildContext context,
  WidgetRef ref, {
  required String path,
  required List<Tip> tips,
}) async {
  final settings = ref.read(settingsProvider.notifier);
  var i = 0;
  while (i < tips.length) {
    final tip = tips[i];
    if (!context.mounted || !showingPath(context, path)) return;
    final target = tip.target.currentContext;
    if (!settings.showTip(tip.id) || target == null) {
      i++;
      continue;
    }
    await Scrollable.ensureVisible(
      target,
      alignment: 0.4,
      duration: const Duration(milliseconds: 200),
    );
    if (!context.mounted) return;
    final keepGoing = await showCoachMark(
      context,
      target: tip.target,
      text: tip.text,
      action: tip.action,
      mood: tip.mood,
    );
    if (!context.mounted) return;
    if (keepGoing) {
      settings.tipSeen(tip.id);
      i++;
    } else if (await confirmSkipTutorial(context)) {
      settings.skipTips();
      return;
    }
    // Otherwise they changed their mind: show the same tip again.
  }
}

/// Asks before turning the tutorial off. True when the learner confirms.
Future<bool> confirmSkipTutorial(BuildContext context) => confirmSheet(
  context,
  title: 'Skip the tutorial?',
  message:
      "Ace won't point things out any more. You can replay the tutorial "
      'any time in Settings.',
  stay: 'Keep the tips',
  action: 'Skip tutorial',
  destructive: false,
  art: const Ace(
    height: 110,
    action: AceAction.shrug,
    mood: AceMood.surprised,
    semanticLabel: 'Ace the eagle, shrugging',
  ),
);

/// Shows [tips] the first time the screen at [path] is opened (and on
/// later visits until each has been seen).
class TipsOnArrival extends ConsumerStatefulWidget {
  const new({
    required this.path,
    required this.tips,
    required this.child,
    super.key,
  });

  final String path;
  final List<Tip> tips;
  final Widget child;

  @override
  ConsumerState<TipsOnArrival> createState() => _TipsOnArrivalState();
}

class _TipsOnArrivalState extends ConsumerState<TipsOnArrival> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(showTips(context, ref, path: widget.path, tips: widget.tips));
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
