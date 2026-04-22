import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/plan.dart';
import '../utils/enum_labels.dart';

class GoalStatusChip extends StatelessWidget {
  final GoalStatus status;

  const GoalStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label, style: TextStyle(color: status.color, fontSize: 12)),
      backgroundColor: status.color.withAlpha(30),
      side: BorderSide(color: status.color),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class PlanStatusChip extends StatelessWidget {
  final PlanStatus status;

  const PlanStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label, style: TextStyle(color: status.color, fontSize: 12)),
      backgroundColor: status.color.withAlpha(30),
      side: BorderSide(color: status.color),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
