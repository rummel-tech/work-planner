import 'package:isar/isar.dart';

import '../models/goal.dart';
import 'database_service.dart';
import 'api_service.dart';

class GoalRepository {
  final Isar _isar = DatabaseService.instance.isar;
  final ApiService? _api;

  /// [api] is optional — when null the repository operates in local-only mode.
  GoalRepository({ApiService? api}) : _api = api;

  // ---------------------------------------------------------------------------
  // Reads — API first, Isar as fallback/cache
  // ---------------------------------------------------------------------------

  Future<List<Goal>> getAll() async {
    final api = _api; if (api != null) {
      try {
        final remote = await api.getGoals();
        final goals = remote.map(_fromJson).toList();
        await _syncToIsar(goals);
        return goals;
      } catch (_) {
        // Fall through to local cache
      }
    }
    return _isar.goals.where().findAll();
  }

  Future<List<Goal>> getByType(GoalType type) async {
    final api = _api; if (api != null) {
      try {
        final remote = await api.getGoals(goalType: type.name);
        final goals = remote.map(_fromJson).toList();
        await _syncToIsar(goals);
        return goals;
      } catch (_) {}
    }
    return _isar.goals.filter().typeEqualTo(type).findAll();
  }

  Future<List<Goal>> getByStatus(GoalStatus status) async {
    final api = _api; if (api != null) {
      try {
        final remote = await api.getGoals(status: status.name);
        final goals = remote.map(_fromJson).toList();
        await _syncToIsar(goals);
        return goals;
      } catch (_) {}
    }
    return _isar.goals.filter().statusEqualTo(status).findAll();
  }

  Future<List<Goal>> getActive() async {
    final api = _api; if (api != null) {
      try {
        final inProgress = await api.getGoals(status: GoalStatus.inProgress.name);
        final notStarted = await api.getGoals(status: GoalStatus.notStarted.name);
        final goals = [...inProgress, ...notStarted].map(_fromJson).toList();
        await _syncToIsar(goals);
        return goals;
      } catch (_) {}
    }
    return _isar.goals
        .filter()
        .statusEqualTo(GoalStatus.inProgress)
        .or()
        .statusEqualTo(GoalStatus.notStarted)
        .findAll();
  }

  Future<Goal?> getById(String id) async {
    return _isar.goals.filter().idEqualTo(id).findFirst();
  }

  // ---------------------------------------------------------------------------
  // Writes — API first, sync to Isar on success
  // ---------------------------------------------------------------------------

  Future<Goal> save(Goal goal) async {
    final api = _api; if (api != null) {
      try {
        final isNew = await getById(goal.id) == null;
        final Map<String, dynamic> body = {
          'title': goal.title,
          'description': goal.description,
          'goal_type': goal.type.name,
          'status': goal.status.name,
          if (goal.targetDate != null) 'target_date': goal.targetDate!.toIso8601String().split('T').first,
        };
        final Map<String, dynamic> remote;
        if (isNew) {
          remote = await api.createGoal(body);
        } else {
          remote = await api.updateGoal(goal.id, body);
        }
        final synced = _fromJson(remote);
        await _writeToIsar(synced);
        return synced;
      } catch (_) {
        // Fall through — write locally only
      }
    }
    await _writeToIsar(goal);
    return goal;
  }

  Future<void> delete(String id) async {
    final api = _api; if (api != null) {
      try {
        await api.deleteGoal(id);
      } catch (_) {}
    }
    await _isar.writeTxn(() => _isar.goals.filter().idEqualTo(id).deleteFirst());
  }

  Future<void> deleteAll() async {
    await _isar.writeTxn(() => _isar.goals.clear());
  }

  // ---------------------------------------------------------------------------
  // Streams (local Isar only)
  // ---------------------------------------------------------------------------

  Stream<List<Goal>> watchAll() => _isar.goals.where().watch(fireImmediately: true);

  Stream<List<Goal>> watchByType(GoalType type) =>
      _isar.goals.filter().typeEqualTo(type).watch(fireImmediately: true);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Goal _fromJson(Map<String, dynamic> json) {
    return Goal.create(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      targetDate: json['target_date'] != null ? DateTime.tryParse(json['target_date'] as String) : null,
      status: GoalStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GoalStatus.notStarted,
      ),
      type: GoalType.values.firstWhere(
        (t) => t.name == json['goal_type'],
        orElse: () => GoalType.corporate,
      ),
    );
  }

  Future<void> _writeToIsar(Goal goal) async {
    await _isar.writeTxn(() => _isar.goals.put(goal));
  }

  Future<void> _syncToIsar(List<Goal> goals) async {
    await _isar.writeTxn(() async {
      for (final g in goals) {
        await _isar.goals.put(g);
      }
    });
  }
}
