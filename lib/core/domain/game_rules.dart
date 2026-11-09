import 'package:meta/meta.dart';

/// XP and review values, kept in one place so a rule change is a one-line
/// edit. Values follow docs/design.md. There are no lockouts or hearts.
@immutable
class GameRules {
  const new({
    this.lessonXp = 10,
    this.lessonPerfectBonus = 5,
    this.reviewXp = 20,
    this.reviewPerfectBonus = 5,
    this.reviewQuestionCount = 8,
    this.finalReviewQuestionCount = 12,
    this.weakSpotQuestionCount = 8,
    this.weakSpotMinimum = 3,
  });

  final int lessonXp;
  final int lessonPerfectBonus;
  final int reviewXp;
  final int reviewPerfectBonus;

  /// How many questions a unit review draws from the unit's lessons.
  final int reviewQuestionCount;

  /// How many questions the final review draws from the whole course.
  final int finalReviewQuestionCount;

  /// The most questions a "practice weak spots" session asks.
  final int weakSpotQuestionCount;

  /// Weak spots practice appears once this many questions count as weak.
  final int weakSpotMinimum;

  /// XP earned for finishing a lesson or review.
  int xpFor({required bool isReview, required bool perfect}) => isReview
      ? reviewXp + (perfect ? reviewPerfectBonus : 0)
      : lessonXp + (perfect ? lessonPerfectBonus : 0);

  @override
  bool operator ==(Object other) =>
      other is GameRules &&
      other.lessonXp == lessonXp &&
      other.lessonPerfectBonus == lessonPerfectBonus &&
      other.reviewXp == reviewXp &&
      other.reviewPerfectBonus == reviewPerfectBonus &&
      other.reviewQuestionCount == reviewQuestionCount &&
      other.finalReviewQuestionCount == finalReviewQuestionCount &&
      other.weakSpotQuestionCount == weakSpotQuestionCount &&
      other.weakSpotMinimum == weakSpotMinimum;

  @override
  int get hashCode => Object.hash(
    lessonXp,
    lessonPerfectBonus,
    reviewXp,
    reviewPerfectBonus,
    reviewQuestionCount,
    finalReviewQuestionCount,
    weakSpotQuestionCount,
    weakSpotMinimum,
  );
}
