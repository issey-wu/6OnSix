import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/glossary.dart';

/// One glossary term: its definition, an example sentence and related
/// terms as tappable chips.
class TermScreen extends ConsumerWidget {
  const new({required this.termId, super.key});

  final String termId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glossary = ref.watch(glossaryProvider).value;
    final term = glossary?.byId(termId);
    return Scaffold(
      appBar: AppBar(),
      body: glossary == null
          ? const Center(child: CircularProgressIndicator())
          : term == null
          ? const Center(child: Text('Term not found.'))
          : _TermBody(term: term, glossary: glossary),
    );
  }
}

class _TermBody extends StatelessWidget {
  const new({required this.term, required this.glossary});

  final GlossaryTerm term;
  final Glossary glossary;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final example = term.example;
    final related = [
      for (final id in term.related)
        if (glossary.byId(id) case final GlossaryTerm r) r,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Semantics(
          header: true,
          child: Text(
            term.term,
            style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        Text(term.definition, style: text.bodyLarge?.copyWith(height: 1.5)),
        if (example != null && example.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: tokens.brandOrange, width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXAMPLE',
                  style: text.labelSmall?.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  example,
                  style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
        if (related.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Related terms',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in related)
                ActionChip(
                  label: Text(r.term),
                  onPressed: () => unawaited(context.push('/glossary/${r.id}')),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
