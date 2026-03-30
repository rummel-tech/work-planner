import 'package:isar/isar.dart';

import '../models/plan.dart';
import 'database_service.dart';
import 'api_service.dart';

class PlanRepository {
  final Isar _isar = DatabaseService.instance.isar;
  final ApiService? _api;

  PlanRepository({ApiService? api}) : _api = api;

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<List<Plan>> getAll() async {
    final api = _api; if (api != null) {
      try {
        final remote = await api.getPlans();
        final plans = remote.map(_fromJson).toList();
        await _syncToIsar(plans);
        return plans;
      } catch (_) {}
    }
    return _isar.plans.where().findAll();
  }

  Future<List<Plan>> getByGoalId(String goalId) async {
    final api = _api; if (api != null) {
      try {
        final remote = await api.getPlans(goalId: goalId);
        final plans = remote.map(_fromJson).toList();
        await _syncToIsar(plans);
        return plans;
      } catch (_) {}
    }
    return _isar.plans.filter().goalIdEqualTo(goalId).findAll();
  }

  Future<List<Plan>> getByStatus(PlanStatus status) async {
    final api = _api; if (api != null) {
      try {
        final remote = await api.getPlans(status: status.name);
        final plans = remote.map(_fromJson).toList();
        await _syncToIsar(plans);
        return plans;
      } catch (_) {}
    }
    return _isar.plans.filter().statusEqualTo(status).findAll();
  }

  Future<List<Plan>> getActive() async => getByStatus(PlanStatus.active);

  Future<Plan?> getById(String id) async =>
      _isar.plans.filter().idEqualTo(id).findFirst();

  Future<int> countByGoalId(String goalId) async =>
      _isar.plans.filter().goalIdEqualTo(goalId).count();

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<Plan> save(Plan plan) async {
    final api = _api; if (api != null) {
      try {
        final isNew = await getById(plan.id) == null;
        final body = {
          'goal_id': plan.goalId,
          'title': plan.title,
          'description': plan.description,
          'status': plan.status.name,
          if (plan.startDate != null) 'start_date': plan.startDate!.toIso8601String().split('T').first,
          if (plan.endDate != null) 'end_date': plan.endDate!.toIso8601String().split('T').first,
          'steps': plan.steps,
        };
        final Map<String, dynamic> remote;
        if (isNew) {
          remote = await api.createPlan(body);
        } else {
          remote = await api.updatePlan(plan.id, body);
        }
        final synced = _fromJson(remote);
        await _writeToIsar(synced);
        return synced;
      } catch (_) {}
    }
    await _writeToIsar(plan);
    return plan;
  }

  Future<void> delete(String id) async {
    final api = _api; if (api != null) {
      try {
        await api.deletePlan(id);
      } catch (_) {}
    }
    await _isar.writeTxn(() => _isar.plans.filter().idEqualTo(id).deleteFirst());
  }

  Future<void> deleteByGoalId(String goalId) async {
    final plans = await _isar.plans.filter().goalIdEqualTo(goalId).findAll();
    final api = _api; if (api != null) {
      for (final p in plans) {
        try {
          await api.deletePlan(p.id);
        } catch (_) {}
      }
    }
    await _isar.writeTxn(() => _isar.plans.filter().goalIdEqualTo(goalId).deleteAll());
  }

  Future<void> deleteAll() async {
    await _isar.writeTxn(() => _isar.plans.clear());
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  Stream<List<Plan>> watchAll() => _isar.plans.where().watch(fireImmediately: true);

  Stream<List<Plan>> watchByGoalId(String goalId) =>
      _isar.plans.filter().goalIdEqualTo(goalId).watch(fireImmediately: true);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Plan _fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List?)?.cast<String>() ?? <String>[];
    return Plan.create(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'] as String) : null,
      steps: steps,
      status: PlanStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PlanStatus.draft,
      ),
    );
  }

  Future<void> _writeToIsar(Plan plan) async {
    await _isar.writeTxn(() => _isar.plans.put(plan));
  }

  Future<void> _syncToIsar(List<Plan> plans) async {
    await _isar.writeTxn(() async {
      for (final p in plans) {
        await _isar.plans.put(p);
      }
    });
  }
}
