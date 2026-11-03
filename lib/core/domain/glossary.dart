import 'package:meta/meta.dart';

/// One glossary entry. [related] holds the ids of other terms.
@immutable
class GlossaryTerm {
  const new({
    required this.id,
    required this.term,
    required this.definition,
    this.example,
    this.related = const [],
    this.unitId,
  });

  final String id;
  final String term;
  final String definition;
  final String? example;
  final List<String> related;
  final String? unitId;

  /// Whether this term matches a search. Matches the term name and the
  /// definition text, ignoring case. An empty query matches everything.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return term.toLowerCase().contains(q) ||
        definition.toLowerCase().contains(q);
  }

  @override
  bool operator ==(Object other) => other is GlossaryTerm && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Every glossary term. All terms are available from the start, whatever
/// the learner's progress.
@immutable
class Glossary {
  const new({required this.terms});

  final List<GlossaryTerm> terms;

  /// Terms matching [query], in alphabetical order.
  List<GlossaryTerm> search(String query) => [
    for (final t in terms)
      if (t.matches(query)) t,
  ]..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));

  GlossaryTerm? byId(String id) {
    for (final t in terms) {
      if (t.id == id) return t;
    }
    return null;
  }
}
