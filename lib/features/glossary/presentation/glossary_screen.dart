import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/course.dart';

/// Filters terms by name or definition, ignoring case. Kept separate from
/// the widget so it can be tested on its own.
List<GlossaryTerm> searchGlossary(List<GlossaryTerm> terms, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return terms;
  return [
    for (final t in terms)
      if (t.term.toLowerCase().contains(q) ||
          t.definition.toLowerCase().contains(q))
        t,
  ];
}

/// The Glossary tab: search, then an A to Z list grouped by first letter.
/// Every term is available from the start.
class GlossaryScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(courseProvider).value;
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final terms = searchGlossary(course?.glossary ?? const [], _query);

    final rows = <Widget>[];
    String? letter;
    for (final term in terms) {
      final first = _firstLetter(term.term);
      if (first != letter) {
        letter = first;
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Semantics(
              header: true,
              child: Text(
                first,
                style: text.titleMedium?.copyWith(
                  color: AppTheme.buttonRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }
      rows.add(
        ListTile(
          title: Text(
            term.term,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            term.definition,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => unawaited(context.push('/glossary/${term.id}')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Glossary')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search terms',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                      ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: tokens.surfaceMuted),
                ),
              ),
            ),
          ),
          Expanded(
            child: course == null
                ? const Center(child: CircularProgressIndicator())
                : terms.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No terms match "${_query.trim()}". '
                      'Try a different word.',
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  )
                : ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: rows,
                  ),
          ),
        ],
      ),
    );
  }

  String _firstLetter(String term) {
    final match = RegExp('[A-Za-z0-9]').firstMatch(term);
    final ch = match?.group(0) ?? '#';
    return RegExp('[0-9]').hasMatch(ch) ? '#' : ch.toUpperCase();
  }
}
