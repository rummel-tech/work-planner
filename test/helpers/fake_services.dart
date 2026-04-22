import 'package:artemis_work_planner/src/models/external_task.dart';
import 'package:artemis_work_planner/src/models/goal.dart';
import 'package:artemis_work_planner/src/models/plan.dart';
import 'package:artemis_work_planner/src/planners/day_planner.dart';
import 'package:artemis_work_planner/src/planners/week_planner.dart';
import 'package:artemis_work_planner/src/services/auth_service.dart';
import 'package:artemis_work_planner/src/services/external_task_service.dart';
import 'package:artemis_work_planner/src/services/goal_repository.dart';
import 'package:artemis_work_planner/src/services/plan_repository.dart';
import 'package:artemis_work_planner/src/services/planner_repository.dart';

// ---------------------------------------------------------------------------
// FakeAuthService
// ---------------------------------------------------------------------------

class FakeAuthService extends AuthService {
  bool _authenticated;

  FakeAuthService({bool authenticated = false})
    : _authenticated = authenticated;

  @override
  Future<bool> isAuthenticated() async => _authenticated;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (email == 'test@test.com' && password == 'password123') {
      _authenticated = true;
      return {'status': 'ok'};
    }
    throw const AuthException('Invalid credentials');
  }

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
    String? registrationCode,
  }) async {
    _authenticated = true;
    return {'status': 'registered'};
  }

  @override
  Future<void> logout() async {
    _authenticated = false;
  }

  @override
  Future<String?> getAccessToken() async =>
      _authenticated ? 'fake_token' : null;

  @override
  Future<String?> getRefreshToken() async =>
      _authenticated ? 'fake_refresh' : null;

  @override
  Future<String?> getUserId() async => _authenticated ? 'test-user-id' : null;

  @override
  Future<String?> getEmail() async => _authenticated ? 'test@test.com' : null;
}

// ---------------------------------------------------------------------------
// FakeExternalTaskService
// ---------------------------------------------------------------------------

class FakeExternalTaskService extends ExternalTaskService {
  FakeExternalTaskService() : super(FakeAuthService());

  @override
  Future<List<ExternalTask>> getHomeManagerTasks() async => [];

  @override
  Future<List<ExternalTask>> getVehicleManagerTasks() async => [];

  @override
  Future<List<ExternalTask>> getAll() async => [];
}

// ---------------------------------------------------------------------------
// FakeGoalRepository
// ---------------------------------------------------------------------------

class FakeGoalRepository extends GoalRepository {
  final _data = <String, Goal>{};

  FakeGoalRepository() : super();

  void seed(List<Goal> goals) {
    for (final g in goals) {
      _data[g.id] = g;
    }
  }

  @override
  Future<List<Goal>> getAll() async => _data.values.toList();

  @override
  Future<List<Goal>> getByType(GoalType type) async =>
      _data.values.where((g) => g.type == type).toList();

  @override
  Future<List<Goal>> getByStatus(GoalStatus status) async =>
      _data.values.where((g) => g.status == status).toList();

  @override
  Future<List<Goal>> getActive() async => _data.values
      .where(
        (g) =>
            g.status == GoalStatus.inProgress ||
            g.status == GoalStatus.notStarted,
      )
      .toList();

  @override
  Future<Goal?> getById(String id) async => _data[id];

  @override
  Future<Goal> save(Goal goal) async {
    _data[goal.id] = goal;
    return goal;
  }

  @override
  Future<void> delete(String id) async {
    _data.remove(id);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}

// ---------------------------------------------------------------------------
// FakePlanRepository
// ---------------------------------------------------------------------------

class FakePlanRepository extends PlanRepository {
  final _data = <String, Plan>{};

  FakePlanRepository() : super();

  void seed(List<Plan> plans) {
    for (final p in plans) {
      _data[p.id] = p;
    }
  }

  @override
  Future<List<Plan>> getAll() async => _data.values.toList();

  @override
  Future<List<Plan>> getByGoalId(String goalId) async =>
      _data.values.where((p) => p.goalId == goalId).toList();

  @override
  Future<List<Plan>> getByStatus(PlanStatus status) async =>
      _data.values.where((p) => p.status == status).toList();

  @override
  Future<List<Plan>> getActive() async =>
      _data.values.where((p) => p.status == PlanStatus.active).toList();

  @override
  Future<Plan?> getById(String id) async => _data[id];

  @override
  Future<int> countByGoalId(String goalId) async =>
      _data.values.where((p) => p.goalId == goalId).length;

  @override
  Future<Plan> save(Plan plan) async {
    _data[plan.id] = plan;
    return plan;
  }

  @override
  Future<void> delete(String id) async {
    _data.remove(id);
  }

  @override
  Future<void> deleteByGoalId(String goalId) async {
    _data.removeWhere((_, p) => p.goalId == goalId);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}

// ---------------------------------------------------------------------------
// FakePlannerRepository
// ---------------------------------------------------------------------------

class FakePlannerRepository extends PlannerRepository {
  final _dayPlanners = <String, DayPlanner>{};
  final _weekPlanners = <String, WeekPlanner>{};

  FakePlannerRepository() : super();

  @override
  Future<List<DayPlanner>> getAllDayPlanners() async =>
      _dayPlanners.values.toList();

  @override
  Future<DayPlanner?> getDayPlannerById(String id) async => _dayPlanners[id];

  @override
  Future<DayPlanner?> getDayPlannerByDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    return _dayPlanners.values.cast<DayPlanner?>().firstWhere(
      (dp) => dp?.date == normalized,
      orElse: () => null,
    );
  }

  @override
  Future<List<DayPlanner>> getDayPlannersByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return _dayPlanners.values
        .where((dp) => !dp.date.isBefore(start) && !dp.date.isAfter(end))
        .toList();
  }

  @override
  Future<DayPlanner> getOrCreateDayPlanner(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final existing = _dayPlanners.values.cast<DayPlanner?>().firstWhere(
      (dp) => dp?.date == normalized,
      orElse: () => null,
    );
    if (existing != null) return existing;
    final planner = DayPlanner.create(date: normalized);
    _dayPlanners[planner.id] = planner;
    return planner;
  }

  @override
  Future<void> saveDayPlanner(DayPlanner planner) async {
    _dayPlanners[planner.id] = planner;
  }

  @override
  Future<DayPlanner> updateDayPlannerNotes(DateTime date, String notes) async {
    final planner = await getOrCreateDayPlanner(date);
    final updated = planner.copyWith(notes: notes);
    _dayPlanners[updated.id] = updated;
    return updated;
  }

  @override
  Future<void> deleteDayPlanner(String id) async {
    _dayPlanners.remove(id);
  }

  @override
  Future<DayPlanner> addTask(DateTime date, Task task) async {
    final planner = await getOrCreateDayPlanner(date);
    final updated = planner.addTask(task);
    _dayPlanners[updated.id] = updated;
    return updated;
  }

  @override
  Future<DayPlanner> updateTask(DateTime date, Task updatedTask) async {
    final planner = await getOrCreateDayPlanner(date);
    final updated = planner.updateTask(updatedTask);
    _dayPlanners[updated.id] = updated;
    return updated;
  }

  @override
  Future<DayPlanner> removeTask(DateTime date, String taskId) async {
    final planner = await getOrCreateDayPlanner(date);
    final updated = planner.removeTask(taskId);
    _dayPlanners[updated.id] = updated;
    return updated;
  }

  @override
  Future<WeekPlanner> getOrCreateWeekPlanner(DateTime weekStartDate) async {
    final normalized = DateTime(
      weekStartDate.year,
      weekStartDate.month,
      weekStartDate.day,
    );
    final existing = _weekPlanners.values.cast<WeekPlanner?>().firstWhere(
      (wp) => wp?.weekStartDate == normalized,
      orElse: () => null,
    );
    if (existing != null) return existing;
    final planner = WeekPlanner.create(weekStartDate: normalized);
    _weekPlanners[planner.id] = planner;
    return planner;
  }

  @override
  Future<WeekPlanner> getCurrentWeekPlanner() async {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return getOrCreateWeekPlanner(weekStart);
  }

  @override
  Future<Map<int, DayPlanner>> getDayPlannersForWeek(
    WeekPlanner weekPlanner,
  ) async {
    final result = <int, DayPlanner>{};
    for (final entry in weekPlanner.dailyPlannerEntries) {
      final dp = _dayPlanners[entry.dayPlannerId];
      if (dp != null) result[entry.dayOfWeek] = dp;
    }
    return result;
  }

  @override
  Future<({int totalTasks, int completedTasks, double completionRate})>
  getWeekStats(WeekPlanner weekPlanner) async {
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

  @override
  Future<WeekPlanner> updateWeekPlannerGoals(
    DateTime weekStart,
    List<String> goals,
  ) async {
    final planner = await getOrCreateWeekPlanner(weekStart);
    final updated = planner.copyWith(weeklyGoals: goals);
    _weekPlanners[updated.id] = updated;
    return updated;
  }

  @override
  Future<WeekPlanner> updateWeekPlannerNotes(
    DateTime weekStart,
    String notes,
  ) async {
    final planner = await getOrCreateWeekPlanner(weekStart);
    final updated = planner.copyWith(notes: notes);
    _weekPlanners[updated.id] = updated;
    return updated;
  }

  @override
  Future<List<Task>> getTasksForPlan(String planId) async {
    final tasks = <Task>[];
    for (final dp in _dayPlanners.values) {
      tasks.addAll(dp.tasks.where((t) => t.planId == planId));
    }
    return tasks;
  }
}
