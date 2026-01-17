import 'package:test/test.dart';
import 'package:artemis_work_planner/artemis_work_planner.dart';

void main() {
  group('WeekPlanner', () {
    late DateTime weekStart;

    setUp(() {
      weekStart = DateTime(2026, 1, 19); // Monday
    });

    test('creates week planner with start date', () {
      final planner = WeekPlanner(weekStartDate: weekStart);

      expect(planner.id, isNotEmpty);
      expect(planner.weekStartDate, weekStart);
      expect(planner.dailyPlanners, isEmpty);
      expect(planner.weeklyGoals, isEmpty);
    });

    test('calculates week end date', () {
      final planner = WeekPlanner(weekStartDate: weekStart);

      final expectedEndDate = weekStart.add(const Duration(days: 6));
      expect(planner.weekEndDate, expectedEndDate);
    });

    test('adds daily planner', () {
      final planner = WeekPlanner(weekStartDate: weekStart);
      final dayPlanner = DayPlanner(date: weekStart);

      final updatedPlanner = planner.addDailyPlanner(0, dayPlanner);

      expect(updatedPlanner.dailyPlanners.length, 1);
      expect(updatedPlanner.dailyPlanners[0], dayPlanner);
    });

    test('throws error for invalid day of week', () {
      final planner = WeekPlanner(weekStartDate: weekStart);
      final dayPlanner = DayPlanner(date: weekStart);

      expect(
        () => planner.addDailyPlanner(-1, dayPlanner),
        throwsArgumentError,
      );

      expect(
        () => planner.addDailyPlanner(7, dayPlanner),
        throwsArgumentError,
      );
    });

    test('removes daily planner', () {
      final dayPlanner = DayPlanner(date: weekStart);
      final planner = WeekPlanner(
        weekStartDate: weekStart,
        dailyPlanners: {0: dayPlanner},
      );

      final updatedPlanner = planner.removeDailyPlanner(0);

      expect(updatedPlanner.dailyPlanners, isEmpty);
    });

    test('gets daily planner by day of week', () {
      final dayPlanner = DayPlanner(date: weekStart);
      final planner = WeekPlanner(
        weekStartDate: weekStart,
        dailyPlanners: {0: dayPlanner},
      );

      final retrieved = planner.getDayPlanner(0);
      expect(retrieved, dayPlanner);

      final nonExistent = planner.getDayPlanner(1);
      expect(nonExistent, isNull);
    });

    test('adds weekly goal', () {
      final planner = WeekPlanner(weekStartDate: weekStart);

      final updated = planner.addWeeklyGoal('Complete project milestone');

      expect(updated.weeklyGoals.length, 1);
      expect(updated.weeklyGoals, contains('Complete project milestone'));
    });

    test('removes weekly goal', () {
      final planner = WeekPlanner(
        weekStartDate: weekStart,
        weeklyGoals: ['Goal 1', 'Goal 2', 'Goal 3'],
      );

      final updated = planner.removeWeeklyGoal('Goal 2');

      expect(updated.weeklyGoals.length, 2);
      expect(updated.weeklyGoals, isNot(contains('Goal 2')));
    });

    test('gets all tasks from all daily planners', () {
      final task1 = Task(title: 'Monday task');
      final task2 = Task(title: 'Tuesday task 1');
      final task3 = Task(title: 'Tuesday task 2');

      final mondayPlanner = DayPlanner(
        date: weekStart,
        tasks: [task1],
      );

      final tuesdayPlanner = DayPlanner(
        date: weekStart.add(const Duration(days: 1)),
        tasks: [task2, task3],
      );

      final planner = WeekPlanner(
        weekStartDate: weekStart,
        dailyPlanners: {
          0: mondayPlanner,
          1: tuesdayPlanner,
        },
      );

      final allTasks = planner.getAllTasks();
      expect(allTasks.length, 3);
      expect(allTasks, contains(task1));
      expect(allTasks, contains(task2));
      expect(allTasks, contains(task3));
    });

    test('calculates total tasks', () {
      final task1 = Task(title: 'Task 1');
      final task2 = Task(title: 'Task 2');
      final task3 = Task(title: 'Task 3');

      final dayPlanner1 = DayPlanner(date: weekStart, tasks: [task1, task2]);
      final dayPlanner2 = DayPlanner(
        date: weekStart.add(const Duration(days: 1)),
        tasks: [task3],
      );

      final planner = WeekPlanner(
        weekStartDate: weekStart,
        dailyPlanners: {0: dayPlanner1, 1: dayPlanner2},
      );

      expect(planner.totalTasks, 3);
    });

    test('calculates completed tasks', () {
      final task1 = Task(title: 'Task 1', completed: true);
      final task2 = Task(title: 'Task 2', completed: false);
      final task3 = Task(title: 'Task 3', completed: true);

      final dayPlanner = DayPlanner(
        date: weekStart,
        tasks: [task1, task2, task3],
      );

      final planner = WeekPlanner(
        weekStartDate: weekStart,
        dailyPlanners: {0: dayPlanner},
      );

      expect(planner.completedTasks, 2);
    });

    test('calculates week completion rate', () {
      final task1 = Task(title: 'Task 1', completed: true);
      final task2 = Task(title: 'Task 2', completed: false);
      final task3 = Task(title: 'Task 3', completed: true);
      final task4 = Task(title: 'Task 4', completed: true);

      final dayPlanner = DayPlanner(
        date: weekStart,
        tasks: [task1, task2, task3, task4],
      );

      final planner = WeekPlanner(
        weekStartDate: weekStart,
        dailyPlanners: {0: dayPlanner},
      );

      expect(planner.weekCompletionRate, 0.75);
    });

    test('completion rate is zero for empty week', () {
      final planner = WeekPlanner(weekStartDate: weekStart);

      expect(planner.weekCompletionRate, 0.0);
    });

    test('stores notes', () {
      final planner = WeekPlanner(
        weekStartDate: weekStart,
        notes: 'Focus on project X this week',
      );

      expect(planner.notes, 'Focus on project X this week');
    });
  });
}
