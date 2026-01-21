import 'package:flutter/material.dart';

import '../models/goal.dart';
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

  IconData get _typeIcon {
    switch (goal.type) {
      case GoalType.corporate:
        return Icons.business;
      case GoalType.entrepreneurial:
        return Icons.lightbulb_outline;
    }
  }

  String get _typeLabel {
    switch (goal.type) {
      case GoalType.corporate:
        return 'Corporate';
      case GoalType.entrepreneurial:
        return 'Entrepreneurial';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No target date';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Icon(_typeIcon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    _typeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
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
                    _formatDate(goal.targetDate),
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
