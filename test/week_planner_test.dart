import 'package:flutter_test/flutter_test.dart';
import 'package:artemis_work_planner/artemis_work_planner.dart';

void main() {
  group('WeekPlanner', () {
    late DateTime weekStart;

    setUp(() {
      weekStart = DateTime(2026, 1, 19); // Monday
    });

    test('creates week planner with start date', () {
      final planner = WeekPlanner.create(weekStartDate: weekStart);

      expect(planner.id, isNotEmpty);
      expect(planner.weekStartDate.day, weekStart.day);
      expect(planner.weekStartDate.month, weekStart.month);
      expect(planner.weekStartDate.year, weekStart.year);
      expect(planner.dailyPlannerEntries, isEmpty);
      expect(planner.weeklyGoals, isEmpty);
    });

    test('calculates week end date', () {
      final planner = WeekPlanner.create(weekStartDate: weekStart);

      final expectedEndDate = weekStart.add(const Duration(days: 6));
      expect(planner.weekEndDate.day, expectedEndDate.day);
      expect(planner.weekEndDate.month, expectedEndDate.month);
      expect(planner.weekEndDate.year, expectedEndDate.year);
    });

    test('adds daily planner entry', () {
      final planner = WeekPlanner.create(weekStartDate: weekStart);
      final dayPlanner = DayPlanner.create(date: weekStart);

      final updatedPlanner = planner.addDailyPlannerEntry(0, dayPlanner.id);

      expect(updatedPlanner.dailyPlannerEntries.length, 1);
      expect(updatedPlanner.dailyPlannerEntries.first.dayOfWeek, 0);
      expect(updatedPlanner.dailyPlannerEntries.first.dayPlannerId, dayPlanner.id);
    });

    test('throws error for invalid day of week when adding', () {
      final planner = WeekPlanner.create(weekStartDate: weekStart);

      expect(
        () => planner.addDailyPlannerEntry(-1, 'test-id'),
        throwsArgumentError,
      );

      expect(
        () => planner.addDailyPlannerEntry(7, 'test-id'),
        throwsArgumentError,
      );
    });

    test('removes daily planner entry', () {
      final dayPlanner = DayPlanner.create(date: weekStart);
      var planner = WeekPlanner.create(weekStartDate: weekStart);
      planner = planner.addDailyPlannerEntry(0, dayPlanner.id);

      final updatedPlanner = planner.removeDailyPlannerEntry(0);

      expect(updatedPlanner.dailyPlannerEntries, isEmpty);
    });

    test('throws error when removing with invalid day of week', () {
      final planner = WeekPlanner.create(weekStartDate: weekStart);

      expect(
        () => planner.removeDailyPlannerEntry(-1),
        throwsArgumentError,
      );

      expect(
        () => planner.removeDailyPlannerEntry(7),
        throwsArgumentError,
      );
    });

    test('gets daily planner id by day of week', () {
      final dayPlanner = DayPlanner.create(date: weekStart);
      var planner = WeekPlanner.create(weekStartDate: weekStart);
      planner = planner.addDailyPlannerEntry(0, dayPlanner.id);

      final retrievedId = planner.getDayPlannerId(0);
      expect(retrievedId, dayPlanner.id);

      final nonExistent = planner.getDayPlannerId(1);
      expect(nonExistent, isNull);
    });

    test('throws error when getting planner with invalid day of week', () {
      final planner = WeekPlanner.create(weekStartDate: weekStart);

      expect(
        () => planner.getDayPlannerId(-1),
        throwsArgumentError,
      );

      expect(
        () => planner.getDayPlannerId(7),
        throwsArgumentError,
      );
    });

    test('adds weekly goal', () {
      final planner = WeekPlanner.create(weekStartDate: weekStart);

      final updated = planner.addWeeklyGoal('Complete project milestone');

      expect(updated.weeklyGoals.length, 1);
      expect(updated.weeklyGoals, contains('Complete project milestone'));
    });

    test('removes weekly goal', () {
      final planner = WeekPlanner.create(
        weekStartDate: weekStart,
        weeklyGoals: ['Goal 1', 'Goal 2', 'Goal 3'],
      );

      final updated = planner.removeWeeklyGoal('Goal 2');

      expect(updated.weeklyGoals.length, 2);
      expect(updated.weeklyGoals, isNot(contains('Goal 2')));
    });

    test('stores notes', () {
      final planner = WeekPlanner.create(
        weekStartDate: weekStart,
        notes: 'Focus on project X this week',
      );

      expect(planner.notes, 'Focus on project X this week');
    });

    test('replaces existing daily planner entry for same day', () {
      var planner = WeekPlanner.create(weekStartDate: weekStart);
      planner = planner.addDailyPlannerEntry(0, 'first-id');
      planner = planner.addDailyPlannerEntry(0, 'second-id');

      expect(planner.dailyPlannerEntries.length, 1);
      expect(planner.getDayPlannerId(0), 'second-id');
    });
  });
}
