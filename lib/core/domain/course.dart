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
/// matching uses [pairs]; drag-and-drop uses [placements] (token to zone),
/// and its [answer] is the same placements in [encodePlacements] form.
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
    this.placements = const {},
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

  /// Drag-and-drop only: the correct zone for each token. The keys are the
  /// question's token set, which is what appears in the tray.
  final Map<String, int> placements;
  final List<String> concepts;
  final String? ruleRef;
  final String? leagueNote;
  final String? phase;

  bool isCorrect(String response) => response == answer;

  /// The correct answer as the learner should read it. Drag-and-drop shows
  /// the arrangement on a court instead, so its label is empty.
  String get answerLabel => switch (type) {
    QuestionType.trueFalse => answer == 'true' ? 'True' : 'False',
    QuestionType.tapZone => 'Zone $answer',
    QuestionType.multipleChoice => answer,
    QuestionType.matching => '',
    QuestionType.dragDrop => '',
  };

  /// A token-to-zone map as one stable string, such as "OH1=2|S=1".
  /// Tokens are sorted, so the same placement always gives the same text,
  /// which lets drag-and-drop be graded on exact placement with [isCorrect].
  static String encodePlacements(Map<String, int> placements) {
    final tokens = placements.keys.toList()..sort();
    return [for (final t in tokens) '$t=${placements[t]}'].join('|');
  }

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
  });

  final String id;
  final Unit unit;
  final String title;

  /// Null for a unit review.
  final Lesson? lesson;

  bool get isReview => lesson == null;
}

@immutable
class Course {
  const new({required this.schemaVersion, required this.units});

  final int schemaVersion;
  final List<Unit> units;

  /// Every node in path order: each unit's lessons, then its review.
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
  ];

  PathNode? nodeById(String id) {
    for (final node in path) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// Questions for a unit review: drawn across the unit's lessons so every
  /// concept tag is covered at least once where possible, then shuffled.
  List<Question> reviewQuestions(Unit unit, {required int count, int? seed}) {
    final random = Random(seed);
    final pool = [for (final lesson in unit.lessons) ...lesson.questions]
      ..shuffle(random);
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
