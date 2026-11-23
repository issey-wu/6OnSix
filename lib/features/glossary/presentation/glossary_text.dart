import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/ui/tap_haptics.dart';

/// Single words worth a link. Everyday words such as "court", "net", "in"
/// or "pass" stay plain, so a card isn't covered in underlines.
const _linkableWords = {
  'antenna',
  'setter',
  'libero',
  'lineup',
  'rotation',
  'overlap',
  'substitution',
  'ace',
  'kill',
  'dig',
  'block',
  'spike',
  'bump',
  'shank',
  'overpass',
  'pipe',
  'side-out',
};

/// Multi-word terms that are everyday phrases rather than terms to learn.
const _plainPhrases = {'"mine!"', '"free!"', 'four hits'};

/// The most links in one piece of text.
const _maxLinks = 4;

/// The glossary terms worth linking in text for a lesson in unit
/// [unitIndex] (counting from 0): those taught in that unit or earlier, so
/// a link never gives away something the learner hasn't reached yet.
List<(GlossaryTerm, RegExp)> _linkable(Course course, int unitIndex) {
  final units = [for (final u in course.units) u.id];
  final found = <(GlossaryTerm, RegExp)>[];
  for (final term in course.glossary) {
    final name = term.term.toLowerCase();
    if (name.contains('(') || _plainPhrases.contains(name)) continue;
    final multiWord = name.contains(' ') || name.contains('-');
    if (!multiWord && !_linkableWords.contains(name)) continue;
    final unit = units.indexOf(term.unitId ?? '');
    if (unit < 0 || unit > unitIndex) continue;
    // "Side-out" also matches "side out"; plurals match too.
    final words = name.split(RegExp('[- ]')).map(RegExp.escape).join(r'[-\s]');
    final plural = name == 'antenna' ? '(e|s)?' : '(s|es)?';
    found.add((term, RegExp('\\b$words$plural\\b', caseSensitive: false)));
  }
  // Longer terms first, so "back-row attack" wins over "back row".
  return found..sort((a, b) => b.$1.term.length.compareTo(a.$1.term.length));
}

/// [text] with the glossary words the learner has met so far underlined.
/// Tapping one opens its meaning in a small sheet.
class GlossaryText extends ConsumerStatefulWidget {
  const new(this.text, {required this.unitIndex, this.style, super.key});

  final String text;

  /// The unit the text belongs to, counting from 0.
  final int unitIndex;
  final TextStyle? style;

  @override
  ConsumerState<GlossaryText> createState() => _GlossaryTextState();
}

class _GlossaryTextState extends ConsumerState<GlossaryText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final course = ref.watch(courseProvider).value;
    final text = widget.text;
    if (course == null) return Text(text, style: widget.style);

    // Find the first match of each term, without overlaps.
    final matches = <(int, int, GlossaryTerm)>[];
    for (final (term, pattern) in _linkable(course, widget.unitIndex)) {
      if (matches.length >= _maxLinks) break;
      for (final m in pattern.allMatches(text)) {
        final clash = matches.any((x) => m.start < x.$2 && x.$1 < m.end);
        if (clash) continue;
        matches.add((m.start, m.end, term));
        break;
      }
    }
    if (matches.isEmpty) return Text(text, style: widget.style);
    matches.sort((a, b) => a.$1.compareTo(b.$1));

    final tokens = AppTokens.of(context);
    final spans = <InlineSpan>[];
    var at = 0;
    for (final (start, end, term) in matches) {
      if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          TapHaptics.play();
          unawaited(showTermSheet(context, term));
        };
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: text.substring(start, end),
          recognizer: recognizer,
          style: TextStyle(
            color: tokens.choice,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: tokens.choice,
            decorationThickness: 2,
          ),
          semanticsLabel: '${text.substring(start, end)}, tap for meaning',
        ),
      );
      at = end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(children: spans), style: widget.style);
  }
}

/// A short sheet with what [term] means, and an example when there is one.
Future<void> showTermSheet(BuildContext context, GlossaryTerm term) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final tokens = AppTokens.of(context);
        final text = Theme.of(context).textTheme;
        final example = term.example;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: tokens.brandYellow,
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: tokens.brandRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        term.term,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(term.definition, style: text.bodyLarge),
              if (example != null && example.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  example,
                  style: text.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('term-ok'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      },
    );
