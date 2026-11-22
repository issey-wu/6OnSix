// The first-run tips (coach marks), by id. Which ones a learner has seen
// is saved with their settings; see AppSettings.tipsSeen.

/// Every tip, by id, in the order a new learner meets them.
abstract final class Tips {
  static const answer = 'lesson.answer';
  static const check = 'lesson.check';
  static const showMeHow = 'lesson.showMeHow';
  static const mistake = 'lesson.mistake';
  static const hint = 'lesson.hint';
  static const path = 'home.path';
  static const streak = 'home.streak';
  static const goal = 'home.goal';
  static const tabs = 'home.tabs';
  static const quests = 'quests.list';
  static const league = 'league.ladder';
  static const glossary = 'glossary.search';

  static const Set<String> all = {
    answer,
    check,
    showMeHow,
    mistake,
    hint,
    path,
    streak,
    goal,
    tabs,
    quests,
    league,
    glossary,
  };
}
