import 'package:test/test.dart';
import 'package:artemis_work_planner/artemis_work_planner.dart';

void main() {
  group('Task', () {
    test('creates task with required fields', () {
      final task = Task(title: 'Complete report');

      expect(task.id, isNotEmpty);
      expect(task.title, 'Complete report');
      expect(task.priority, TaskPriority.medium);
      expect(task.completed, false);
    });

    test('creates task with all fields', () {
      final scheduledTime = DateTime(2026, 1, 20, 9, 0);
      final task = Task(
        title: 'Morning meeting',
        description: 'Team standup',
        scheduledTime: scheduledTime,
        durationMinutes: 30,
        priority: TaskPriority.high,
        planId: 'plan-123',
      );

      expect(task.title, 'Morning meeting');
      expect(task.description, 'Team standup');
      expect(task.scheduledTime, scheduledTime);
      expect(task.durationMinutes, 30);
      expect(task.priority, TaskPriority.high);
      expect(task.planId, 'plan-123');
    });

    test('toggles task completion', () {
      final task = Task(title: 'Write code');

      expect(task.completed, false);

      final completedTask = task.toggleCompleted();
      expect(completedTask.completed, true);

      final uncompletedTask = completedTask.toggleCompleted();
      expect(uncompletedTask.completed, false);
    });

    test('updates task with copyWith', () {
      final task = Task(title: 'Original task');

      final updated = task.copyWith(
        title: 'Updated task',
        priority: TaskPriority.urgent,
      );

      expect(updated.title, 'Updated task');
      expect(updated.priority, TaskPriority.urgent);
      expect(updated.id, task.id);
    });
  });

  group('DayPlanner', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2026, 1, 20);
    });

    test('creates day planner with date', () {
      final planner = DayPlanner(date: testDate);

      expect(planner.id, isNotEmpty);
      expect(planner.date, testDate);
      expect(planner.tasks, isEmpty);
    });

    test('adds task to day planner', () {
      final planner = DayPlanner(date: testDate);
      final task = Task(title: 'Morning workout');

      final updatedPlanner = planner.addTask(task);

      expect(updatedPlanner.tasks.length, 1);
      expect(updatedPlanner.tasks.first.title, 'Morning workout');
    });

    test('removes task from day planner', () {
      final task1 = Task(title: 'Task 1');
      final task2 = Task(title: 'Task 2');
      final planner = DayPlanner(
        date: testDate,
        tasks: [task1, task2],
      );

      final updatedPlanner = planner.removeTask(task1.id);

      expect(updatedPlanner.tasks.length, 1);
      expect(updatedPlanner.tasks.first.title, 'Task 2');
    });

    test('updates task in day planner', () {
      final task = Task(title: 'Original');
      final planner = DayPlanner(date: testDate, tasks: [task]);

      final updatedTask = task.copyWith(title: 'Updated');
      final updatedPlanner = planner.updateTask(updatedTask);

      expect(updatedPlanner.tasks.first.title, 'Updated');
    });

    test('filters completed tasks', () {
      final task1 = Task(title: 'Task 1', completed: true);
      final task2 = Task(title: 'Task 2', completed: false);
      final task3 = Task(title: 'Task 3', completed: true);

      final planner = DayPlanner(
        date: testDate,
        tasks: [task1, task2, task3],
      );

      expect(planner.completedTasks.length, 2);
      expect(planner.completedTasks, contains(task1));
      expect(planner.completedTasks, contains(task3));
    });

    test('filters pending tasks', () {
      final task1 = Task(title: 'Task 1', completed: true);
      final task2 = Task(title: 'Task 2', completed: false);
      final task3 = Task(title: 'Task 3', completed: false);

      final planner = DayPlanner(
        date: testDate,
        tasks: [task1, task2, task3],
      );

      expect(planner.pendingTasks.length, 2);
      expect(planner.pendingTasks, contains(task2));
      expect(planner.pendingTasks, contains(task3));
    });

    test('calculates completion rate', () {
      final task1 = Task(title: 'Task 1', completed: true);
      final task2 = Task(title: 'Task 2', completed: false);
      final task3 = Task(title: 'Task 3', completed: true);
      final task4 = Task(title: 'Task 4', completed: true);

      final planner = DayPlanner(
        date: testDate,
        tasks: [task1, task2, task3, task4],
      );

      expect(planner.completionRate, 0.75);
    });

    test('completion rate is zero for empty planner', () {
      final planner = DayPlanner(date: testDate);

      expect(planner.completionRate, 0.0);
    });

    test('stores notes', () {
      final planner = DayPlanner(
        date: testDate,
        notes: 'Important meetings today',
      );

      expect(planner.notes, 'Important meetings today');
    });
  });
}
