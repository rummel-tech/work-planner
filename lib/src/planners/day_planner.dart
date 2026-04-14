import 'package:uuid/uuid.dart';

/// Which work context a task belongs to.
/// null is treated as [TaskCategory.corporate] for backward compatibility.
enum TaskCategory { corporate, farm, appDevelopment }

/// Represents a task in a planner
class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? scheduledTime;
  final int? durationMinutes;
  final TaskPriority priority;
  final bool completed;
  final String? planId;
  final int? pomodoroBlock; // 1–4, only meaningful for corporate tasks
  final TaskCategory? taskCategory; // null == corporate (backward compat)

  const Task._({
    required this.id,
    required this.title,
    this.description,
    this.scheduledTime,
    this.durationMinutes,
    required this.priority,
    required this.completed,
    this.planId,
    this.pomodoroBlock,
    this.taskCategory,
  });

  Task.create({
    String? id,
    required String title,
    String? description,
    DateTime? scheduledTime,
    int? durationMinutes,
    TaskPriority priority = TaskPriority.medium,
    bool completed = false,
    String? planId,
    int? pomodoroBlock,
    TaskCategory? taskCategory,
  }) : this._(
         id: id ?? const Uuid().v4(),
         title: title,
         description: description,
         scheduledTime: scheduledTime,
         durationMinutes: durationMinutes,
         priority: priority,
         completed: completed,
         planId: planId,
         pomodoroBlock: pomodoroBlock,
         taskCategory: taskCategory,
       );

  Task copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? scheduledTime,
    bool clearScheduledTime = false,
    int? durationMinutes,
    bool clearDurationMinutes = false,
    TaskPriority? priority,
    bool? completed,
    String? planId,
    bool clearPlanId = false,
    int? pomodoroBlock,
    bool clearPomodoroBlock = false,
    TaskCategory? taskCategory,
    bool clearTaskCategory = false,
  }) {
    return Task._(
      id: id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      scheduledTime: clearScheduledTime
          ? null
          : (scheduledTime ?? this.scheduledTime),
      durationMinutes: clearDurationMinutes
          ? null
          : (durationMinutes ?? this.durationMinutes),
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      planId: clearPlanId ? null : (planId ?? this.planId),
      pomodoroBlock: clearPomodoroBlock
          ? null
          : (pomodoroBlock ?? this.pomodoroBlock),
      taskCategory: clearTaskCategory
          ? null
          : (taskCategory ?? this.taskCategory),
    );
  }

  Task toggleCompleted() {
    return copyWith(completed: !completed);
  }

  /// Effective category — null stored as corporate for backward compat.
  TaskCategory get effectiveCategory => taskCategory ?? TaskCategory.corporate;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: $priority, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Priority level for a task
enum TaskPriority { low, medium, high, urgent }

/// Represents a daily planner
class DayPlanner {
  final String id;
  final DateTime date;
  final List<Task> tasks;
  final String? notes;

  const DayPlanner._({
    required this.id,
    required this.date,
    required this.tasks,
    this.notes,
  });

  DayPlanner.create({
    String? id,
    required DateTime date,
    List<Task>? tasks,
    String? notes,
  }) : this._(
         id: id ?? const Uuid().v4(),
         date: DateTime(date.year, date.month, date.day),
         tasks: tasks ?? const [],
         notes: notes,
       );

  DayPlanner copyWith({DateTime? date, List<Task>? tasks, String? notes}) {
    return DayPlanner._(
      id: id,
      date: date ?? this.date,
      tasks: tasks ?? List<Task>.from(this.tasks),
      notes: notes ?? this.notes,
    );
  }

  DayPlanner addTask(Task task) {
    return copyWith(tasks: [...tasks, task]);
  }

  DayPlanner removeTask(String taskId) {
    return copyWith(tasks: tasks.where((t) => t.id != taskId).toList());
  }

  DayPlanner updateTask(Task updatedTask) {
    return copyWith(
      tasks: tasks
          .map((t) => t.id == updatedTask.id ? updatedTask : t)
          .toList(),
    );
  }

  List<Task> get completedTasks => tasks.where((t) => t.completed).toList();

  List<Task> get pendingTasks => tasks.where((t) => !t.completed).toList();

  double get completionRate {
    if (tasks.isEmpty) return 0.0;
    return completedTasks.length / tasks.length;
  }

  @override
  String toString() {
    return 'DayPlanner(id: $id, date: ${date.toIso8601String().split('T')[0]}, tasks: ${tasks.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayPlanner && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
