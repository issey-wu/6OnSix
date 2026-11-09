import 'dart:math';

import 'package:meta/meta.dart';

/// The kinds of question the lesson player supports.
enum QuestionType { multipleChoice, trueFalse, matching, tapZone, dragDrop }

@immutable
class TeachingCard {
  const new({required this.title, required this.body});

  final String title;
  final String body;
}

@immutable
class MatchPair {
  const new({required this.left, required this.right});

  final String left;
  final String right;
}

/// One question. Which answer fields are used depends on [type]:
/// multiple choice uses [options] and [answer]; true/false uses [answer]
/// ("true" or "false"); tap the zone uses [answer] (a zone from 1 to 6);
/// matching uses [pairs]; drag-and-drop uses [tokens] and [answer]
/// (placements in token order, such as "S=1|OPP=4").
@immutable
class Question {
  const new({
    required this.id,
    required this.type,
    required this.prompt,
    required this.explanation,
    this.options = const [],
    this.answer = '',
    this.pairs = const [],
    this.tokens = const [],
    this.concepts = const [],
    this.ruleRef,
    this.leagueNote,
    this.phase,
  });

  final String id;
  final QuestionType type;
  final String prompt;
  final String explanation;
  final List<String> options;
  final String answer;
  final List<MatchPair> pairs;
  final List<String> tokens;
  final List<String> concepts;
  final String? ruleRef;
  final String? leagueNote;
  final String? phase;

  bool isCorrect(String response) => response == answer;

  /// The correct answer as the learner should read it.
  String get answerLabel => switch (type) {
    QuestionType.trueFalse => answer == 'true' ? 'True' : 'False',
    QuestionType.tapZone => 'Zone $answer',
    QuestionType.multipleChoice => answer,
    QuestionType.matching => '',
    QuestionType.dragDrop => [
      for (final entry in placements.entries)
        '${entry.key} in zone ${entry.value}',
    ].join(', '),
  };

  /// For drag-and-drop: where each token belongs.
  Map<String, int> get placements => {
    for (final part in answer.split('|'))
      if (part.contains('=')) part.split('=')[0]: int.parse(part.split('=')[1]),
  };

  @override
  bool operator ==(Object other) => other is Question && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class Lesson {
  const new({
    required this.id,
    required this.title,
    required this.cards,
    required this.questions,
  });

  final String id;
  final String title;
  final List<TeachingCard> cards;
  final List<Question> questions;
}

@immutable
class Unit {
  const new({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
  });

  final String id;
  final String title;
  final String description;
  final List<Lesson> lessons;

  /// The id of this unit's review node.
  String get reviewId => '$id.review';
}

/// One stop on the learning path: a lesson or a unit review.
@immutable
class PathNode {
  const new({
    required this.id,
    required this.unit,
    required this.title,
    this.lesson,
    this.isFinal = false,
  });

  final String id;

  /// The unit this node sits under. The final review sits under the last
  /// unit.
  final Unit unit;
  final String title;

  /// Null for a unit review or the final review.
  final Lesson? lesson;

  /// True for the final review after the last unit.
  final bool isFinal;

  bool get isReview => lesson == null;
}

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

  /// Ids of related glossary terms.
  final List<String> related;
  final String? unitId;
}

@immutable
class Course {
  const new({
    required this.schemaVersion,
    required this.units,
    this.glossary = const [],
  });

  /// The id of the final review node after the last unit.
  static const finalReviewId = 'final.review';

  /// The id used for a "practice weak spots" session. It is not a node on
  /// the path.
  static const weakSpotsId = 'practice.weak';

  final int schemaVersion;
  final List<Unit> units;

  /// Sorted A to Z by term.
  final List<GlossaryTerm> glossary;

  GlossaryTerm? termById(String id) {
    for (final term in glossary) {
      if (term.id == id) return term;
    }
    return null;
  }

  /// Every node in path order: each unit's lessons, then its review, then
  /// one final review after the last unit.
  List<PathNode> get path => [
    for (final unit in units) ...[
      for (final lesson in unit.lessons)
        PathNode(
          id: lesson.id,
          unit: unit,
          title: lesson.title,
          lesson: lesson,
        ),
      PathNode(id: unit.reviewId, unit: unit, title: 'Unit review'),
    ],
    if (units.isNotEmpty)
      PathNode(
        id: finalReviewId,
        unit: units.last,
        title: 'Final review',
        isFinal: true,
      ),
  ];

  /// Every question in the course, in lesson order.
  List<Question> get allQuestions => [
    for (final unit in units)
      for (final lesson in unit.lessons) ...lesson.questions,
  ];

  Question? questionById(String id) {
    for (final q in allQuestions) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// The lesson a question belongs to.
  Lesson? lessonOf(Question question) {
    for (final unit in units) {
      for (final lesson in unit.lessons) {
        if (lesson.questions.contains(question)) return lesson;
      }
    }
    return null;
  }

  /// Glossary terms that help with [question]: terms named in its concepts
  /// first, then terms whose name appears in [text] (the prompt or the
  /// explanation), longest names first. At most [limit].
  List<GlossaryTerm> termsFor(Question question, String text, {int limit = 3}) {
    final found = <GlossaryTerm>[];
    for (final concept in question.concepts) {
      final term = termById(concept);
      if (term != null && !found.contains(term)) found.add(term);
    }
    final lower = text.toLowerCase();
    final byLength = [...glossary]
      ..sort((a, b) => b.term.length.compareTo(a.term.length));
    for (final term in byLength) {
      if (found.length >= limit) break;
      if (found.contains(term)) continue;
      final name = RegExp.escape(term.term.toLowerCase());
      if (!RegExp('\\b$name\\b').hasMatch(lower)) continue;
      // Skip a short term inside a longer one already found, such as
      // "line" inside "attack line".
      final inside = found.any(
        (t) => t.term.toLowerCase().contains(term.term.toLowerCase()),
      );
      if (!inside) found.add(term);
    }
    return found.take(limit).toList();
  }

  PathNode? nodeById(String id) {
    for (final node in path) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// Questions for a unit review: drawn across the unit's lessons so every
  /// concept tag is covered at least once where possible, then shuffled.
  List<Question> reviewQuestions(Unit unit, {required int count, int? seed}) =>
      _drawCovering(
        [for (final lesson in unit.lessons) ...lesson.questions],
        count: count,
        seed: seed,
      );

  /// Questions for the final review: drawn across every unit the same way.
  List<Question> finalReviewQuestions({required int count, int? seed}) =>
      _drawCovering(allQuestions, count: count, seed: seed);

  static List<Question> _drawCovering(
    List<Question> questions, {
    required int count,
    int? seed,
  }) {
    final random = Random(seed);
    final pool = [...questions]..shuffle(random);
    final picked = <Question>[];
    final covered = <String>{};
    for (final q in pool) {
      if (picked.length == count) break;
      if (q.concepts.any((c) => !covered.contains(c))) {
        picked.add(q);
        covered.addAll(q.concepts);
      }
    }
    for (final q in pool) {
      if (picked.length == count) break;
      if (!picked.contains(q)) picked.add(q);
    }
    return picked..shuffle(random);
  }
}
