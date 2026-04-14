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

  const Goal._({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.targetDate,
    required this.status,
    required this.type,
  });

  Goal.create({
    String? id,
    required String title,
    required String description,
    DateTime? createdAt,
    DateTime? targetDate,
    GoalStatus status = GoalStatus.notStarted,
    required GoalType type,
  }) : this._(
         id: id ?? const Uuid().v4(),
         title: title,
         description: description,
         createdAt: createdAt ?? DateTime.now(),
         targetDate: targetDate,
         status: status,
         type: type,
       );

  Goal copyWith({
    String? title,
    String? description,
    DateTime? targetDate,
    bool clearTargetDate = false,
    GoalStatus? status,
    GoalType? type,
  }) {
    return Goal._(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
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
enum GoalStatus { notStarted, inProgress, completed, abandoned }

/// Type of goal — determines which dashboard tab it belongs to
enum GoalType {
  corporate,       // Corp tab — pomodoro-based work
  farm,            // Farm tab — farm side hustle
  appDevelopment,  // App Dev tab — software side hustle
  homeAuto,        // Home & Auto tab — household/vehicle goals
}
