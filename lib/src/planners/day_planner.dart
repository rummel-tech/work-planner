import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'day_planner.g.dart';

/// Represents a task in a planner
@embedded
class Task {
  late String id;
  late String title;
  String? description;
  DateTime? scheduledTime;
  int? durationMinutes;

  @enumerated
  late TaskPriority priority;

  late bool completed;
  String? planId;

  Task();

  Task.create({
    String? id,
    required String title,
    this.description,
    this.scheduledTime,
    this.durationMinutes,
    TaskPriority priority = TaskPriority.medium,
    bool completed = false,
    this.planId,
  }) {
    this.id = id ?? const Uuid().v4();
    this.title = title;
    this.priority = priority;
    this.completed = completed;
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? scheduledTime,
    int? durationMinutes,
    TaskPriority? priority,
    bool? completed,
    String? planId,
  }) {
    final copy = Task()
      ..id = id
      ..title = title ?? this.title
      ..description = description ?? this.description
      ..scheduledTime = scheduledTime ?? this.scheduledTime
      ..durationMinutes = durationMinutes ?? this.durationMinutes
      ..priority = priority ?? this.priority
      ..completed = completed ?? this.completed
      ..planId = planId ?? this.planId;
    return copy;
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
@collection
class DayPlanner {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index()
  late DateTime date;

  late List<Task> tasks;
  String? notes;

  DayPlanner();

  DayPlanner.create({
    String? id,
    required DateTime date,
    List<Task>? tasks,
    this.notes,
  }) {
    this.id = id ?? const Uuid().v4();
    this.date = DateTime(date.year, date.month, date.day);
    this.tasks = tasks ?? [];
  }

  DayPlanner copyWith({
    DateTime? date,
    List<Task>? tasks,
    String? notes,
  }) {
    final copy = DayPlanner()
      ..isarId = isarId
      ..id = id
      ..date = date ?? this.date
      ..tasks = tasks ?? List<Task>.from(this.tasks)
      ..notes = notes ?? this.notes;
    return copy;
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

  @ignore
  List<Task> get completedTasks => tasks.where((t) => t.completed).toList();

  @ignore
  List<Task> get pendingTasks => tasks.where((t) => !t.completed).toList();

  @ignore
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
  @ignore
  int get hashCode => id.hashCode;
}
