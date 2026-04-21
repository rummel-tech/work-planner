/// A task fetched from an external Artemis module (home-manager, vehicle-manager).
class ExternalTask {
  final String id;
  final String title;
  final String? description;
  final ExternalTaskPriority priority;
  final ExternalTaskStatus status;
  final DateTime? dueDate;
  final String category;
  final ExternalTaskSource source;

  const ExternalTask({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.category,
    required this.source,
  });

  factory ExternalTask.fromJson(
    Map<String, dynamic> json,
    ExternalTaskSource source,
  ) {
    return ExternalTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: ExternalTaskPriority.fromString(
        json['priority'] as String? ?? 'medium',
      ),
      status: ExternalTaskStatus.fromString(
        json['status'] as String? ?? 'open',
      ),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      category: json['category'] as String? ?? 'general',
      source: source,
    );
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDone => status == ExternalTaskStatus.done;

  ExternalTask copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    ExternalTaskPriority? priority,
    ExternalTaskStatus? status,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? category,
    ExternalTaskSource? source,
  }) {
    return ExternalTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      category: category ?? this.category,
      source: source ?? this.source,
    );
  }

  @override
  String toString() =>
      'ExternalTask(id: $id, title: $title, source: $source, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExternalTask && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Which external service this task comes from.
enum ExternalTaskSource { homeManager, vehicleManager }

/// Priority of an external task.
enum ExternalTaskPriority {
  low,
  medium,
  high,
  urgent;

  static ExternalTaskPriority fromString(String value) {
    switch (value) {
      case 'low':
        return ExternalTaskPriority.low;
      case 'high':
        return ExternalTaskPriority.high;
      case 'urgent':
        return ExternalTaskPriority.urgent;
      case 'medium':
      default:
        return ExternalTaskPriority.medium;
    }
  }

  String get apiValue => name;
}

/// Status of an external task.
enum ExternalTaskStatus {
  open,
  inProgress,
  done;

  static ExternalTaskStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return ExternalTaskStatus.inProgress;
      case 'done':
        return ExternalTaskStatus.done;
      case 'open':
      default:
        return ExternalTaskStatus.open;
    }
  }

  String get apiValue {
    switch (this) {
      case ExternalTaskStatus.open:
        return 'open';
      case ExternalTaskStatus.inProgress:
        return 'in_progress';
      case ExternalTaskStatus.done:
        return 'done';
    }
  }
}
