import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/plan.dart';
import '../planners/day_planner.dart';

// ---------------------------------------------------------------------------
// GoalType extensions
// ---------------------------------------------------------------------------

extension GoalTypeUI on GoalType {
  String get label {
    switch (this) {
      case GoalType.corporate:
        return 'Corporate';
      case GoalType.farm:
        return 'Farm';
      case GoalType.appDevelopment:
        return 'App Dev';
      case GoalType.homeAuto:
        return 'Home & Auto';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalType.corporate:
        return Icons.business;
      case GoalType.farm:
        return Icons.agriculture;
      case GoalType.appDevelopment:
        return Icons.code;
      case GoalType.homeAuto:
        return Icons.home;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case GoalType.corporate:
        return Theme.of(context).colorScheme.primary;
      case GoalType.farm:
        return Colors.green.shade700;
      case GoalType.appDevelopment:
        return Colors.orange.shade700;
      case GoalType.homeAuto:
        return Colors.purple.shade600;
    }
  }
}

// ---------------------------------------------------------------------------
// GoalStatus extensions
// ---------------------------------------------------------------------------

extension GoalStatusUI on GoalStatus {
  String get label {
    switch (this) {
      case GoalStatus.notStarted:
        return 'Not Started';
      case GoalStatus.inProgress:
        return 'In Progress';
      case GoalStatus.completed:
        return 'Completed';
      case GoalStatus.abandoned:
        return 'Abandoned';
    }
  }

  Color get color {
    switch (this) {
      case GoalStatus.notStarted:
        return Colors.grey;
      case GoalStatus.inProgress:
        return Colors.blue;
      case GoalStatus.completed:
        return Colors.green;
      case GoalStatus.abandoned:
        return Colors.red;
    }
  }

  /// Status dot color used in compact goal cards.
  Color statusDotColor(BuildContext context) {
    switch (this) {
      case GoalStatus.inProgress:
        return Colors.green;
      case GoalStatus.notStarted:
        return Theme.of(context).colorScheme.outline;
      case GoalStatus.completed:
        return Colors.blue;
      case GoalStatus.abandoned:
        return Colors.red;
    }
  }
}

// ---------------------------------------------------------------------------
// PlanStatus extensions
// ---------------------------------------------------------------------------

extension PlanStatusUI on PlanStatus {
  String get label {
    switch (this) {
      case PlanStatus.draft:
        return 'Draft';
      case PlanStatus.active:
        return 'Active';
      case PlanStatus.completed:
        return 'Completed';
      case PlanStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case PlanStatus.draft:
        return Colors.grey;
      case PlanStatus.active:
        return Colors.blue;
      case PlanStatus.completed:
        return Colors.green;
      case PlanStatus.cancelled:
        return Colors.red;
    }
  }
}

// ---------------------------------------------------------------------------
// TaskPriority extensions
// ---------------------------------------------------------------------------

extension TaskPriorityUI on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.grey;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }
}

// ---------------------------------------------------------------------------
// TaskCategory extensions
// ---------------------------------------------------------------------------

extension TaskCategoryUI on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.corporate:
        return 'Corporate';
      case TaskCategory.farm:
        return 'Farm';
      case TaskCategory.appDevelopment:
        return 'App Dev';
    }
  }
}
