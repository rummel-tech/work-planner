/// A task fetched from an external Artemis module (home-manager, vehicle-manager).
class ExternalTask {
  final String id;
  final String title;
  final String? description;
  final String priority; // low | medium | high | urgent
  final String status;   // open | in_progress | done
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
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
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

  bool get isDone => status == 'done';
}

/// Which external service this task comes from.
enum ExternalTaskSource { homeManager, vehicleManager }
