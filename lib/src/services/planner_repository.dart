import 'package:sembast/sembast.dart';
import 'package:flutter/foundation.dart';

import '../planners/day_planner.dart';
import '../planners/week_planner.dart';
import 'database_service.dart';
import 'api_service.dart';
import 'connectivity_notifier.dart';

class PlannerRepository {
  final _dayStore = stringMapStoreFactory.store('dayPlanners');
  final _weekStore = stringMapStoreFactory.store('weekPlanners');
  Database get _db => DatabaseService.instance.db;
  final ApiService? _api;

  PlannerRepository({ApiService? api}) : _api = api;

  // ---------------------------------------------------------------------------
  // DayPlanner — reads
  // ---------------------------------------------------------------------------

  Future<List<DayPlanner>> getAllDayPlanners() async {
    final records = await _dayStore.find(_db);
    return records.map((r) => _dayPlannerFromLocal(r.value)).toList();
  }

  Future<DayPlanner?> getDayPlannerById(String id) async {
    final value = await _dayStore.record(id).get(_db);
    if (value == null) return null;
    return _dayPlannerFromLocal(value);
  }

  Future<DayPlanner?> getDayPlannerByDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final dateStr = _dateStr(normalized);
    final api = _api;
    if (api != null) {
      try {
        final remote = await api.getDayPlanner(dateStr);
        final dp = _dayPlannerFromApiJson(remote);
        await _dayStore.record(dp.id).put(_db, _dayPlannerToLocal(dp));
        return dp;
      } catch (e) {
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
    }
    final records = await _dayStore.find(
      _db,
      finder: Finder(
        filter: Filter.equals('date', normalized.toIso8601String()),
      ),
    );
    if (records.isEmpty) return null;
    return _dayPlannerFromLocal(records.first.value);
  }

  Future<List<DayPlanner>> getDayPlannersByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    final records = await _dayStore.find(
      _db,
      finder: Finder(
        filter: Filter.and([
          Filter.greaterThanOrEquals('date', normalizedStart.toIso8601String()),
          Filter.lessThanOrEquals('date', normalizedEnd.toIso8601String()),
        ]),
      ),
    );
    return records.map((r) => _dayPlannerFromLocal(r.value)).toList();
  }

  Future<DayPlanner> getOrCreateDayPlanner(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final dateStr = _dateStr(normalized);

    final api = _api;
    if (api != null) {
      try {
        final remote = await api.upsertDayPlanner(dateStr);
        ConnectivityNotifier.setOffline(false);
        final dp = _dayPlannerFromApiJson(remote);
        await _dayStore.record(dp.id).put(_db, _dayPlannerToLocal(dp));
        return dp;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
    }

    final records = await _dayStore.find(
      _db,
      finder: Finder(
        filter: Filter.equals('date', normalized.toIso8601String()),
      ),
    );
    if (records.isNotEmpty) {
      return _dayPlannerFromLocal(records.first.value);
    }
    final planner = DayPlanner.create(date: normalized);
    await _dayStore.record(planner.id).put(_db, _dayPlannerToLocal(planner));
    return planner;
  }

  Future<void> saveDayPlanner(DayPlanner planner) async {
    await _dayStore.record(planner.id).put(_db, _dayPlannerToLocal(planner));
  }

  Future<DayPlanner> updateDayPlannerNotes(DateTime date, String notes) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final dateStr = _dateStr(normalized);

    final api = _api;
    if (api != null) {
      try {
        final remote = await api.updateDayPlanner(dateStr, notes: notes);
        final dp = _dayPlannerFromApiJson(remote);
        await _dayStore.record(dp.id).put(_db, _dayPlannerToLocal(dp));
        return dp;
      } catch (e) {
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
    }

    final planner = await getOrCreateDayPlanner(normalized);
    final updated = planner.copyWith(notes: notes);
    await _dayStore.record(updated.id).put(_db, _dayPlannerToLocal(updated));
    return updated;
  }

  Future<void> deleteDayPlanner(String id) async {
    await _dayStore.record(id).delete(_db);
  }

  // ---------------------------------------------------------------------------
  // Tasks — API-backed, sync to sembast via DayPlanner
  // ---------------------------------------------------------------------------

  Future<DayPlanner> addTask(DateTime date, Task task) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final dateStr = _dateStr(normalized);

    final api = _api;
    if (api != null) {
      try {
        await api.createTask(dateStr, {
          'title': task.title,
          if (task.description != null) 'description': task.description,
          'priority': task.priority.name,
          if (task.scheduledTime != null)
            'scheduled_time': task.scheduledTime!.toIso8601String(),
          if (task.durationMinutes != null)
            'duration_minutes': task.durationMinutes,
          if (task.planId != null) 'plan_id': task.planId,
          if (task.pomodoroBlock != null) 'pomodoro_block': task.pomodoroBlock,
          if (task.taskCategory != null) 'task_category': task.taskCategory!.name,
        });
        final remote = await api.getDayPlanner(dateStr);
        final dp = _dayPlannerFromApiJson(remote);
        await _dayStore.record(dp.id).put(_db, _dayPlannerToLocal(dp));
        return dp;
      } catch (e) {
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
    }

    final planner = await getOrCreateDayPlanner(normalized);
    final updated = planner.addTask(task);
    await _dayStore.record(updated.id).put(_db, _dayPlannerToLocal(updated));
    return updated;
  }

  Future<DayPlanner> updateTask(DateTime date, Task updatedTask) async {
    final api = _api;
    if (api != null) {
      try {
        await api.updateTask(updatedTask.id, {
          'title': updatedTask.title,
          if (updatedTask.description != null)
            'description': updatedTask.description,
          'priority': updatedTask.priority.name,
          'completed': updatedTask.completed,
          if (updatedTask.scheduledTime != null)
            'scheduled_time': updatedTask.scheduledTime!.toIso8601String(),
          if (updatedTask.durationMinutes != null)
            'duration_minutes': updatedTask.durationMinutes,
          'pomodoro_block': updatedTask.pomodoroBlock,
          'task_category': updatedTask.taskCategory?.name,
          if (updatedTask.planId != null) 'plan_id': updatedTask.planId,
        });
      } catch (e) {
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
    }

    final planner = await getOrCreateDayPlanner(date);
    final updated = planner.updateTask(updatedTask);
    await _dayStore.record(updated.id).put(_db, _dayPlannerToLocal(updated));
    return updated;
  }

  Future<DayPlanner> removeTask(DateTime date, String taskId) async {
    final api = _api;
    if (api != null) {
      try {
        await api.deleteTask(taskId);
      } catch (e) {
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
    }

    final planner = await getOrCreateDayPlanner(date);
    final updated = planner.removeTask(taskId);
    await _dayStore.record(updated.id).put(_db, _dayPlannerToLocal(updated));
    return updated;
  }

  // ---------------------------------------------------------------------------
  // WeekPlanner — reads
  // ---------------------------------------------------------------------------

  Future<List<WeekPlanner>> getAllWeekPlanners() async {
    final records = await _weekStore.find(_db);
    return records.map((r) => _weekPlannerFromLocal(r.value)).toList();
  }

  Future<WeekPlanner?> getWeekPlannerById(String id) async {
    final value = await _weekStore.record(id).get(_db);
    if (value == null) return null;
    return _weekPlannerFromLocal(value);
  }

  Future<WeekPlanner?> getWeekPlannerByStartDate(DateTime startDate) async {
    final normalized = DateTime(startDate.year, startDate.month, startDate.day);
    final records = await _weekStore.find(
      _db,
      finder: Finder(
        filter: Filter.equals('weekStartDate', normalized.toIso8601String()),
      ),
    );
    if (records.isEmpty) return null;
    return _weekPlannerFromLocal(records.first.value);
  }

  DateTime _weekStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  Future<WeekPlanner> getCurrentWeekPlanner() async {
    return getOrCreateWeekPlanner(_weekStart(DateTime.now()));
  }

  Future<WeekPlanner> getOrCreateWeekPlanner(DateTime weekStartDate) async {
    final normalized = _weekStart(weekStartDate);
    final dateStr = _dateStr(normalized);

    final api = _api;
    if (api != null) {
      try {
        final remote = await api.upsertWeekPlanner(dateStr);
        ConnectivityNotifier.setOffline(false);
        final wp = _weekPlannerFromApiJson(remote, normalized);
        await _weekStore.record(wp.id).put(_db, _weekPlannerToLocal(wp));
        return wp;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
    }

    final records = await _weekStore.find(
      _db,
      finder: Finder(
        filter: Filter.equals('weekStartDate', normalized.toIso8601String()),
      ),
    );
    if (records.isNotEmpty) {
      return _weekPlannerFromLocal(records.first.value);
    }
    final planner = WeekPlanner.create(weekStartDate: normalized);
    await _weekStore.record(planner.id).put(_db, _weekPlannerToLocal(planner));
    return planner;
  }

  Future<void> saveWeekPlanner(WeekPlanner planner) async {
    await _weekStore.record(planner.id).put(_db, _weekPlannerToLocal(planner));
  }

  Future<void> deleteWeekPlanner(String id) async {
    await _weekStore.record(id).delete(_db);
  }

  Future<Map<int, DayPlanner>> getDayPlannersForWeek(
    WeekPlanner weekPlanner,
  ) async {
    final result = <int, DayPlanner>{};
    for (final entry in weekPlanner.dailyPlannerEntries) {
      final dp = await getDayPlannerById(entry.dayPlannerId);
      if (dp != null) result[entry.dayOfWeek] = dp;
    }
    return result;
  }

  Future<({int totalTasks, int completedTasks, double completionRate})>
  getWeekStats(WeekPlanner weekPlanner) async {
    final api = _api;
    if (api != null) {
      try {
        final dateStr = weekPlanner.weekStartDate
            .toIso8601String()
            .split('T')
            .first;
        final stats = await api.getWeekStats(dateStr);
        return (
          totalTasks: stats['total_tasks'] as int? ?? 0,
          completedTasks: stats['completed_tasks'] as int? ?? 0,
          completionRate: (stats['completion_rate'] as num?)?.toDouble() ?? 0.0,
        );
      } catch (e) {
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
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
  // WeekPlanner — writes (API-backed)
  // ---------------------------------------------------------------------------

  Future<WeekPlanner> updateWeekPlannerGoals(
    DateTime weekStart,
    List<String> goals,
  ) async {
    final normalized = _weekStart(weekStart);
    final dateStr = _dateStr(normalized);

    final api = _api;
    if (api != null) {
      try {
        final remote = await api.updateWeekPlanner(dateStr, weeklyGoals: goals);
        ConnectivityNotifier.setOffline(false);
        final wp = _weekPlannerFromApiJson(remote, normalized);
        await _weekStore.record(wp.id).put(_db, _weekPlannerToLocal(wp));
        return wp;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
    }

    final planner = await getOrCreateWeekPlanner(normalized);
    final updated = planner.copyWith(weeklyGoals: goals);
    await _weekStore.record(updated.id).put(_db, _weekPlannerToLocal(updated));
    return updated;
  }

  Future<WeekPlanner> updateWeekPlannerNotes(
    DateTime weekStart,
    String notes,
  ) async {
    final normalized = _weekStart(weekStart);
    final dateStr = _dateStr(normalized);

    final api = _api;
    if (api != null) {
      try {
        final remote = await api.updateWeekPlanner(dateStr, notes: notes);
        ConnectivityNotifier.setOffline(false);
        final wp = _weekPlannerFromApiJson(remote, normalized);
        await _weekStore.record(wp.id).put(_db, _weekPlannerToLocal(wp));
        return wp;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
    }

    final planner = await getOrCreateWeekPlanner(normalized);
    final updated = planner.copyWith(notes: notes);
    await _weekStore.record(updated.id).put(_db, _weekPlannerToLocal(updated));
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Tasks — cross-day query by plan
  // ---------------------------------------------------------------------------

  Future<List<Task>> getTasksForPlan(String planId) async {
    final api = _api;
    if (api != null) {
      try {
        final remote = await api.getTasks(planId: planId);
        ConnectivityNotifier.setOffline(false);
        return remote.map(_taskFromApiJson).toList();
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[PlannerRepository] API error (falling back to cache): $e');
      }
    }

    final allRecords = await _dayStore.find(_db);
    final tasks = <Task>[];
    for (final r in allRecords) {
      final dp = _dayPlannerFromLocal(r.value);
      tasks.addAll(dp.tasks.where((t) => t.planId == planId));
    }
    return tasks;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _dateStr(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _taskToLocal(Task t) => {
    'id': t.id,
    'title': t.title,
    'description': t.description,
    'scheduledTime': t.scheduledTime?.toIso8601String(),
    'durationMinutes': t.durationMinutes,
    'priority': t.priority.name,
    'completed': t.completed,
    'planId': t.planId,
    'pomodoroBlock': t.pomodoroBlock,
    'taskCategory': t.taskCategory?.name,
  };

  Task _taskFromLocal(Map<String, dynamic> json) {
    return Task.create(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.tryParse(json['scheduledTime'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int?,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      completed: (json['completed'] as bool?) ?? false,
      planId: json['planId'] as String?,
      pomodoroBlock: json['pomodoroBlock'] as int?,
      taskCategory: _parseTaskCategory(json['taskCategory'] as String?),
    );
  }

  Task _taskFromApiJson(Map<String, dynamic> json) {
    return Task.create(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.tryParse(json['scheduled_time'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int?,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      completed: (json['completed'] as bool?) ?? false,
      planId: json['plan_id'] as String?,
      pomodoroBlock: json['pomodoro_block'] as int?,
      taskCategory: _parseTaskCategory(json['task_category'] as String?),
    );
  }

  TaskCategory? _parseTaskCategory(String? value) {
    if (value == null) return null;
    return TaskCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => TaskCategory.corporate,
    );
  }

  Map<String, dynamic> _dayPlannerToLocal(DayPlanner dp) => {
    'id': dp.id,
    'date': dp.date.toIso8601String(),
    'notes': dp.notes,
    'tasks': dp.tasks.map(_taskToLocal).toList(),
  };

  DayPlanner _dayPlannerFromLocal(Map<String, dynamic> json) {
    final taskList = (json['tasks'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_taskFromLocal)
        .toList();
    return DayPlanner.create(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      tasks: taskList,
    );
  }

  DayPlanner _dayPlannerFromApiJson(Map<String, dynamic> json) {
    final taskList = (json['tasks'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_taskFromApiJson)
        .toList();
    final date = DateTime.parse(json['date'] as String);
    return DayPlanner.create(
      id: json['id'] as String,
      date: DateTime(date.year, date.month, date.day),
      notes: json['notes'] as String?,
      tasks: taskList,
    );
  }

  Map<String, dynamic> _weekPlannerToLocal(WeekPlanner wp) => {
    'id': wp.id,
    'weekStartDate': wp.weekStartDate.toIso8601String(),
    'dailyPlannerEntries': wp.dailyPlannerEntries
        .map((e) => {'dayOfWeek': e.dayOfWeek, 'dayPlannerId': e.dayPlannerId})
        .toList(),
    'weeklyGoals': wp.weeklyGoals,
    'notes': wp.notes,
  };

  WeekPlanner _weekPlannerFromLocal(Map<String, dynamic> json) {
    final entries = (json['dailyPlannerEntries'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(
          (e) => DayPlannerEntry.create(
            dayOfWeek: e['dayOfWeek'] as int,
            dayPlannerId: e['dayPlannerId'] as String,
          ),
        )
        .toList();
    return WeekPlanner.create(
      id: json['id'] as String,
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
      dailyPlannerEntries: entries,
      weeklyGoals: (json['weeklyGoals'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
    );
  }

  WeekPlanner _weekPlannerFromApiJson(
    Map<String, dynamic> json,
    DateTime weekStart,
  ) {
    return WeekPlanner.create(
      id: json['id'] as String,
      weekStartDate: weekStart,
      weeklyGoals: (json['weekly_goals'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
    );
  }
}
