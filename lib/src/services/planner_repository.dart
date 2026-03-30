import 'package:isar/isar.dart';

import '../planners/day_planner.dart';
import '../planners/week_planner.dart';
import 'database_service.dart';
import 'api_service.dart';

class PlannerRepository {
  final Isar _isar = DatabaseService.instance.isar;
  final ApiService? _api;

  PlannerRepository({ApiService? api}) : _api = api;

  // ---------------------------------------------------------------------------
  // DayPlanner — reads
  // ---------------------------------------------------------------------------

  Future<List<DayPlanner>> getAllDayPlanners() async {
    return _isar.dayPlanners.where().findAll();
  }

  Future<DayPlanner?> getDayPlannerById(String id) async {
    return _isar.dayPlanners.filter().idEqualTo(id).findFirst();
  }

  Future<DayPlanner?> getDayPlannerByDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final api = _api; if (api != null) {
      try {
        final dateStr = '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
        final remote = await api.getDayPlanner(dateStr);
        final dp = _dayPlannerFromJson(remote);
        await _isar.writeTxn(() => _isar.dayPlanners.put(dp));
        return dp;
      } catch (_) {}
    }
    return _isar.dayPlanners.filter().dateEqualTo(normalized).findFirst();
  }

  Future<List<DayPlanner>> getDayPlannersByDateRange(DateTime start, DateTime end) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return _isar.dayPlanners
        .filter()
        .dateGreaterThan(normalizedStart.subtract(const Duration(days: 1)))
        .dateLessThan(normalizedEnd.add(const Duration(days: 1)))
        .findAll();
  }

  Future<DayPlanner> getOrCreateDayPlanner(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final dateStr = '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';

    final api = _api; if (api != null) {
      try {
        final remote = await api.upsertDayPlanner(dateStr);
        final dp = _dayPlannerFromJson(remote);
        await _isar.writeTxn(() => _isar.dayPlanners.put(dp));
        return dp;
      } catch (_) {}
    }

    var planner = await _isar.dayPlanners.filter().dateEqualTo(normalized).findFirst();
    if (planner == null) {
      planner = DayPlanner.create(date: normalized);
      await _isar.writeTxn(() => _isar.dayPlanners.put(planner!));
    }
    return planner;
  }

  Future<void> saveDayPlanner(DayPlanner planner) async {
    await _isar.writeTxn(() => _isar.dayPlanners.put(planner));
  }

  Future<void> deleteDayPlanner(String id) async {
    await _isar.writeTxn(() => _isar.dayPlanners.filter().idEqualTo(id).deleteFirst());
  }

  Stream<DayPlanner?> watchDayPlannerByDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _isar.dayPlanners
        .filter()
        .dateEqualTo(normalized)
        .watch(fireImmediately: true)
        .map((list) => list.isEmpty ? null : list.first);
  }

  // ---------------------------------------------------------------------------
  // Tasks — API-backed, sync to Isar via DayPlanner
  // ---------------------------------------------------------------------------

  Future<DayPlanner> addTask(DateTime date, Task task) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final dateStr = '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';

    final api = _api; if (api != null) {
      try {
        await api.createTask(dateStr, {
          'title': task.title,
          if (task.description != null) 'description': task.description,
          'priority': task.priority.name,
          if (task.scheduledTime != null) 'scheduled_time': task.scheduledTime!.toIso8601String(),
          if (task.durationMinutes != null) 'duration_minutes': task.durationMinutes,
          if (task.planId != null) 'plan_id': task.planId,
        });
        // Re-fetch to get server-assigned IDs
        final remote = await api.getDayPlanner(dateStr);
        final dp = _dayPlannerFromJson(remote);
        await _isar.writeTxn(() => _isar.dayPlanners.put(dp));
        return dp;
      } catch (_) {}
    }

    final planner = await getOrCreateDayPlanner(normalized);
    final updated = planner.addTask(task);
    await _isar.writeTxn(() => _isar.dayPlanners.put(updated));
    return updated;
  }

  Future<DayPlanner> updateTask(DateTime date, Task updatedTask) async {
    final api = _api; if (api != null) {
      try {
        await api.updateTask(updatedTask.id, {
          'title': updatedTask.title,
          if (updatedTask.description != null) 'description': updatedTask.description,
          'priority': updatedTask.priority.name,
          'completed': updatedTask.completed,
          if (updatedTask.scheduledTime != null) 'scheduled_time': updatedTask.scheduledTime!.toIso8601String(),
          if (updatedTask.durationMinutes != null) 'duration_minutes': updatedTask.durationMinutes,
        });
      } catch (_) {}
    }

    final planner = await getOrCreateDayPlanner(date);
    final updated = planner.updateTask(updatedTask);
    await _isar.writeTxn(() => _isar.dayPlanners.put(updated));
    return updated;
  }

  Future<DayPlanner> removeTask(DateTime date, String taskId) async {
    final api = _api; if (api != null) {
      try {
        await api.deleteTask(taskId);
      } catch (_) {}
    }

    final planner = await getOrCreateDayPlanner(date);
    final updated = planner.removeTask(taskId);
    await _isar.writeTxn(() => _isar.dayPlanners.put(updated));
    return updated;
  }

  // ---------------------------------------------------------------------------
  // WeekPlanner — reads
  // ---------------------------------------------------------------------------

  Future<List<WeekPlanner>> getAllWeekPlanners() async {
    return _isar.weekPlanners.where().findAll();
  }

  Future<WeekPlanner?> getWeekPlannerById(String id) async {
    return _isar.weekPlanners.filter().idEqualTo(id).findFirst();
  }

  Future<WeekPlanner?> getWeekPlannerByStartDate(DateTime startDate) async {
    final normalized = DateTime(startDate.year, startDate.month, startDate.day);
    return _isar.weekPlanners.filter().weekStartDateEqualTo(normalized).findFirst();
  }

  DateTime _weekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  Future<WeekPlanner> getCurrentWeekPlanner() async {
    return getOrCreateWeekPlanner(_weekStart(DateTime.now()));
  }

  Future<WeekPlanner> getOrCreateWeekPlanner(DateTime weekStartDate) async {
    final normalized = _weekStart(weekStartDate);
    final dateStr = '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';

    final api = _api; if (api != null) {
      try {
        final remote = await api.upsertWeekPlanner(dateStr);
        final wp = _weekPlannerFromJson(remote, normalized);
        await _isar.writeTxn(() => _isar.weekPlanners.put(wp));
        return wp;
      } catch (_) {}
    }

    var planner = await _isar.weekPlanners.filter().weekStartDateEqualTo(normalized).findFirst();
    if (planner == null) {
      planner = WeekPlanner.create(weekStartDate: normalized);
      await _isar.writeTxn(() => _isar.weekPlanners.put(planner!));
    }
    return planner;
  }

  Future<void> saveWeekPlanner(WeekPlanner planner) async {
    await _isar.writeTxn(() => _isar.weekPlanners.put(planner));
  }

  Future<void> deleteWeekPlanner(String id) async {
    await _isar.writeTxn(() => _isar.weekPlanners.filter().idEqualTo(id).deleteFirst());
  }

  Stream<WeekPlanner?> watchCurrentWeekPlanner() {
    final ws = _weekStart(DateTime.now());
    return _isar.weekPlanners
        .filter()
        .weekStartDateEqualTo(ws)
        .watch(fireImmediately: true)
        .map((list) => list.isEmpty ? null : list.first);
  }

  Future<Map<int, DayPlanner>> getDayPlannersForWeek(WeekPlanner weekPlanner) async {
    final result = <int, DayPlanner>{};
    for (final entry in weekPlanner.dailyPlannerEntries) {
      final dp = await getDayPlannerById(entry.dayPlannerId);
      if (dp != null) result[entry.dayOfWeek] = dp;
    }
    return result;
  }

  Future<({int totalTasks, int completedTasks, double completionRate})> getWeekStats(
    WeekPlanner weekPlanner,
  ) async {
    final api = _api; if (api != null) {
      try {
        final dateStr = weekPlanner.weekStartDate.toIso8601String().split('T').first;
        final stats = await api.getWeekStats(dateStr);
        return (
          totalTasks: stats['total_tasks'] as int? ?? 0,
          completedTasks: stats['completed_tasks'] as int? ?? 0,
          completionRate: (stats['completion_rate'] as num?)?.toDouble() ?? 0.0,
        );
      } catch (_) {}
    }

    final dayPlanners = await getDayPlannersForWeek(weekPlanner);
    int total = 0;
    int completed = 0;
    for (final dp in dayPlanners.values) {
      total += dp.tasks.length;
      completed += dp.completedTasks.length;
    }
    return (
      totalTasks: total,
      completedTasks: completed,
      completionRate: total > 0 ? completed / total : 0.0,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DayPlanner _dayPlannerFromJson(Map<String, dynamic> json) {
    final taskList = (json['tasks'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_taskFromJson)
        .toList();
    final date = DateTime.parse(json['date'] as String);
    return DayPlanner.create(
      id: json['id'] as String,
      date: DateTime(date.year, date.month, date.day),
      notes: json['notes'] as String?,
      tasks: taskList,
    );
  }

  Task _taskFromJson(Map<String, dynamic> json) {
    return Task.create(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledTime: json['scheduled_time'] != null ? DateTime.tryParse(json['scheduled_time'] as String) : null,
      durationMinutes: json['duration_minutes'] as int?,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      completed: (json['completed'] as bool?) ?? false,
      planId: json['plan_id'] as String?,
    );
  }

  WeekPlanner _weekPlannerFromJson(Map<String, dynamic> json, DateTime weekStart) {
    return WeekPlanner.create(
      id: json['id'] as String,
      weekStartDate: weekStart,
      weeklyGoals: (json['weekly_goals'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
    );
  }
}
