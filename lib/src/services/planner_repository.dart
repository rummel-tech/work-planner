import 'package:isar/isar.dart';

import '../planners/day_planner.dart';
import '../planners/week_planner.dart';
import 'database_service.dart';

class PlannerRepository {
  final Isar _isar = DatabaseService.instance.isar;

  // DayPlanner operations
  Future<List<DayPlanner>> getAllDayPlanners() async {
    return await _isar.dayPlanners.where().findAll();
  }

  Future<DayPlanner?> getDayPlannerById(String id) async {
    return await _isar.dayPlanners.filter().idEqualTo(id).findFirst();
  }

  Future<DayPlanner?> getDayPlannerByDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return await _isar.dayPlanners
        .filter()
        .dateEqualTo(normalizedDate)
        .findFirst();
  }

  Future<List<DayPlanner>> getDayPlannersByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return await _isar.dayPlanners
        .filter()
        .dateGreaterThan(normalizedStart.subtract(const Duration(days: 1)))
        .dateLessThan(normalizedEnd.add(const Duration(days: 1)))
        .findAll();
  }

  Future<DayPlanner> getOrCreateDayPlanner(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    var planner = await getDayPlannerByDate(normalizedDate);
    if (planner == null) {
      planner = DayPlanner.create(date: normalizedDate);
      await saveDayPlanner(planner);
    }
    return planner;
  }

  Future<void> saveDayPlanner(DayPlanner planner) async {
    await _isar.writeTxn(() async {
      await _isar.dayPlanners.put(planner);
    });
  }

  Future<void> deleteDayPlanner(String id) async {
    await _isar.writeTxn(() async {
      await _isar.dayPlanners.filter().idEqualTo(id).deleteFirst();
    });
  }

  Stream<DayPlanner?> watchDayPlannerByDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _isar.dayPlanners
        .filter()
        .dateEqualTo(normalizedDate)
        .watch(fireImmediately: true)
        .map((list) => list.isEmpty ? null : list.first);
  }

  // WeekPlanner operations
  Future<List<WeekPlanner>> getAllWeekPlanners() async {
    return await _isar.weekPlanners.where().findAll();
  }

  Future<WeekPlanner?> getWeekPlannerById(String id) async {
    return await _isar.weekPlanners.filter().idEqualTo(id).findFirst();
  }

  Future<WeekPlanner?> getWeekPlannerByStartDate(DateTime startDate) async {
    final normalizedDate = DateTime(startDate.year, startDate.month, startDate.day);
    return await _isar.weekPlanners
        .filter()
        .weekStartDateEqualTo(normalizedDate)
        .findFirst();
  }

  DateTime _getWeekStartDate(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  Future<WeekPlanner> getCurrentWeekPlanner() async {
    final now = DateTime.now();
    final weekStart = _getWeekStartDate(now);
    return await getOrCreateWeekPlanner(weekStart);
  }

  Future<WeekPlanner> getOrCreateWeekPlanner(DateTime weekStartDate) async {
    final normalizedDate = _getWeekStartDate(weekStartDate);
    var planner = await getWeekPlannerByStartDate(normalizedDate);
    if (planner == null) {
      planner = WeekPlanner.create(weekStartDate: normalizedDate);
      await saveWeekPlanner(planner);
    }
    return planner;
  }

  Future<void> saveWeekPlanner(WeekPlanner planner) async {
    await _isar.writeTxn(() async {
      await _isar.weekPlanners.put(planner);
    });
  }

  Future<void> deleteWeekPlanner(String id) async {
    await _isar.writeTxn(() async {
      await _isar.weekPlanners.filter().idEqualTo(id).deleteFirst();
    });
  }

  Stream<WeekPlanner?> watchCurrentWeekPlanner() {
    final now = DateTime.now();
    final weekStart = _getWeekStartDate(now);
    return _isar.weekPlanners
        .filter()
        .weekStartDateEqualTo(weekStart)
        .watch(fireImmediately: true)
        .map((list) => list.isEmpty ? null : list.first);
  }

  // Get all day planners for a week
  Future<Map<int, DayPlanner>> getDayPlannersForWeek(WeekPlanner weekPlanner) async {
    final result = <int, DayPlanner>{};
    for (final entry in weekPlanner.dailyPlannerEntries) {
      final dayPlanner = await getDayPlannerById(entry.dayPlannerId);
      if (dayPlanner != null) {
        result[entry.dayOfWeek] = dayPlanner;
      }
    }
    return result;
  }

  // Calculate week statistics
  Future<({int totalTasks, int completedTasks, double completionRate})>
      getWeekStats(WeekPlanner weekPlanner) async {
    final dayPlanners = await getDayPlannersForWeek(weekPlanner);
    int totalTasks = 0;
    int completedTasks = 0;

    for (final planner in dayPlanners.values) {
      totalTasks += planner.tasks.length;
      completedTasks += planner.completedTasks.length;
    }

    return (
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      completionRate: totalTasks > 0 ? completedTasks / totalTasks : 0.0,
    );
  }
}
