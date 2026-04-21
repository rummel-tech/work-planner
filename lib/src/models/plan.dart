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

  const Plan._({
    required this.id,
    required this.title,
    required this.description,
    required this.goalId,
    required this.createdAt,
    this.startDate,
    this.endDate,
    required this.steps,
    required this.status,
  });

  Plan.create({
    String? id,
    required String title,
    required String description,
    required String goalId,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? steps,
    PlanStatus status = PlanStatus.draft,
  }) : this._(
         id: id ?? const Uuid().v4(),
         title: title,
         description: description,
         goalId: goalId,
         createdAt: createdAt ?? DateTime.now(),
         startDate: startDate,
         endDate: endDate,
         steps: steps ?? const [],
         status: status,
       );

  Plan copyWith({
    String? title,
    String? description,
    String? goalId,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    List<String>? steps,
    PlanStatus? status,
  }) {
    return Plan._(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      goalId: goalId ?? this.goalId,
      createdAt: createdAt,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      steps: steps ?? List<String>.from(this.steps),
      status: status ?? this.status,
    );
  }

  Plan addStep(String step) {
    return copyWith(steps: [...steps, step]);
  }

  Plan removeStepAt(int index) {
    final updated = List<String>.from(steps);
    updated.removeAt(index);
    return copyWith(steps: updated);
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
enum PlanStatus { draft, active, completed, cancelled }
