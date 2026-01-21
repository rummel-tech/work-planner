import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'plan.g.dart';

/// Represents a plan to achieve a goal
@collection
class Plan {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String title;
  late String description;

  @Index()
  late String goalId;

  late DateTime createdAt;
  DateTime? startDate;
  DateTime? endDate;
  late List<String> steps;

  @enumerated
  late PlanStatus status;

  Plan();

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
  }) {
    this.id = id ?? const Uuid().v4();
    this.title = title;
    this.description = description;
    this.goalId = goalId;
    this.createdAt = createdAt ?? DateTime.now();
    this.startDate = startDate;
    this.endDate = endDate;
    this.steps = steps ?? [];
    this.status = status;
  }

  Plan copyWith({
    String? title,
    String? description,
    String? goalId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? steps,
    PlanStatus? status,
  }) {
    final copy = Plan()
      ..isarId = isarId
      ..id = id
      ..title = title ?? this.title
      ..description = description ?? this.description
      ..goalId = goalId ?? this.goalId
      ..createdAt = createdAt
      ..startDate = startDate ?? this.startDate
      ..endDate = endDate ?? this.endDate
      ..steps = steps ?? List<String>.from(this.steps)
      ..status = status ?? this.status;
    return copy;
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
  @ignore
  int get hashCode => id.hashCode;
}

/// Status of a plan
enum PlanStatus {
  draft,
  active,
  completed,
  cancelled,
}
