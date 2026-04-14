import 'package:artemis_work_planner/src/planners/day_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Task makeTask({
    String? id,
    String title = 'Task',
    TaskPriority priority = TaskPriority.medium,
    bool completed = false,
    int? pomodoroBlock,
    String? planId,
  }) => Task.create(
    id: id,
    title: title,
    priority: priority,
    completed: completed,
    pomodoroBlock: pomodoroBlock,
    planId: planId,
  );

  group('Task', () {
    group('Task.create', () {
      test('generates a UUID id', () {
        expect(makeTask().id, hasLength(36));
      });

      test('defaults completed to false', () {
        expect(makeTask().completed, isFalse);
      });

      test('defaults priority to medium', () {
        expect(makeTask().priority, equals(TaskPriority.medium));
      });

      test('defaults pomodoroBlock to null', () {
        expect(makeTask().pomodoroBlock, isNull);
      });

      test('stores pomodoroBlock when provided', () {
        expect(makeTask(pomodoroBlock: 2).pomodoroBlock, equals(2));
      });
    });

    group('toggleCompleted', () {
      test('false → true', () {
        expect(makeTask(completed: false).toggleCompleted().completed, isTrue);
      });

      test('true → false', () {
        expect(makeTask(completed: true).toggleCompleted().completed, isFalse);
      });

      test('does not mutate original', () {
        final t = makeTask(completed: false);
        t.toggleCompleted();
        expect(t.completed, isFalse);
      });
    });

    group('copyWith', () {
      test('preserves id', () {
        final t = makeTask(id: 't1');
        expect(t.copyWith(title: 'New').id, equals('t1'));
      });

      test('updates priority', () {
        expect(
          makeTask().copyWith(priority: TaskPriority.urgent).priority,
          equals(TaskPriority.urgent),
        );
      });

      test('updates pomodoroBlock', () {
        expect(makeTask().copyWith(pomodoroBlock: 3).pomodoroBlock, equals(3));
      });

      test('clears pomodoroBlock with clearPomodoroBlock flag', () {
        final t = makeTask(pomodoroBlock: 2);
        expect(t.copyWith(clearPomodoroBlock: true).pomodoroBlock, isNull);
      });

      test('pomodoroBlock stays null when not specified', () {
        expect(makeTask().copyWith(title: 'X').pomodoroBlock, isNull);
      });
    });

    group('equality', () {
      test('same id means equal regardless of other fields', () {
        final a = Task.create(id: 'same', title: 'A');
        final b = Task.create(id: 'same', title: 'B', completed: true);
        expect(a, equals(b));
      });
    });
  });

  group('DayPlanner', () {
    final today = DateTime(2025, 6, 15);

    group('DayPlanner.create', () {
      test('normalises date to midnight', () {
        final dp = DayPlanner.create(date: DateTime(2025, 6, 15, 14, 30));
        expect(dp.date, equals(DateTime(2025, 6, 15)));
      });

      test('defaults tasks to empty list', () {
        expect(DayPlanner.create(date: today).tasks, isEmpty);
      });
    });

    group('addTask / removeTask / updateTask', () {
      test('addTask appends the task', () {
        final dp = DayPlanner.create(date: today);
        final t = makeTask(id: 't1', title: 'First');
        expect(dp.addTask(t).tasks, contains(t));
      });

      test('addTask does not mutate original', () {
        final dp = DayPlanner.create(date: today);
        dp.addTask(makeTask());
        expect(dp.tasks, isEmpty);
      });

      test('removeTask removes by id', () {
        final t = makeTask(id: 'r1');
        final dp = DayPlanner.create(date: today).addTask(t);
        expect(dp.removeTask('r1').tasks, isEmpty);
      });

      test('removeTask leaves other tasks intact', () {
        final a = makeTask(id: 'a');
        final b = makeTask(id: 'b');
        final dp = DayPlanner.create(date: today).addTask(a).addTask(b);
        expect(dp.removeTask('a').tasks, equals([b]));
      });

      test('updateTask replaces the matching task', () {
        final t = makeTask(id: 'u1', title: 'Old');
        final dp = DayPlanner.create(date: today).addTask(t);
        final updated = t.copyWith(title: 'New');
        expect(dp.updateTask(updated).tasks.first.title, equals('New'));
      });

      test('updateTask does not affect tasks with different id', () {
        final a = makeTask(id: 'a', title: 'A');
        final b = makeTask(id: 'b', title: 'B');
        final dp = DayPlanner.create(date: today).addTask(a).addTask(b);
        final updatedA = a.copyWith(title: 'A2');
        final result = dp.updateTask(updatedA);
        expect(result.tasks.firstWhere((t) => t.id == 'b').title, equals('B'));
      });
    });

    group('computed properties', () {
      test('completedTasks returns only completed tasks', () {
        final dp = DayPlanner.create(date: today)
            .addTask(makeTask(id: '1', completed: true))
            .addTask(makeTask(id: '2', completed: false))
            .addTask(makeTask(id: '3', completed: true));
        expect(dp.completedTasks.length, equals(2));
      });

      test('pendingTasks returns only incomplete tasks', () {
        final dp = DayPlanner.create(date: today)
            .addTask(makeTask(id: '1', completed: true))
            .addTask(makeTask(id: '2', completed: false));
        expect(dp.pendingTasks.length, equals(1));
      });

      test('completionRate is 0.0 when no tasks', () {
        expect(DayPlanner.create(date: today).completionRate, equals(0.0));
      });

      test('completionRate is 1.0 when all complete', () {
        final dp = DayPlanner.create(date: today)
            .addTask(makeTask(id: '1', completed: true))
            .addTask(makeTask(id: '2', completed: true));
        expect(dp.completionRate, equals(1.0));
      });

      test('completionRate is 0.5 when half complete', () {
        final dp = DayPlanner.create(date: today)
            .addTask(makeTask(id: '1', completed: true))
            .addTask(makeTask(id: '2', completed: false));
        expect(dp.completionRate, equals(0.5));
      });
    });

    group('pomodoro block grouping', () {
      test('tasks can be filtered by pomodoroBlock', () {
        final dp = DayPlanner.create(date: today)
            .addTask(makeTask(id: '1', pomodoroBlock: 1))
            .addTask(makeTask(id: '2', pomodoroBlock: 2))
            .addTask(makeTask(id: '3', pomodoroBlock: 1))
            .addTask(makeTask(id: '4'));

        final block1 = dp.tasks.where((t) => t.pomodoroBlock == 1).toList();
        final block2 = dp.tasks.where((t) => t.pomodoroBlock == 2).toList();
        final unassigned = dp.tasks
            .where((t) => t.pomodoroBlock == null)
            .toList();

        expect(block1.length, equals(2));
        expect(block2.length, equals(1));
        expect(unassigned.length, equals(1));
      });

      test('reassigning block updates task', () {
        final t = makeTask(id: 't1', pomodoroBlock: 1);
        final dp = DayPlanner.create(date: today).addTask(t);
        final reassigned = t.copyWith(pomodoroBlock: 3);
        final updated = dp.updateTask(reassigned);
        expect(updated.tasks.first.pomodoroBlock, equals(3));
      });
    });
  });

  group('TaskPriority enum', () {
    test('all cases exist', () {
      expect(
        TaskPriority.values,
        containsAll([
          TaskPriority.low,
          TaskPriority.medium,
          TaskPriority.high,
          TaskPriority.urgent,
        ]),
      );
    });
  });
}
