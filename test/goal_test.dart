import 'package:flutter_test/flutter_test.dart';
import 'package:artemis_work_planner/artemis_work_planner.dart';

void main() {
  group('Goal', () {
    test('creates goal with required fields', () {
      final goal = Goal.create(
        title: 'Launch new product',
        description: 'Launch product by Q2',
        type: GoalType.corporate,
      );

      expect(goal.id, isNotEmpty);
      expect(goal.title, 'Launch new product');
      expect(goal.description, 'Launch product by Q2');
      expect(goal.status, GoalStatus.notStarted);
      expect(goal.type, GoalType.corporate);
      expect(goal.createdAt, isNotNull);
    });

    test('creates farm goal', () {
      final goal = Goal.create(
        title: 'Start side business',
        description: 'Launch consulting service',
        type: GoalType.farm,
      );

      expect(goal.type, GoalType.farm);
    });

    test('creates goal with target date', () {
      final targetDate = DateTime(2026, 6, 30);
      final goal = Goal.create(
        title: 'Complete certification',
        description: 'Get AWS certification',
        type: GoalType.corporate,
        targetDate: targetDate,
      );

      expect(goal.targetDate, targetDate);
    });

    test('updates goal status with copyWith', () {
      final goal = Goal.create(
        title: 'Complete project',
        description: 'Finish the project',
        type: GoalType.corporate,
      );

      final updatedGoal = goal.copyWith(status: GoalStatus.inProgress);

      expect(updatedGoal.status, GoalStatus.inProgress);
      expect(updatedGoal.id, goal.id);
      expect(updatedGoal.title, goal.title);
    });

    test('equality based on id', () {
      final goal1 = Goal.create(
        id: 'test-id',
        title: 'Goal 1',
        description: 'Description 1',
        type: GoalType.corporate,
      );

      final goal2 = Goal.create(
        id: 'test-id',
        title: 'Goal 2',
        description: 'Description 2',
        type: GoalType.corporate,
      );

      expect(goal1, equals(goal2));
    });

    test('toString includes important fields', () {
      final goal = Goal.create(
        title: 'Test Goal',
        description: 'Test',
        type: GoalType.corporate,
      );

      final str = goal.toString();
      expect(str, contains('Test Goal'));
      expect(str, contains('corporate'));
    });
  });
}
