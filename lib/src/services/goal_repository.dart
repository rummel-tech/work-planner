import 'package:sembast/sembast.dart';
import 'package:flutter/foundation.dart';

import '../models/goal.dart';
import 'database_service.dart';
import 'api_service.dart';
import 'connectivity_notifier.dart';

class GoalRepository {
  final _store = stringMapStoreFactory.store('goals');
  Database get _db => DatabaseService.instance.db;
  final ApiService? _api;

  GoalRepository({ApiService? api}) : _api = api;

  // ---------------------------------------------------------------------------
  // Reads — API first, sembast as fallback/cache
  // ---------------------------------------------------------------------------

  Future<List<Goal>> getAll() async {
    final api = _api; if (api != null) {
      try {
        final remote = await api.getGoals();
        ConnectivityNotifier.setOffline(false);
        final goals = remote.map(_fromApiJson).toList();
        await _syncToDb(goals);
        return goals;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[GoalRepository] API error (falling back to cache): $e');
      }
    }
    final records = await _store.find(_db);
    return records.map((r) => _fromLocal(r.value)).toList();
  }

  Future<List<Goal>> getByType(GoalType type) async {
    final api = _api; if (api != null) {
      try {
        final remote = await api.getGoals(goalType: type.name);
        ConnectivityNotifier.setOffline(false);
        final goals = remote.map(_fromApiJson).toList();
        await _syncToDb(goals);
        return goals;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[GoalRepository] API error (falling back to cache): $e');
      }
    }
    final records = await _store.find(_db,
        finder: Finder(filter: Filter.equals('type', type.name)));
    return records.map((r) => _fromLocal(r.value)).toList();
  }

  Future<List<Goal>> getByStatus(GoalStatus status) async {
    final api = _api; if (api != null) {
      try {
        final remote = await api.getGoals(status: status.name);
        ConnectivityNotifier.setOffline(false);
        final goals = remote.map(_fromApiJson).toList();
        await _syncToDb(goals);
        return goals;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[GoalRepository] API error (falling back to cache): $e');
      }
    }
    final records = await _store.find(_db,
        finder: Finder(filter: Filter.equals('status', status.name)));
    return records.map((r) => _fromLocal(r.value)).toList();
  }

  Future<List<Goal>> getActive() async {
    final api = _api; if (api != null) {
      try {
        final inProgress = await api.getGoals(status: GoalStatus.inProgress.name);
        final notStarted = await api.getGoals(status: GoalStatus.notStarted.name);
        ConnectivityNotifier.setOffline(false);
        final goals = [...inProgress, ...notStarted].map(_fromApiJson).toList();
        await _syncToDb(goals);
        return goals;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[GoalRepository] API error (falling back to cache): $e');
      }
    }
    final records = await _store.find(_db,
        finder: Finder(
          filter: Filter.or([
            Filter.equals('status', GoalStatus.inProgress.name),
            Filter.equals('status', GoalStatus.notStarted.name),
          ]),
        ));
    return records.map((r) => _fromLocal(r.value)).toList();
  }

  Future<Goal?> getById(String id) async {
    final value = await _store.record(id).get(_db);
    if (value == null) return null;
    return _fromLocal(value);
  }

  // ---------------------------------------------------------------------------
  // Writes — API first, sync to sembast on success
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
        ConnectivityNotifier.setOffline(false);
        final synced = _fromApiJson(remote);
        await _store.record(synced.id).put(_db, _toLocal(synced));
        return synced;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[GoalRepository] API error (falling back to cache): $e');
      }
    }
    await _store.record(goal.id).put(_db, _toLocal(goal));
    return goal;
  }

  Future<void> delete(String id) async {
    final api = _api; if (api != null) {
      try {
        await api.deleteGoal(id);
      } catch (e) { debugPrint('[GoalRepository] API error: $e'); }
    }
    await _store.record(id).delete(_db);
  }

  Future<void> deleteAll() async {
    await _store.delete(_db);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toLocal(Goal goal) => {
    'id': goal.id,
    'title': goal.title,
    'description': goal.description,
    'createdAt': goal.createdAt.toIso8601String(),
    'targetDate': goal.targetDate?.toIso8601String(),
    'status': goal.status.name,
    'type': goal.type.name,
  };

  Goal _fromLocal(Map<String, dynamic> json) {
    return Goal.create(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      targetDate: json['targetDate'] != null ? DateTime.tryParse(json['targetDate'] as String) : null,
      status: GoalStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GoalStatus.notStarted,
      ),
      type: GoalType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => GoalType.corporate,
      ),
    );
  }

  Goal _fromApiJson(Map<String, dynamic> json) {
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

  Future<void> _syncToDb(List<Goal> goals) async {
    await _db.transaction((txn) async {
      for (final g in goals) {
        await _store.record(g.id).put(txn, _toLocal(g));
      }
    });
  }
}
