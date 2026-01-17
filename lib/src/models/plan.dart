import 'package:uuid/uuid.dart';

/// Represents a plan to achieve a goal
class Plan {
  final String id;
  final String title;
  final String description;
  final String goalId;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> steps;
  final PlanStatus status;

  Plan({
    String? id,
    required this.title,
    required this.description,
    required this.goalId,
    DateTime? createdAt,
    this.startDate,
    this.endDate,
    List<String>? steps,
    this.status = PlanStatus.draft,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        steps = steps ?? [];

  Plan copyWith({
    String? title,
    String? description,
    String? goalId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? steps,
    PlanStatus? status,
  }) {
    return Plan(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      goalId: goalId ?? this.goalId,
      createdAt: createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      steps: steps ?? this.steps,
      status: status ?? this.status,
    );
  }

  Plan addStep(String step) {
    return copyWith(steps: [...steps, step]);
  }

  Plan removeStep(String step) {
    return copyWith(steps: steps.where((s) => s != step).toList());
  }

  @override
  String toString() {
    return 'Plan(id: $id, title: $title, goalId: $goalId, status: $status, steps: ${steps.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Plan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Status of a plan
enum PlanStatus {
  draft,
  active,
  completed,
  cancelled,
}
