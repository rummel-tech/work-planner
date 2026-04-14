import 'package:artemis_work_planner/src/planners/week_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final monday = DateTime(2025, 6, 16); // Monday

  group('WeekPlanner', () {
    group('WeekPlanner.create', () {
      test('normalises weekStartDate to midnight', () {
        final wp = WeekPlanner.create(
          weekStartDate: DateTime(2025, 6, 16, 10, 30),
        );
        expect(wp.weekStartDate, equals(DateTime(2025, 6, 16)));
      });

      test('weekEndDate is 6 days after start', () {
        final wp = WeekPlanner.create(weekStartDate: monday);
        expect(wp.weekEndDate, equals(DateTime(2025, 6, 22)));
      });

      test('defaults weeklyGoals to empty', () {
        expect(WeekPlanner.create(weekStartDate: monday).weeklyGoals, isEmpty);
      });

      test('defaults dailyPlannerEntries to empty', () {
        expect(
          WeekPlanner.create(weekStartDate: monday).dailyPlannerEntries,
          isEmpty,
        );
      });
    });

    group('addWeeklyGoal / removeWeeklyGoal', () {
      test('addWeeklyGoal appends goal', () {
        final wp = WeekPlanner.create(weekStartDate: monday);
        expect(
          wp.addWeeklyGoal('Ship feature').weeklyGoals,
          equals(['Ship feature']),
        );
      });

      test('addWeeklyGoal does not mutate original', () {
        final wp = WeekPlanner.create(weekStartDate: monday);
        wp.addWeeklyGoal('Goal');
        expect(wp.weeklyGoals, isEmpty);
      });

      test('removeWeeklyGoal removes matching goal', () {
        final wp = WeekPlanner.create(
          weekStartDate: monday,
        ).addWeeklyGoal('a').addWeeklyGoal('b');
        expect(wp.removeWeeklyGoal('a').weeklyGoals, equals(['b']));
      });

      test('goals can be chained', () {
        final wp = WeekPlanner.create(
          weekStartDate: monday,
        ).addWeeklyGoal('x').addWeeklyGoal('y').removeWeeklyGoal('x');
        expect(wp.weeklyGoals, equals(['y']));
      });
    });

    group(
      'addDailyPlannerEntry / removeDailyPlannerEntry / getDayPlannerId',
      () {
        test('addDailyPlannerEntry stores entry for given day', () {
          final wp = WeekPlanner.create(
            weekStartDate: monday,
          ).addDailyPlannerEntry(0, 'dp-id');
          expect(wp.getDayPlannerId(0), equals('dp-id'));
        });

        test('addDailyPlannerEntry replaces existing entry for same day', () {
          final wp = WeekPlanner.create(
            weekStartDate: monday,
          ).addDailyPlannerEntry(0, 'old').addDailyPlannerEntry(0, 'new');
          expect(wp.getDayPlannerId(0), equals('new'));
          expect(wp.dailyPlannerEntries.length, equals(1));
        });

        test('removeDailyPlannerEntry removes entry', () {
          final wp = WeekPlanner.create(
            weekStartDate: monday,
          ).addDailyPlannerEntry(1, 'dp-id');
          expect(wp.removeDailyPlannerEntry(1).getDayPlannerId(1), isNull);
        });

        test('getDayPlannerId returns null for unset day', () {
          expect(
            WeekPlanner.create(weekStartDate: monday).getDayPlannerId(3),
            isNull,
          );
        });

        test('throws ArgumentError for out-of-range dayOfWeek', () {
          final wp = WeekPlanner.create(weekStartDate: monday);
          expect(() => wp.addDailyPlannerEntry(-1, 'id'), throwsArgumentError);
          expect(() => wp.addDailyPlannerEntry(7, 'id'), throwsArgumentError);
        });
      },
    );

    group('copyWith', () {
      test('preserves id and weekStartDate', () {
        final wp = WeekPlanner.create(weekStartDate: monday);
        final copy = wp.copyWith(notes: 'hello');
        expect(copy.id, equals(wp.id));
        expect(copy.weekStartDate, equals(wp.weekStartDate));
      });

      test('updates notes', () {
        expect(
          WeekPlanner.create(
            weekStartDate: monday,
          ).copyWith(notes: 'note').notes,
          equals('note'),
        );
      });

      test('updates weeklyGoals defensively', () {
        final wp = WeekPlanner.create(
          weekStartDate: monday,
          weeklyGoals: ['a'],
        );
        final copy = wp.copyWith(weeklyGoals: ['b']);
        expect(wp.weeklyGoals, equals(['a']));
        expect(copy.weeklyGoals, equals(['b']));
      });
    });

    group('equality', () {
      test('same id means equal', () {
        final a = WeekPlanner.create(
          id: 'same',
          weekStartDate: DateTime(2025, 1, 6),
        );
        final b = WeekPlanner.create(
          id: 'same',
          weekStartDate: DateTime(2025, 2, 3),
        );
        expect(a, equals(b));
      });
    });
  });
}
