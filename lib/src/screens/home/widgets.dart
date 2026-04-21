import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../navigation/app_router.dart';
import '../../utils/enum_labels.dart';

// ============================================================================
// Compact goal card used in the 3-across goals row
// ============================================================================

class CompactGoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const CompactGoalCard({super.key, required this.goal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = goal.type.color(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(goal.type.icon, size: 14, color: color),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: goal.status.statusDotColor(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                goal.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Goals row — reused in every dashboard tab
// ============================================================================

class GoalsRow extends StatelessWidget {
  final List<Goal> goals;
  final Map<String, int> planCounts;
  final VoidCallback onViewAll;
  final Future<void> Function(Goal) onGoalTap;

  const GoalsRow({
    super.key,
    required this.goals,
    required this.planCounts,
    required this.onViewAll,
    required this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Goals', style: theme.textTheme.titleSmall),
            TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 6),
        if (goals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No active goals',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            children: goals.take(3).map((goal) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CompactGoalCard(
                    goal: goal,
                    onTap: () => onGoalTap(goal),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ============================================================================
// Week progress card
// ============================================================================

class WeekProgressCard extends StatelessWidget {
  final double completionRate;
  final int weeklyGoalCount;
  final VoidCallback onTap;

  const WeekProgressCard({
    super.key,
    required this.completionRate,
    required this.weeklyGoalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: completionRate,
                    strokeWidth: 4,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                  Text(
                    '${(completionRate * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Week Progress', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    weeklyGoalCount > 0
                        ? '$weeklyGoalCount weekly goals'
                        : 'No weekly goals',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
