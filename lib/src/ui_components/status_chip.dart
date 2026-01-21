import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/plan.dart';

class GoalStatusChip extends StatelessWidget {
  final GoalStatus status;

  const GoalStatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
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

  String get _label {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        _label,
        style: TextStyle(color: _color, fontSize: 12),
      ),
      backgroundColor: _color.withAlpha(30),
      side: BorderSide(color: _color),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class PlanStatusChip extends StatelessWidget {
  final PlanStatus status;

  const PlanStatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
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

  String get _label {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        _label,
        style: TextStyle(color: _color, fontSize: 12),
      ),
      backgroundColor: _color.withAlpha(30),
      side: BorderSide(color: _color),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
