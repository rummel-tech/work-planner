import 'package:isar/isar.dart';

import '../models/goal.dart';
import 'database_service.dart';

class GoalRepository {
  final Isar _isar = DatabaseService.instance.isar;

  Future<List<Goal>> getAll() async {
    return await _isar.goals.where().findAll();
  }

  Future<Goal?> getById(String id) async {
    return await _isar.goals.filter().idEqualTo(id).findFirst();
  }

  Future<List<Goal>> getByType(GoalType type) async {
    return await _isar.goals.filter().typeEqualTo(type).findAll();
  }

  Future<List<Goal>> getByStatus(GoalStatus status) async {
    return await _isar.goals.filter().statusEqualTo(status).findAll();
  }

  Future<List<Goal>> getActive() async {
    return await _isar.goals
        .filter()
        .statusEqualTo(GoalStatus.inProgress)
        .or()
        .statusEqualTo(GoalStatus.notStarted)
        .findAll();
  }

  Future<void> save(Goal goal) async {
    await _isar.writeTxn(() async {
      await _isar.goals.put(goal);
    });
  }

  Future<void> delete(String id) async {
    await _isar.writeTxn(() async {
      await _isar.goals.filter().idEqualTo(id).deleteFirst();
    });
  }

  Future<void> deleteAll() async {
    await _isar.writeTxn(() async {
      await _isar.goals.clear();
    });
  }

  Stream<List<Goal>> watchAll() {
    return _isar.goals.where().watch(fireImmediately: true);
  }

  Stream<List<Goal>> watchByType(GoalType type) {
    return _isar.goals
        .filter()
        .typeEqualTo(type)
        .watch(fireImmediately: true);
  }
}
