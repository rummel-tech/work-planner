import 'package:isar/isar.dart';

import '../models/plan.dart';
import 'database_service.dart';

class PlanRepository {
  final Isar _isar = DatabaseService.instance.isar;

  Future<List<Plan>> getAll() async {
    return await _isar.plans.where().findAll();
  }

  Future<Plan?> getById(String id) async {
    return await _isar.plans.filter().idEqualTo(id).findFirst();
  }

  Future<List<Plan>> getByGoalId(String goalId) async {
    return await _isar.plans.filter().goalIdEqualTo(goalId).findAll();
  }

  Future<List<Plan>> getByStatus(PlanStatus status) async {
    return await _isar.plans.filter().statusEqualTo(status).findAll();
  }

  Future<List<Plan>> getActive() async {
    return await _isar.plans.filter().statusEqualTo(PlanStatus.active).findAll();
  }

  Future<void> save(Plan plan) async {
    await _isar.writeTxn(() async {
      await _isar.plans.put(plan);
    });
  }

  Future<void> delete(String id) async {
    await _isar.writeTxn(() async {
      await _isar.plans.filter().idEqualTo(id).deleteFirst();
    });
  }

  Future<void> deleteByGoalId(String goalId) async {
    await _isar.writeTxn(() async {
      await _isar.plans.filter().goalIdEqualTo(goalId).deleteAll();
    });
  }

  Future<void> deleteAll() async {
    await _isar.writeTxn(() async {
      await _isar.plans.clear();
    });
  }

  Stream<List<Plan>> watchAll() {
    return _isar.plans.where().watch(fireImmediately: true);
  }

  Stream<List<Plan>> watchByGoalId(String goalId) {
    return _isar.plans
        .filter()
        .goalIdEqualTo(goalId)
        .watch(fireImmediately: true);
  }

  Future<int> countByGoalId(String goalId) async {
    return await _isar.plans.filter().goalIdEqualTo(goalId).count();
  }
}
