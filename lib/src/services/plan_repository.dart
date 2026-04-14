import 'package:sembast/sembast.dart';
import 'package:flutter/foundation.dart';

import '../models/plan.dart';
import 'database_service.dart';
import 'api_service.dart';
import 'connectivity_notifier.dart';

class PlanRepository {
  final _store = stringMapStoreFactory.store('plans');
  Database get _db => DatabaseService.instance.db;
  final ApiService? _api;

  PlanRepository({ApiService? api}) : _api = api;

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<List<Plan>> getAll() async {
    final api = _api;
    if (api != null) {
      try {
        final remote = await api.getPlans();
        ConnectivityNotifier.setOffline(false);
        final plans = remote.map(_fromApiJson).toList();
        await _syncToDb(plans);
        return plans;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[PlanRepository] API error (falling back to cache): $e');
      }
    }
    final records = await _store.find(_db);
    return records.map((r) => _fromLocal(r.value)).toList();
  }

  Future<List<Plan>> getByGoalId(String goalId) async {
    final api = _api;
    if (api != null) {
      try {
        final remote = await api.getPlans(goalId: goalId);
        ConnectivityNotifier.setOffline(false);
        final plans = remote.map(_fromApiJson).toList();
        await _syncToDb(plans);
        return plans;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[PlanRepository] API error (falling back to cache): $e');
      }
    }
    final records = await _store.find(
      _db,
      finder: Finder(filter: Filter.equals('goalId', goalId)),
    );
    return records.map((r) => _fromLocal(r.value)).toList();
  }

  Future<List<Plan>> getByStatus(PlanStatus status) async {
    final api = _api;
    if (api != null) {
      try {
        final remote = await api.getPlans(status: status.name);
        ConnectivityNotifier.setOffline(false);
        final plans = remote.map(_fromApiJson).toList();
        await _syncToDb(plans);
        return plans;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[PlanRepository] API error (falling back to cache): $e');
      }
    }
    final records = await _store.find(
      _db,
      finder: Finder(filter: Filter.equals('status', status.name)),
    );
    return records.map((r) => _fromLocal(r.value)).toList();
  }

  Future<List<Plan>> getActive() async => getByStatus(PlanStatus.active);

  Future<Plan?> getById(String id) async {
    final value = await _store.record(id).get(_db);
    if (value == null) return null;
    return _fromLocal(value);
  }

  Future<int> countByGoalId(String goalId) async {
    return _store.count(_db, filter: Filter.equals('goalId', goalId));
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<Plan> save(Plan plan) async {
    final api = _api;
    if (api != null) {
      try {
        final isNew = await getById(plan.id) == null;
        final body = {
          'goal_id': plan.goalId,
          'title': plan.title,
          'description': plan.description,
          'status': plan.status.name,
          if (plan.startDate != null)
            'start_date': plan.startDate!.toIso8601String().split('T').first,
          if (plan.endDate != null)
            'end_date': plan.endDate!.toIso8601String().split('T').first,
          'steps': plan.steps,
        };
        final Map<String, dynamic> remote;
        if (isNew) {
          remote = await api.createPlan(body);
        } else {
          remote = await api.updatePlan(plan.id, body);
        }
        ConnectivityNotifier.setOffline(false);
        final synced = _fromApiJson(remote);
        await _store.record(synced.id).put(_db, _toLocal(synced));
        return synced;
      } catch (e) {
        if (e is ApiNetworkException) ConnectivityNotifier.setOffline(true);
        debugPrint('[PlanRepository] API error (falling back to cache): $e');
      }
    }
    await _store.record(plan.id).put(_db, _toLocal(plan));
    return plan;
  }

  Future<void> delete(String id) async {
    final api = _api;
    if (api != null) {
      try {
        await api.deletePlan(id);
      } catch (e) {
        debugPrint('[PlanRepository] API error: $e');
      }
    }
    await _store.record(id).delete(_db);
  }

  Future<void> deleteByGoalId(String goalId) async {
    final plans = await getByGoalId(goalId);
    final api = _api;
    if (api != null) {
      for (final p in plans) {
        try {
          await api.deletePlan(p.id);
        } catch (e) {
          debugPrint('[PlanRepository] API error: $e');
        }
      }
    }
    await _store.delete(
      _db,
      finder: Finder(filter: Filter.equals('goalId', goalId)),
    );
  }

  Future<void> deleteAll() async {
    await _store.delete(_db);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toLocal(Plan plan) => {
    'id': plan.id,
    'title': plan.title,
    'description': plan.description,
    'goalId': plan.goalId,
    'createdAt': plan.createdAt.toIso8601String(),
    'startDate': plan.startDate?.toIso8601String(),
    'endDate': plan.endDate?.toIso8601String(),
    'steps': plan.steps,
    'status': plan.status.name,
  };

  Plan _fromLocal(Map<String, dynamic> json) {
    return Plan.create(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      goalId: json['goalId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      steps: (json['steps'] as List?)?.cast<String>() ?? [],
      status: PlanStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PlanStatus.draft,
      ),
    );
  }

  Plan _fromApiJson(Map<String, dynamic> json) {
    return Plan.create(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      steps: (json['steps'] as List?)?.cast<String>() ?? [],
      status: PlanStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PlanStatus.draft,
      ),
    );
  }

  Future<void> _syncToDb(List<Plan> plans) async {
    await _db.transaction((txn) async {
      for (final p in plans) {
        await _store.record(p.id).put(txn, _toLocal(p));
      }
    });
  }
}
