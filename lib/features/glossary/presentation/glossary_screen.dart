import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/domain/glossary.dart';

/// The Glossary tab: a search bar and every term, A to Z, grouped by first
/// letter. The search matches term names and definitions as you type.
class GlossaryScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final glossary = ref.watch(glossaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Glossary')),
      body: glossary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The glossary could not be loaded. Please reinstall the app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (glossary) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                key: const ValueKey('glossary-search'),
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search ${glossary.terms.length} terms',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Expanded(child: _results(context, glossary.search(_query))),
          ],
        ),
      ),
    );
  }

  Widget _results(BuildContext context, List<GlossaryTerm> results) {
    final tokens = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No terms match "${_query.trim()}". Try a different word.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: tokens.textSecondary),
          ),
        ),
      );
    }
    final children = <Widget>[];
    String? letter;
    for (final term in results) {
      final first = term.term.substring(0, 1).toUpperCase();
      if (first != letter) {
        letter = first;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Semantics(
              header: true,
              child: Text(
                first,
                style: text.titleSmall?.copyWith(
                  color: tokens.brandRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }
      children.add(
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
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }
}
