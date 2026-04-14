import 'package:artemis_work_planner/src/models/goal.dart';
import 'package:artemis_work_planner/src/planners/day_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';

void main() {
  group('Workflow 4: Offline-First Data Access', () {
    group('GoalRepository (cache layer)', () {
      late FakeGoalRepository repo;

      setUp(() => repo = FakeGoalRepository());

      test('getAll returns empty list when nothing is saved', () async {
        expect(await repo.getAll(), isEmpty);
      });

      test('save persists a goal and getById retrieves it', () async {
        final goal = Goal.create(
          title: 'Cached Goal',
          description: 'Stored locally',
          type: GoalType.corporate,
        );
        await repo.save(goal);
        final found = await repo.getById(goal.id);
        expect(found, isNotNull);
        expect(found!.title, 'Cached Goal');
      });

      test('save updates an existing goal (upsert behaviour)', () async {
        final goal = Goal.create(
          title: 'Original',
          description: 'D',
          type: GoalType.corporate,
        );
        await repo.save(goal);

        final updated = goal.copyWith(
          title: 'Updated',
          status: GoalStatus.inProgress,
        );
        await repo.save(updated);

        final result = await repo.getById(goal.id);
        expect(result!.title, 'Updated');
        expect(result.status, GoalStatus.inProgress);
      });

      test('getByType returns only goals of the requested type', () async {
        repo.seed([
          Goal.create(
            id: 'c1',
            title: 'Corp',
            description: 'D',
            type: GoalType.corporate,
          ),
          Goal.create(
            id: 'e1',
            title: 'Startup',
            description: 'D',
            type: GoalType.farm,
          ),
        ]);
        final corp = await repo.getByType(GoalType.corporate);
        expect(corp, hasLength(1));
        expect(corp.first.type, GoalType.corporate);

        final ent = await repo.getByType(GoalType.farm);
        expect(ent, hasLength(1));
        expect(ent.first.type, GoalType.farm);
      });

      test('getByStatus filters by status correctly', () async {
        repo.seed([
          Goal.create(
            id: 'g1',
            title: 'Active',
            description: 'D',
            type: GoalType.corporate,
            status: GoalStatus.inProgress,
          ),
          Goal.create(
            id: 'g2',
            title: 'Done',
            description: 'D',
            type: GoalType.corporate,
            status: GoalStatus.completed,
          ),
        ]);
        final active = await repo.getByStatus(GoalStatus.inProgress);
        expect(active, hasLength(1));
        expect(active.first.title, 'Active');
      });

      test('getActive returns notStarted and inProgress goals', () async {
        repo.seed([
          Goal.create(
            id: 'g1',
            title: 'NotStarted',
            description: 'D',
            type: GoalType.corporate,
            status: GoalStatus.notStarted,
          ),
          Goal.create(
            id: 'g2',
            title: 'InProgress',
            description: 'D',
            type: GoalType.corporate,
            status: GoalStatus.inProgress,
          ),
          Goal.create(
            id: 'g3',
            title: 'Completed',
            description: 'D',
            type: GoalType.corporate,
            status: GoalStatus.completed,
          ),
          Goal.create(
            id: 'g4',
            title: 'Abandoned',
            description: 'D',
            type: GoalType.corporate,
            status: GoalStatus.abandoned,
          ),
        ]);
        final active = await repo.getActive();
        expect(active, hasLength(2));
        expect(
          active.map((g) => g.title),
          containsAll(['NotStarted', 'InProgress']),
        );
      });

      test('delete removes a goal by id', () async {
        final goal = Goal.create(
          title: 'To Delete',
          description: 'D',
          type: GoalType.corporate,
        );
        await repo.save(goal);
        await repo.delete(goal.id);
        expect(await repo.getById(goal.id), isNull);
        expect(await repo.getAll(), isEmpty);
      });

      test('deleteAll clears every goal', () async {
        repo.seed([
          Goal.create(
            id: 'g1',
            title: 'A',
            description: 'D',
            type: GoalType.corporate,
          ),
          Goal.create(
            id: 'g2',
            title: 'B',
            description: 'D',
            type: GoalType.corporate,
          ),
        ]);
        await repo.deleteAll();
        expect(await repo.getAll(), isEmpty);
      });

      test('getById returns null for unknown id', () async {
        expect(await repo.getById('nonexistent'), isNull);
      });
    });

    group('PlannerRepository (cache layer)', () {
      late FakePlannerRepository repo;
      final testDate = DateTime(2025, 6, 16);

      setUp(() => repo = FakePlannerRepository());

      test('getDayPlannerByDate returns null when not yet created', () async {
        expect(await repo.getDayPlannerByDate(testDate), isNull);
      });

      test('getOrCreateDayPlanner creates a planner for the date', () async {
        final planner = await repo.getOrCreateDayPlanner(testDate);
        expect(planner.date, testDate);
        expect(planner.tasks, isEmpty);
      });

      test('getOrCreateDayPlanner is idempotent', () async {
        final first = await repo.getOrCreateDayPlanner(testDate);
        final second = await repo.getOrCreateDayPlanner(testDate);
        expect(first.id, second.id);
      });

      test('addTask creates planner if missing and stores the task', () async {
        final task = Task.create(title: 'Cached Task');
        await repo.addTask(testDate, task);
        final planner = await repo.getDayPlannerByDate(testDate);
        expect(planner, isNotNull);
        expect(planner!.tasks.first.title, 'Cached Task');
      });

      test('updateTask modifies the task in-place', () async {
        final task = Task.create(title: 'Original Task');
        await repo.addTask(testDate, task);

        final modified = task.copyWith(title: 'Modified Task', completed: true);
        await repo.updateTask(testDate, modified);

        final planner = await repo.getDayPlannerByDate(testDate);
        expect(planner!.tasks.first.title, 'Modified Task');
        expect(planner.tasks.first.completed, isTrue);
      });

      test('removeTask deletes a task from the planner', () async {
        final task = Task.create(title: 'To Remove');
        await repo.addTask(testDate, task);
        await repo.removeTask(testDate, task.id);

        final planner = await repo.getDayPlannerByDate(testDate);
        expect(planner!.tasks, isEmpty);
      });

      test('getTasksForPlan aggregates tasks across multiple days', () async {
        const planId = 'plan-123';
        final day1 = DateTime(2025, 6, 16);
        final day2 = DateTime(2025, 6, 17);
        final day3 = DateTime(2025, 6, 18);

        await repo.addTask(
          day1,
          Task.create(title: 'Mon task', planId: planId),
        );
        await repo.addTask(
          day2,
          Task.create(title: 'Tue task', planId: planId),
        );
        await repo.addTask(
          day3,
          Task.create(title: 'Unlinked task'),
        ); // different plan

        final tasks = await repo.getTasksForPlan(planId);
        expect(tasks, hasLength(2));
        expect(
          tasks.map((t) => t.title),
          containsAll(['Mon task', 'Tue task']),
        );
      });

      test(
        'getTasksForPlan returns empty list when no tasks are linked',
        () async {
          await repo.addTask(testDate, Task.create(title: 'Unrelated'));
          expect(await repo.getTasksForPlan('unknown-plan'), isEmpty);
        },
      );

      test('getDayPlannersByDateRange returns planners in range', () async {
        final d1 = DateTime(2025, 6, 16);
        final d2 = DateTime(2025, 6, 17);
        final d3 = DateTime(2025, 6, 18);
        final d4 = DateTime(2025, 6, 19);

        await repo.getOrCreateDayPlanner(d1);
        await repo.getOrCreateDayPlanner(d2);
        await repo.getOrCreateDayPlanner(d3);
        await repo.getOrCreateDayPlanner(d4);

        final inRange = await repo.getDayPlannersByDateRange(d1, d2);
        expect(inRange, hasLength(2));

        final wider = await repo.getDayPlannersByDateRange(d1, d4);
        expect(wider, hasLength(4));
      });

      test('updateDayPlannerNotes persists notes', () async {
        final updated = await repo.updateDayPlannerNotes(
          testDate,
          'Focus on deep work',
        );
        expect(updated.notes, 'Focus on deep work');
      });
    });
  });
}
