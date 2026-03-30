import 'package:uuid/uuid.dart';

/// Embedded day planner entry for storing in WeekPlanner
class DayPlannerEntry {
  final int dayOfWeek;
  final String dayPlannerId;

  const DayPlannerEntry({
    required this.dayOfWeek,
    required this.dayPlannerId,
  });

  DayPlannerEntry.create({
    required this.dayOfWeek,
    required this.dayPlannerId,
  });
}

/// Represents a weekly planner
class WeekPlanner {
  final String id;
  final DateTime weekStartDate;
  final List<DayPlannerEntry> dailyPlannerEntries;
  final List<String> weeklyGoals;
  final String? notes;

  const WeekPlanner._({
    required this.id,
    required this.weekStartDate,
    required this.dailyPlannerEntries,
    required this.weeklyGoals,
    this.notes,
  });

  WeekPlanner.create({
    String? id,
    required DateTime weekStartDate,
    List<DayPlannerEntry>? dailyPlannerEntries,
    List<String>? weeklyGoals,
    String? notes,
  }) : this._(
          id: id ?? const Uuid().v4(),
          weekStartDate: DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day),
          dailyPlannerEntries: dailyPlannerEntries ?? const [],
          weeklyGoals: weeklyGoals ?? const [],
          notes: notes,
        );

  DateTime get weekEndDate => weekStartDate.add(const Duration(days: 6));

  WeekPlanner copyWith({
    DateTime? weekStartDate,
    List<DayPlannerEntry>? dailyPlannerEntries,
    List<String>? weeklyGoals,
    String? notes,
  }) {
    return WeekPlanner._(
      id: id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      dailyPlannerEntries: dailyPlannerEntries ?? List<DayPlannerEntry>.from(this.dailyPlannerEntries),
      weeklyGoals: weeklyGoals ?? List<String>.from(this.weeklyGoals),
      notes: notes ?? this.notes,
    );
  }

  WeekPlanner addDailyPlannerEntry(int dayOfWeek, String dayPlannerId) {
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      throw ArgumentError('dayOfWeek must be between 0 (Monday) and 6 (Sunday)');
    }
    final updatedEntries = dailyPlannerEntries
        .where((e) => e.dayOfWeek != dayOfWeek)
        .toList();
    updatedEntries.add(DayPlannerEntry.create(
      dayOfWeek: dayOfWeek,
      dayPlannerId: dayPlannerId,
    ));
    return copyWith(dailyPlannerEntries: updatedEntries);
  }

  WeekPlanner removeDailyPlannerEntry(int dayOfWeek) {
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      throw ArgumentError('dayOfWeek must be between 0 (Monday) and 6 (Sunday)');
    }
    final updatedEntries = dailyPlannerEntries
        .where((e) => e.dayOfWeek != dayOfWeek)
        .toList();
    return copyWith(dailyPlannerEntries: updatedEntries);
  }

  String? getDayPlannerId(int dayOfWeek) {
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      throw ArgumentError('dayOfWeek must be between 0 (Monday) and 6 (Sunday)');
    }
    try {
      return dailyPlannerEntries
          .firstWhere((e) => e.dayOfWeek == dayOfWeek)
          .dayPlannerId;
    } catch (_) {
      return null;
    }
  }

  WeekPlanner addWeeklyGoal(String goal) {
    return copyWith(weeklyGoals: [...weeklyGoals, goal]);
  }

  WeekPlanner removeWeeklyGoal(String goal) {
    return copyWith(weeklyGoals: weeklyGoals.where((g) => g != goal).toList());
  }

  @override
  String toString() {
    return 'WeekPlanner(id: $id, weekStart: ${weekStartDate.toIso8601String().split('T')[0]}, dailyPlanners: ${dailyPlannerEntries.length}, weeklyGoals: ${weeklyGoals.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeekPlanner && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
