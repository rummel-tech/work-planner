import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../utils/enum_labels.dart';
import '../utils/format_helpers.dart';
import 'status_chip.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final int planCount;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    this.planCount = 0,
    this.onTap,
  });



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = goal.type.color(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(goal.type.icon, size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(
                    goal.type.label,
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                  const Spacer(),
                  GoalStatusChip(status: goal.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                goal.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (goal.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  goal.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    goal.targetDate == null ? 'No target date' : formatDate(goal.targetDate!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.list_alt,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$planCount plans',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
