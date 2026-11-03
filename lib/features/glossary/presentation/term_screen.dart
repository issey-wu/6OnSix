import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/app/providers.dart';
import 'package:six_on_six/app/theme.dart';

/// One glossary term: definition, an example, and related terms as chips.
class TermScreen extends ConsumerWidget {
  const new({required this.termId, super.key});

  final String termId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider).value;
    final term = course?.termById(termId);
    final text = Theme.of(context).textTheme;
    final tokens = AppTokens.of(context);

    if (course == null || term == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: course == null
              ? const CircularProgressIndicator()
              : const Text('Term not found.'),
        ),
      );
    }

    final related = [for (final id in term.related) ?course.termById(id)];
    final example = term.example;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Semantics(
            header: true,
            child: Text(
              term.term,
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          Text(term.definition, style: text.bodyLarge?.copyWith(height: 1.5)),
          if (example != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.selectedBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXAMPLE',
                    style: text.labelMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    example,
                    style: text.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (related.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Related terms',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in related)
                  ActionChip(
                    label: Text(r.term),
                    onPressed: () =>
                        unawaited(context.push('/glossary/${r.id}')),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
