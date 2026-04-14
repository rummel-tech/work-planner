import 'package:artemis_work_planner/src/models/goal.dart';
import 'package:artemis_work_planner/src/models/plan.dart';
import 'package:artemis_work_planner/src/planners/day_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';

void main() {
  late FakeGoalRepository goalRepo;
  late FakePlanRepository planRepo;
  late FakePlannerRepository plannerRepo;

  final testDate = DateTime(2025, 6, 16); // Monday

  setUp(() {
    goalRepo = FakeGoalRepository();
    planRepo = FakePlanRepository();
    plannerRepo = FakePlannerRepository();
  });

  group('Workflow 1: Goal → Plan → Daily Execution', () {
    test('Step 1: create and retrieve a goal', () async {
      final goal = Goal.create(
        title: 'Launch Product X',
        description: 'Ship v1 by Q3',
        type: GoalType.farm,
      );
      await goalRepo.save(goal);

      final all = await goalRepo.getAll();
      expect(all, hasLength(1));
      expect(all.first.title, 'Launch Product X');
    });

    test('Step 1b: goal defaults to notStarted status', () async {
      final goal = Goal.create(
        title: 'New Goal',
        description: 'Description',
        type: GoalType.corporate,
      );
      await goalRepo.save(goal);

      final found = await goalRepo.getById(goal.id);
      expect(found!.status, GoalStatus.notStarted);
    });

    test('Step 2: create a plan linked to a goal', () async {
      final goal = Goal.create(
        title: 'Corp Goal',
        description: 'Desc',
        type: GoalType.corporate,
      );
      await goalRepo.save(goal);

      final plan = Plan.create(
        title: 'Phase 1 Plan',
        description: 'First phase',
        goalId: goal.id,
        steps: ['Research', 'Design', 'Build'],
        status: PlanStatus.active,
      );
      await planRepo.save(plan);

      final plans = await planRepo.getByGoalId(goal.id);
      expect(plans, hasLength(1));
      expect(plans.first.title, 'Phase 1 Plan');
      expect(plans.first.steps, ['Research', 'Design', 'Build']);
    });

    test('Step 2b: plan status advances from draft to active', () async {
      final plan = Plan.create(
        title: 'Sprint',
        description: 'D',
        goalId: 'g1',
        status: PlanStatus.draft,
      );
      await planRepo.save(plan);

      final activated = plan.copyWith(status: PlanStatus.active);
      await planRepo.save(activated);

      final found = await planRepo.getById(plan.id);
      expect(found!.status, PlanStatus.active);
    });

    test('Step 3: add a task to a day planner', () async {
      final task = Task.create(
        title: 'Team standup',
        priority: TaskPriority.high,
        pomodoroBlock: 1,
      );
      await plannerRepo.addTask(testDate, task);

      final planner = await plannerRepo.getDayPlannerByDate(testDate);
      expect(planner, isNotNull);
      expect(planner!.tasks, hasLength(1));
      expect(planner.tasks.first.title, 'Team standup');
    });

    test(
      'Step 3b: tasks can be assigned to specific pomodoro blocks',
      () async {
        final t1 = Task.create(title: 'Block 1 task', pomodoroBlock: 1);
        final t2 = Task.create(title: 'Block 3 task', pomodoroBlock: 3);
        final t3 = Task.create(title: 'Unassigned task');

        await plannerRepo.addTask(testDate, t1);
        await plannerRepo.addTask(testDate, t2);
        await plannerRepo.addTask(testDate, t3);

        final planner = await plannerRepo.getDayPlannerByDate(testDate);
        expect(planner!.tasks.where((t) => t.pomodoroBlock == 1), hasLength(1));
        expect(planner.tasks.where((t) => t.pomodoroBlock == 3), hasLength(1));
        expect(
          planner.tasks.where((t) => t.pomodoroBlock == null),
          hasLength(1),
        );
      },
    );

    test('Step 4: link a task to a plan via planId', () async {
      final plan = Plan.create(
        title: 'Sprint Plan',
        description: 'Weekly sprint',
        goalId: 'g1',
        status: PlanStatus.active,
      );
      await planRepo.save(plan);

      final task = Task.create(
        title: 'Fix bug #42',
        planId: plan.id,
        pomodoroBlock: 2,
      );
      await plannerRepo.addTask(testDate, task);

      final linkedTasks = await plannerRepo.getTasksForPlan(plan.id);
      expect(linkedTasks, hasLength(1));
      expect(linkedTasks.first.title, 'Fix bug #42');
    });

    test('Step 5: complete a task and verify completion rate', () async {
      final t1 = Task.create(title: 'T1', completed: true);
      final t2 = Task.create(title: 'T2');
      await plannerRepo.addTask(testDate, t1);
      await plannerRepo.addTask(testDate, t2);

      final planner = await plannerRepo.getDayPlannerByDate(testDate);
      expect(planner!.completionRate, 0.5);
      expect(planner.completedTasks, hasLength(1));
      expect(planner.pendingTasks, hasLength(1));
    });

    test(
      'Step 5b: toggleCompleted updates the task in the day planner',
      () async {
        final task = Task.create(title: 'Write tests');
        await plannerRepo.addTask(testDate, task);

        var planner = await plannerRepo.getDayPlannerByDate(testDate);
        expect(planner!.completionRate, 0.0);

        await plannerRepo.updateTask(testDate, task.toggleCompleted());

        planner = await plannerRepo.getDayPlannerByDate(testDate);
        expect(planner!.completionRate, 1.0);
      },
    );

    test('Step 5c: completion rate is 1.0 when all tasks are done', () async {
      final t1 = Task.create(title: 'T1');
      final t2 = Task.create(title: 'T2');
      final t3 = Task.create(title: 'T3');
      await plannerRepo.addTask(testDate, t1);
      await plannerRepo.addTask(testDate, t2);
      await plannerRepo.addTask(testDate, t3);

      await plannerRepo.updateTask(testDate, t1.toggleCompleted());
      await plannerRepo.updateTask(testDate, t2.toggleCompleted());
      await plannerRepo.updateTask(testDate, t3.toggleCompleted());

      final planner = await plannerRepo.getDayPlannerByDate(testDate);
      expect(planner!.completionRate, 1.0);
    });

    test('Step 6: advance goal status to inProgress', () async {
      final goal = Goal.create(
        title: 'My Goal',
        description: 'D',
        type: GoalType.corporate,
      );
      await goalRepo.save(goal);

      final updated = goal.copyWith(status: GoalStatus.inProgress);
      await goalRepo.save(updated);

      final found = await goalRepo.getById(goal.id);
      expect(found!.status, GoalStatus.inProgress);
    });

    test('Step 7: delete goal also removes its linked plans', () async {
      final goal = Goal.create(
        title: 'Temp Goal',
        description: 'D',
        type: GoalType.corporate,
      );
      await goalRepo.save(goal);

      await planRepo.save(
        Plan.create(
          title: 'Plan A',
          description: 'D',
          goalId: goal.id,
          status: PlanStatus.draft,
        ),
      );
      await planRepo.save(
        Plan.create(
          title: 'Plan B',
          description: 'D',
          goalId: goal.id,
          status: PlanStatus.active,
        ),
      );

      expect(await planRepo.getByGoalId(goal.id), hasLength(2));

      await planRepo.deleteByGoalId(goal.id);
      await goalRepo.delete(goal.id);

      expect(await goalRepo.getAll(), isEmpty);
      expect(await planRepo.getByGoalId(goal.id), isEmpty);
    });

    test('full end-to-end: goal -> plan -> tasks -> complete', () async {
      final goal = Goal.create(
        title: 'E2E Goal',
        description: 'Full workflow test',
        type: GoalType.farm,
        status: GoalStatus.inProgress,
      );
      await goalRepo.save(goal);

      final plan = Plan.create(
        title: 'E2E Plan',
        description: 'Execute the workflow',
        goalId: goal.id,
        steps: ['Step A', 'Step B'],
        status: PlanStatus.active,
      );
      await planRepo.save(plan);

      final task1 = Task.create(
        title: 'Work on Step A',
        planId: plan.id,
        pomodoroBlock: 1,
      );
      final task2 = Task.create(
        title: 'Work on Step B',
        planId: plan.id,
        pomodoroBlock: 2,
      );
      await plannerRepo.addTask(testDate, task1);
      await plannerRepo.addTask(testDate, task2);

      await plannerRepo.updateTask(testDate, task1.toggleCompleted());

      final planner = await plannerRepo.getDayPlannerByDate(testDate);
      expect(planner!.completionRate, 0.5);

      final linked = await plannerRepo.getTasksForPlan(plan.id);
      expect(linked, hasLength(2));

      final retrieved = await goalRepo.getById(goal.id);
      expect(retrieved!.status, GoalStatus.inProgress);
    });
  });
}
