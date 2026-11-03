import 'dart:math';

import 'package:flutter/material.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';

/// A matching question: tap a left item, then its match on the right.
/// Calls [onDone] once every pair is matched.
class MatchingView extends StatefulWidget {
  const new({
    required this.question,
    required this.onDone,
    this.onPairMatched,
    this.onWrongPair,
    super.key,
  });

  final Question question;
  final ValueChanged<bool> onDone;
  final VoidCallback? onPairMatched;
  final VoidCallback? onWrongPair;

  @override
  State<MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<MatchingView> {
  late final List<MatchPair> _left;
  late final List<MatchPair> _right;
  final Set<MatchPair> _matched = {};
  MatchPair? _selectedLeft;
  MatchPair? _wrongRight;
  bool _hadMistake = false;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _left = [...widget.question.pairs]..shuffle(random);
    _right = [...widget.question.pairs]..shuffle(random);
  }

  void _tapRight(MatchPair pair) {
    final left = _selectedLeft;
    if (left == null) return;
    final correct = identical(left, pair);
    (correct ? widget.onPairMatched : widget.onWrongPair)?.call();
    setState(() {
      if (correct) {
        _matched.add(pair);
        _selectedLeft = null;
        _wrongRight = null;
      } else {
        _hadMistake = true;
        _wrongRight = pair;
        _selectedLeft = null;
      }
    });
    if (_matched.length == widget.question.pairs.length) {
      widget.onDone(_hadMistake);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    Widget tile(String text, MatchPair pair, {required bool left}) {
      final matched = _matched.contains(pair);
      final selected = left && identical(_selectedLeft, pair);
      final wrong = !left && identical(_wrongRight, pair);
      final color = matched
          ? tokens.successBg
          : wrong
          ? tokens.errorBg
          : selected
          ? tokens.selectedBg
          : Theme.of(context).colorScheme.surface;
      final border = matched
          ? tokens.success
          : wrong
          ? tokens.error
          : selected
          ? tokens.brandOrange
          : tokens.surfaceMuted;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: border, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: matched
                ? null
                : () => left
                      ? setState(() {
                          _selectedLeft = pair;
                          _wrongRight = null;
                        })
                      : _tapRight(pair),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.all(10),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  if (matched) Icon(Icons.check, color: tokens.onSuccess),
                  if (wrong) Icon(Icons.close, color: tokens.onError),
                  Expanded(child: Text(text)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [for (final p in _left) tile(p.left, p, left: true)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Column(
            children: [for (final p in _right) tile(p.right, p, left: false)],
          ),
        ),
      ],
    );
  }
}
