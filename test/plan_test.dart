import 'package:test/test.dart';
import 'package:artemis_work_planner/artemis_work_planner.dart';

void main() {
  group('Plan', () {
    late Goal testGoal;

    setUp(() {
      testGoal = Goal(
        title: 'Test Goal',
        description: 'A test goal',
        type: GoalType.corporate,
      );
    });

    test('creates plan with required fields', () {
      final plan = Plan(
        title: 'Q1 Marketing Plan',
        description: 'Execute marketing strategy',
        goalId: testGoal.id,
      );

      expect(plan.id, isNotEmpty);
      expect(plan.title, 'Q1 Marketing Plan');
      expect(plan.description, 'Execute marketing strategy');
      expect(plan.goalId, testGoal.id);
      expect(plan.status, PlanStatus.draft);
      expect(plan.steps, isEmpty);
      expect(plan.createdAt, isNotNull);
    });

    test('creates plan with steps', () {
      final plan = Plan(
        title: 'Development Plan',
        description: 'Build the feature',
        goalId: testGoal.id,
        steps: ['Design', 'Implement', 'Test', 'Deploy'],
      );

      expect(plan.steps.length, 4);
      expect(plan.steps, contains('Design'));
    });

    test('creates plan with dates', () {
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 3, 31);

      final plan = Plan(
        title: 'Q1 Plan',
        description: 'First quarter plan',
        goalId: testGoal.id,
        startDate: startDate,
        endDate: endDate,
      );

      expect(plan.startDate, startDate);
      expect(plan.endDate, endDate);
    });

    test('adds step to plan', () {
      final plan = Plan(
        title: 'Test Plan',
        description: 'Testing',
        goalId: testGoal.id,
      );

      final updatedPlan = plan.addStep('New step');

      expect(updatedPlan.steps.length, 1);
      expect(updatedPlan.steps, contains('New step'));
      expect(plan.steps, isEmpty); // Original unchanged
    });

    test('removes step from plan', () {
      final plan = Plan(
        title: 'Test Plan',
        description: 'Testing',
        goalId: testGoal.id,
        steps: ['Step 1', 'Step 2', 'Step 3'],
      );

      final updatedPlan = plan.removeStep('Step 2');

      expect(updatedPlan.steps.length, 2);
      expect(updatedPlan.steps, isNot(contains('Step 2')));
      expect(updatedPlan.steps, contains('Step 1'));
      expect(updatedPlan.steps, contains('Step 3'));
    });

    test('updates plan status with copyWith', () {
      final plan = Plan(
        title: 'Test Plan',
        description: 'Testing',
        goalId: testGoal.id,
      );

      final updatedPlan = plan.copyWith(status: PlanStatus.active);

      expect(updatedPlan.status, PlanStatus.active);
      expect(updatedPlan.id, plan.id);
    });

    test('equality based on id', () {
      final plan1 = Plan(
        id: 'test-id',
        title: 'Plan 1',
        description: 'Description 1',
        goalId: testGoal.id,
      );

      final plan2 = Plan(
        id: 'test-id',
        title: 'Plan 2',
        description: 'Description 2',
        goalId: testGoal.id,
      );

      expect(plan1, equals(plan2));
    });

    test('toString includes important fields', () {
      final plan = Plan(
        title: 'Test Plan',
        description: 'Testing',
        goalId: testGoal.id,
        steps: ['Step 1', 'Step 2'],
      );

      final str = plan.toString();
      expect(str, contains('Test Plan'));
      expect(str, contains('2')); // Number of steps
    });
  });
}
