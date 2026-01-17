import 'package:uuid/uuid.dart';

/// Represents a goal in the work planning system
class Goal {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? targetDate;
  final GoalStatus status;
  final GoalType type;

  Goal({
    String? id,
    required this.title,
    required this.description,
    DateTime? createdAt,
    this.targetDate,
    this.status = GoalStatus.notStarted,
    required this.type,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Goal copyWith({
    String? title,
    String? description,
    DateTime? targetDate,
    GoalStatus? status,
    GoalType? type,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      type: type ?? this.type,
    );
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
