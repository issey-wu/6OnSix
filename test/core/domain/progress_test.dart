import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/core/domain/course.dart';
import 'package:six_on_six/core/domain/game_rules.dart';
import 'package:six_on_six/core/domain/progress.dart';

void main() {
  final day1 = DateTime(2026, 10, 20, 21);

  group('streak', () {
    test('starts at 1 and does not grow twice on the same day', () {
      final p = const Progress()
          .complete(nodeId: 'a', xpEarned: 10, localNow: day1)
          .complete(
            nodeId: 'b',
            xpEarned: 10,
            localNow: day1.add(const Duration(hours: 2)),
          );
      expect(p.streak, 1);
      expect(p.xp, 20);
    });

    test('grows on the next calendar day, even a few minutes later', () {
      final p = const Progress()
          .complete(
            nodeId: 'a',
            xpEarned: 10,
            localNow: DateTime(2026, 10, 20, 23, 58),
          )
          .complete(
            nodeId: 'b',
            xpEarned: 10,
            localNow: DateTime(2026, 10, 21, 0, 3),
          );
      expect(p.streak, 2);
    });

    test('resets after a missed day', () {
      final p = const Progress()
          .complete(nodeId: 'a', xpEarned: 10, localNow: day1)
          .complete(
            nodeId: 'b',
            xpEarned: 10,
            localNow: day1.add(const Duration(days: 2)),
          );
      expect(p.streak, 1);
    });

    test('shows zero once a full day passes without a lesson', () {
      final p = const Progress().complete(
        nodeId: 'a',
        xpEarned: 10,
        localNow: day1,
      );
      expect(p.streakOn(day1.add(const Duration(days: 1))), 1);
      expect(p.streakOn(day1.add(const Duration(days: 2))), 0);
    });
  });

  test('a node unlocks when the node before it is completed', () {
    const unit = Unit(id: 'u1', title: 'U', description: 'd', lessons: []);
    const path = [
      PathNode(id: 'a', unit: unit, title: 'A'),
      PathNode(id: 'b', unit: unit, title: 'B'),
      PathNode(id: 'c', unit: unit, title: 'C'),
    ];
    const progress = Progress(completed: {'a'});
    expect(progress.stateOf(path, 0), NodeState.completed);
    expect(progress.stateOf(path, 1), NodeState.current);
    expect(progress.stateOf(path, 2), NodeState.locked);
  });

  test('XP follows the design values', () {
    const rules = GameRules();
    expect(rules.xpFor(isReview: false, perfect: false), 10);
    expect(rules.xpFor(isReview: false, perfect: true), 15);
    expect(rules.xpFor(isReview: true, perfect: false), 20);
    expect(rules.xpFor(isReview: true, perfect: true), 25);
  });
}
