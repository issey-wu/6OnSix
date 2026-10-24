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
  });

  final int lessonXp;
  final int lessonPerfectBonus;
  final int reviewXp;
  final int reviewPerfectBonus;

  /// How many questions a unit review draws from the unit's lessons.
  final int reviewQuestionCount;

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
      other.reviewQuestionCount == reviewQuestionCount;

  @override
  int get hashCode => Object.hash(
    lessonXp,
    lessonPerfectBonus,
    reviewXp,
    reviewPerfectBonus,
    reviewQuestionCount,
  );
}
