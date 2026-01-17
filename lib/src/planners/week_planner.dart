import 'package:uuid/uuid.dart';
import 'day_planner.dart';

/// Represents a weekly planner
class WeekPlanner {
  final String id;
  final DateTime weekStartDate;
  final Map<int, DayPlanner> dailyPlanners;
  final List<String> weeklyGoals;
  final String? notes;

  WeekPlanner({
    String? id,
    required this.weekStartDate,
    Map<int, DayPlanner>? dailyPlanners,
    List<String>? weeklyGoals,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        dailyPlanners = dailyPlanners ?? {},
        weeklyGoals = weeklyGoals ?? [];

  DateTime get weekEndDate => weekStartDate.add(const Duration(days: 6));

  WeekPlanner copyWith({
    DateTime? weekStartDate,
    Map<int, DayPlanner>? dailyPlanners,
    List<String>? weeklyGoals,
    String? notes,
  }) {
    return WeekPlanner(
      id: id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      dailyPlanners: dailyPlanners ?? this.dailyPlanners,
      weeklyGoals: weeklyGoals ?? this.weeklyGoals,
      notes: notes ?? this.notes,
    );
  }

  WeekPlanner addDailyPlanner(int dayOfWeek, DayPlanner planner) {
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      throw ArgumentError('dayOfWeek must be between 0 (Monday) and 6 (Sunday)');
    }
    final updatedPlanners = Map<int, DayPlanner>.from(dailyPlanners);
    updatedPlanners[dayOfWeek] = planner;
    return copyWith(dailyPlanners: updatedPlanners);
  }

  WeekPlanner removeDailyPlanner(int dayOfWeek) {
    final updatedPlanners = Map<int, DayPlanner>.from(dailyPlanners);
    updatedPlanners.remove(dayOfWeek);
    return copyWith(dailyPlanners: updatedPlanners);
  }

  WeekPlanner addWeeklyGoal(String goal) {
    return copyWith(weeklyGoals: [...weeklyGoals, goal]);
  }

  WeekPlanner removeWeeklyGoal(String goal) {
    return copyWith(weeklyGoals: weeklyGoals.where((g) => g != goal).toList());
  }

  DayPlanner? getDayPlanner(int dayOfWeek) {
    return dailyPlanners[dayOfWeek];
  }

  List<Task> getAllTasks() {
    return dailyPlanners.values
        .expand((planner) => planner.tasks)
        .toList();
  }

  int get totalTasks => getAllTasks().length;

  int get completedTasks => getAllTasks().where((t) => t.completed).length;

  double get weekCompletionRate {
    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }

  @override
  String toString() {
    return 'WeekPlanner(id: $id, weekStart: ${weekStartDate.toIso8601String().split('T')[0]}, dailyPlanners: ${dailyPlanners.length}, weeklyGoals: ${weeklyGoals.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeekPlanner && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
