import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/data/course_parser.dart';
import 'package:six_on_six/core/domain/glossary.dart';

const _glossary = Glossary(
  terms: [
    GlossaryTerm(
      id: 'rotation',
      term: 'Rotation',
      definition: 'Moving one zone clockwise after winning the serve back.',
    ),
    GlossaryTerm(
      id: 'ace',
      term: 'Ace',
      definition: 'A serve that scores directly.',
    ),
    GlossaryTerm(
      id: 'libero',
      term: 'Libero',
      definition: 'A back-row specialist in a contrasting jersey.',
    ),
  ],
);

void main() {
  group('Glossary.search', () {
    test('an empty search lists every term, A to Z', () {
      expect(_glossary.search('  ').map((t) => t.term), [
        'Ace',
        'Libero',
        'Rotation',
      ]);
    });

    test('matches term names, ignoring case', () {
      expect(_glossary.search('ROT').map((t) => t.id), ['rotation']);
    });

    test('matches definition text too', () {
      expect(_glossary.search('serve').map((t) => t.id), ['ace', 'rotation']);
    });

    test('returns nothing when nothing matches', () {
      expect(_glossary.search('zzz'), isEmpty);
    });
  });

  test('the bundled glossary parses and its related terms all exist', () {
    final glossary = parseGlossary(
      jsonDecode(File('assets/content/glossary.json').readAsStringSync())
          as Map<String, Object?>,
    );
    expect(glossary.terms.length, greaterThanOrEqualTo(40));
    final ids = glossary.terms.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final term in glossary.terms) {
      expect(term.definition, isNotEmpty, reason: term.id);
      for (final r in term.related) {
        expect(glossary.byId(r), isNotNull, reason: '${term.id} -> $r');
      }
    }
  });

  test('a glossary with an unknown schema version is rejected', () {
    expect(
      () => parseGlossary({'schemaVersion': 99, 'terms': <Object?>[]}),
      throwsA(isA<ContentFormatException>()),
    );
  });
}
