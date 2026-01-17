import 'package:uuid/uuid.dart';

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

  Task({
    String? id,
    required this.title,
    this.description,
    this.scheduledTime,
    this.durationMinutes,
    this.priority = TaskPriority.medium,
    this.completed = false,
    this.planId,
  }) : id = id ?? const Uuid().v4();

  Task copyWith({
    String? title,
    String? description,
    DateTime? scheduledTime,
    int? durationMinutes,
    TaskPriority? priority,
    bool? completed,
    String? planId,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      planId: planId ?? this.planId,
    );
  }

  Task toggleCompleted() {
    return copyWith(completed: !completed);
  }

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
enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

/// Represents a daily planner
class DayPlanner {
  final String id;
  final DateTime date;
  final List<Task> tasks;
  final String? notes;

  DayPlanner({
    String? id,
    required this.date,
    List<Task>? tasks,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        tasks = tasks ?? [];

  DayPlanner copyWith({
    DateTime? date,
    List<Task>? tasks,
    String? notes,
  }) {
    return DayPlanner(
      id: id,
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
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
      tasks: tasks.map((t) => t.id == updatedTask.id ? updatedTask : t).toList(),
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
