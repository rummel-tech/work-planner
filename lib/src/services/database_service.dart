import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/goal.dart';
import '../models/plan.dart';
import '../planners/day_planner.dart';
import '../planners/week_planner.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  late Isar _isar;
  Isar get isar => _isar;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [GoalSchema, PlanSchema, DayPlannerSchema, WeekPlannerSchema],
      directory: dir.path,
      name: 'artemis_work_planner',
    );
    _initialized = true;
  }

  Future<void> close() async {
    await _isar.close();
    _initialized = false;
  }

  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.clear();
    });
  }
}
