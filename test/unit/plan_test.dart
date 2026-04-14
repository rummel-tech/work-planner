import 'package:artemis_work_planner/src/models/plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Plan makePlan({
    String? id,
    String title = 'Plan',
    String description = 'Desc',
    String goalId = 'goal-1',
    PlanStatus status = PlanStatus.draft,
    List<String>? steps,
  }) => Plan.create(
    id: id,
    title: title,
    description: description,
    goalId: goalId,
    status: status,
    steps: steps,
  );

  group('Plan', () {
    group('Plan.create', () {
      test('generates a UUID id when none is provided', () {
        final p = makePlan();
        expect(p.id, isNotEmpty);
        expect(p.id.length, equals(36));
      });

      test('defaults status to draft', () {
        expect(makePlan().status, equals(PlanStatus.draft));
      });

      test('defaults steps to empty list', () {
        expect(makePlan().steps, isEmpty);
      });

      test('sets startDate and endDate', () {
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 6, 30);
        final p = Plan.create(
          title: 'T',
          description: 'D',
          goalId: 'g',
          startDate: start,
          endDate: end,
        );
        expect(p.startDate, equals(start));
        expect(p.endDate, equals(end));
      });
    });

    group('copyWith', () {
      test('preserves id, goalId, and createdAt', () {
        final p = makePlan(id: 'p1', goalId: 'g1');
        final copy = p.copyWith(title: 'New');
        expect(copy.id, equals('p1'));
        expect(copy.goalId, equals('g1'));
        expect(copy.createdAt, equals(p.createdAt));
      });

      test('updates status', () {
        expect(
          makePlan().copyWith(status: PlanStatus.active).status,
          equals(PlanStatus.active),
        );
      });

      test('updates steps defensively (new list)', () {
        final p = makePlan(steps: ['a', 'b']);
        final copy = p.copyWith(steps: ['c']);
        expect(p.steps, equals(['a', 'b']));
        expect(copy.steps, equals(['c']));
      });
    });

    group('addStep / removeStep', () {
      test('addStep appends to steps', () {
        final p = makePlan(steps: ['step 1']);
        final updated = p.addStep('step 2');
        expect(updated.steps, equals(['step 1', 'step 2']));
      });

      test('addStep does not mutate original', () {
        final p = makePlan(steps: ['step 1']);
        p.addStep('step 2');
        expect(p.steps, equals(['step 1']));
      });

      test('removeStep removes matching step', () {
        final p = makePlan(steps: ['a', 'b', 'c']);
        expect(p.removeStep('b').steps, equals(['a', 'c']));
      });

      test('removeStep does nothing for non-existent step', () {
        final p = makePlan(steps: ['a']);
        expect(p.removeStep('z').steps, equals(['a']));
      });

      test('steps can be chained', () {
        final p = makePlan()
            .addStep('first')
            .addStep('second')
            .removeStep('first');
        expect(p.steps, equals(['second']));
      });
    });

    group('equality', () {
      test('same id means equal', () {
        final a = Plan.create(
          id: 'same',
          title: 'A',
          description: 'D',
          goalId: 'g',
        );
        final b = Plan.create(
          id: 'same',
          title: 'B',
          description: 'X',
          goalId: 'g2',
        );
        expect(a, equals(b));
      });

      test('different ids means not equal', () {
        final a = makePlan();
        final b = makePlan();
        expect(a, isNot(equals(b)));
      });
    });

    group('PlanStatus enum', () {
      test('all cases exist', () {
        expect(
          PlanStatus.values,
          containsAll([
            PlanStatus.draft,
            PlanStatus.active,
            PlanStatus.completed,
            PlanStatus.cancelled,
          ]),
        );
      });
    });
  });
}
