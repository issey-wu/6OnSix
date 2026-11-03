import 'package:six_on_six/core/domain/course.dart';

/// Thrown when the bundled content does not match the expected format.
class ContentFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'ContentFormatException: $message';
}

const supportedSchemaVersion = 2;

/// Parses the decoded course.json produced by content/export_content.dart.
Course parseCourse(Map<String, Object?> json) {
  final version = json['schemaVersion'];
  if (version != supportedSchemaVersion) {
    throw ContentFormatException('Unsupported schemaVersion $version');
  }
  return Course(
    schemaVersion: supportedSchemaVersion,
    units: [for (final u in _list(json, 'units')) _unit(_map(u))],
    glossary: [
      if (json['glossary'] != null)
        for (final g in _list(json, 'glossary')) _term(_map(g)),
    ],
  );
}

Unit _unit(Map<String, Object?> json) => Unit(
  id: _string(json, 'id'),
  title: _string(json, 'title'),
  description: _string(json, 'description'),
  lessons: [for (final l in _list(json, 'lessons')) _lesson(_map(l))],
);

Lesson _lesson(Map<String, Object?> json) => Lesson(
  id: _string(json, 'id'),
  title: _string(json, 'title'),
  cards: [
    for (final c in _list(json, 'cards'))
      TeachingCard(
        title: _string(_map(c), 'title'),
        body: _string(_map(c), 'body'),
      ),
  ],
  questions: [for (final q in _list(json, 'questions')) _question(_map(q))],
);

Question _question(Map<String, Object?> json) {
  final type = switch (_string(json, 'type')) {
    'mc' => QuestionType.multipleChoice,
    'tf' => QuestionType.trueFalse,
    'match' => QuestionType.matching,
    'zone' => QuestionType.tapZone,
    'drag' => QuestionType.dragDrop,
    final other => throw ContentFormatException('Unknown type "$other"'),
  };
  return Question(
    id: _string(json, 'id'),
    type: type,
    prompt: _string(json, 'prompt'),
    explanation: _string(json, 'explanation'),
    options: [
      if (json['options'] != null)
        for (final o in _list(json, 'options')) o.toString(),
    ],
    answer: json['answer']?.toString() ?? '',
    pairs: [
      if (json['pairs'] != null)
        for (final p in _list(json, 'pairs'))
          MatchPair(
            left: _string(_map(p), 'left'),
            right: _string(_map(p), 'right'),
          ),
    ],
    tokens: [
      if (json['tokens'] != null)
        for (final t in _list(json, 'tokens')) t.toString(),
    ],
    concepts: [for (final c in _list(json, 'concepts')) c.toString()],
    ruleRef: json['ruleRef'] as String?,
    leagueNote: json['leagueNote'] as String?,
    phase: json['phase'] as String?,
  );
}

GlossaryTerm _term(Map<String, Object?> json) => GlossaryTerm(
  id: _string(json, 'id'),
  term: _string(json, 'term'),
  definition: _string(json, 'definition'),
  example: json['example'] as String?,
  related: [
    if (json['related'] != null)
      for (final r in _list(json, 'related')) r.toString(),
  ],
  unitId: json['unit'] as String?,
);

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw const ContentFormatException('Expected an object');
}

List<Object?> _list(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is List<Object?>) return value;
  throw ContentFormatException('Expected a list at "$key"');
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw ContentFormatException('Expected text at "$key"');
}
