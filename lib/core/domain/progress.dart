import 'package:meta/meta.dart';
import 'package:six_on_six/core/domain/course.dart';

enum NodeState { locked, current, completed }

/// The learner's progress: finished nodes, total XP and the daily streak.
@immutable
class Progress {
  const new({
    this.completed = const {},
    this.xp = 0,
    this.streak = 0,
    this.lastActiveDay,
  });

  final Set<String> completed;
  final int xp;
  final int streak;

  /// The device-local calendar day of the last finished lesson, stored as
  /// midnight UTC so day arithmetic ignores daylight saving changes.
  final DateTime? lastActiveDay;

  /// Records a finished lesson or review at [localNow] (device local time).
  Progress complete({
    required String nodeId,
    required int xpEarned,
    required DateTime localNow,
  }) {
    final today = _day(localNow);
    final last = lastActiveDay;
    final int nextStreak;
    if (last == null) {
      nextStreak = 1;
    } else {
      final gap = today.difference(last).inDays;
      nextStreak = gap == 0 ? streak : (gap == 1 ? streak + 1 : 1);
    }
    return Progress(
      completed: {...completed, nodeId},
      xp: xp + xpEarned,
      streak: nextStreak,
      lastActiveDay: today,
    );
  }

  /// The streak to show at [localNow]: it drops to zero once a full day
  /// passes without a finished lesson.
  int streakOn(DateTime localNow) {
    final last = lastActiveDay;
    if (last == null) return 0;
    return _day(localNow).difference(last).inDays <= 1 ? streak : 0;
  }

  /// Whether a node is locked, current or completed. A node unlocks when the
  /// node before it on the path is completed.
  NodeState stateOf(List<PathNode> path, int index) {
    if (completed.contains(path[index].id)) return NodeState.completed;
    if (index == 0 || completed.contains(path[index - 1].id)) {
      return NodeState.current;
    }
    return NodeState.locked;
  }

  static DateTime _day(DateTime local) =>
      DateTime.utc(local.year, local.month, local.day);
}
