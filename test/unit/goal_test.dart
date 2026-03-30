import 'package:artemis_work_planner/src/models/goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Goal', () {
    group('Goal.create', () {
      test('generates a UUID id when none is provided', () {
        final g = Goal.create(
          title: 'Test', description: 'Desc', type: GoalType.corporate);
        expect(g.id, isNotEmpty);
        expect(g.id.length, equals(36)); // UUID v4
      });

      test('uses provided id', () {
        final g = Goal.create(
          id: 'my-id', title: 'Test', description: 'Desc',
          type: GoalType.corporate);
        expect(g.id, equals('my-id'));
      });

      test('defaults status to notStarted', () {
        final g = Goal.create(
          title: 'T', description: 'D', type: GoalType.corporate);
        expect(g.status, equals(GoalStatus.notStarted));
      });

      test('sets createdAt to now when not provided', () {
        final before = DateTime.now();
        final g = Goal.create(
          title: 'T', description: 'D', type: GoalType.entrepreneurial);
        final after = DateTime.now();
        expect(g.createdAt.isAfter(before) || g.createdAt.isAtSameMomentAs(before), isTrue);
        expect(g.createdAt.isBefore(after) || g.createdAt.isAtSameMomentAs(after), isTrue);
      });

      test('stores targetDate as null when not provided', () {
        final g = Goal.create(
          title: 'T', description: 'D', type: GoalType.corporate);
        expect(g.targetDate, isNull);
      });
    });

    group('copyWith', () {
      late Goal base;
      setUp(() {
        base = Goal.create(
          id: 'g1',
          title: 'Original',
          description: 'Desc',
          type: GoalType.corporate,
          status: GoalStatus.notStarted,
        );
      });

      test('preserves id and createdAt', () {
        final copy = base.copyWith(title: 'New');
        expect(copy.id, equals(base.id));
        expect(copy.createdAt, equals(base.createdAt));
      });

      test('updates title', () {
        expect(base.copyWith(title: 'New').title, equals('New'));
      });

      test('updates description', () {
        expect(base.copyWith(description: 'New').description, equals('New'));
      });

      test('updates status', () {
        expect(
          base.copyWith(status: GoalStatus.inProgress).status,
          equals(GoalStatus.inProgress));
      });

      test('updates type', () {
        expect(
          base.copyWith(type: GoalType.entrepreneurial).type,
          equals(GoalType.entrepreneurial));
      });

      test('updates targetDate', () {
        final date = DateTime(2025, 12, 31);
        expect(base.copyWith(targetDate: date).targetDate, equals(date));
      });

      test('unmodified fields retain original values', () {
        final copy = base.copyWith(title: 'New');
        expect(copy.description, equals(base.description));
        expect(copy.type, equals(base.type));
        expect(copy.status, equals(base.status));
      });
    });

    group('equality', () {
      test('two goals with same id are equal', () {
        final a = Goal.create(id: 'same', title: 'A', description: 'D', type: GoalType.corporate);
        final b = Goal.create(id: 'same', title: 'B', description: 'X', type: GoalType.entrepreneurial);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('goals with different ids are not equal', () {
        final a = Goal.create(title: 'A', description: 'D', type: GoalType.corporate);
        final b = Goal.create(title: 'A', description: 'D', type: GoalType.corporate);
        expect(a, isNot(equals(b)));
      });
    });

    group('GoalStatus enum', () {
      test('all cases exist', () {
        expect(GoalStatus.values, containsAll([
          GoalStatus.notStarted,
          GoalStatus.inProgress,
          GoalStatus.completed,
          GoalStatus.abandoned,
        ]));
      });
    });

    group('GoalType enum', () {
      test('all cases exist', () {
        expect(GoalType.values,
            containsAll([GoalType.corporate, GoalType.entrepreneurial]));
      });
    });
  });
}
