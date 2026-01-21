import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'week_planner.g.dart';

/// Embedded day planner entry for storing in WeekPlanner
@embedded
class DayPlannerEntry {
  late int dayOfWeek;
  late String dayPlannerId;

  DayPlannerEntry();

  DayPlannerEntry.create({
    required this.dayOfWeek,
    required this.dayPlannerId,
  });
}

/// Represents a weekly planner
@collection
class WeekPlanner {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index()
  late DateTime weekStartDate;

  late List<DayPlannerEntry> dailyPlannerEntries;
  late List<String> weeklyGoals;
  String? notes;

  WeekPlanner();

  WeekPlanner.create({
    String? id,
    required DateTime weekStartDate,
    List<DayPlannerEntry>? dailyPlannerEntries,
    List<String>? weeklyGoals,
    this.notes,
  }) {
    this.id = id ?? const Uuid().v4();
    this.weekStartDate = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day);
    this.dailyPlannerEntries = dailyPlannerEntries ?? [];
    this.weeklyGoals = weeklyGoals ?? [];
  }

  @ignore
  DateTime get weekEndDate => weekStartDate.add(const Duration(days: 6));

  WeekPlanner copyWith({
    DateTime? weekStartDate,
    List<DayPlannerEntry>? dailyPlannerEntries,
    List<String>? weeklyGoals,
    String? notes,
  }) {
    final copy = WeekPlanner()
      ..isarId = isarId
      ..id = id
      ..weekStartDate = weekStartDate ?? this.weekStartDate
      ..dailyPlannerEntries = dailyPlannerEntries ?? List<DayPlannerEntry>.from(this.dailyPlannerEntries)
      ..weeklyGoals = weeklyGoals ?? List<String>.from(this.weeklyGoals)
      ..notes = notes ?? this.notes;
    return copy;
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
  @ignore
  int get hashCode => id.hashCode;
}
