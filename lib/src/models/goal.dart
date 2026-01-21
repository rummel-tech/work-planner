import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'goal.g.dart';

/// Represents a goal in the work planning system
@collection
class Goal {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String title;
  late String description;
  late DateTime createdAt;
  DateTime? targetDate;

  @enumerated
  late GoalStatus status;

  @enumerated
  late GoalType type;

  Goal();

  Goal.create({
    String? id,
    required String title,
    required String description,
    DateTime? createdAt,
    DateTime? targetDate,
    GoalStatus status = GoalStatus.notStarted,
    required GoalType type,
  }) {
    this.id = id ?? const Uuid().v4();
    this.title = title;
    this.description = description;
    this.createdAt = createdAt ?? DateTime.now();
    this.targetDate = targetDate;
    this.status = status;
    this.type = type;
  }

  Goal copyWith({
    String? title,
    String? description,
    DateTime? targetDate,
    GoalStatus? status,
    GoalType? type,
  }) {
    final copy = Goal()
      ..isarId = isarId
      ..id = id
      ..title = title ?? this.title
      ..description = description ?? this.description
      ..createdAt = createdAt
      ..targetDate = targetDate ?? this.targetDate
      ..status = status ?? this.status
      ..type = type ?? this.type;
    return copy;
  }

  @override
  String toString() {
    return 'Goal(id: $id, title: $title, status: $status, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Goal && other.id == id;
  }

  @override
  @ignore
  int get hashCode => id.hashCode;
}

/// Status of a goal
enum GoalStatus {
  notStarted,
  inProgress,
  completed,
  abandoned,
}

/// Type of goal (corporate or entrepreneurial)
enum GoalType {
  corporate,
  entrepreneurial,
}
