import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../navigation/app_router.dart';
import '../../planners/day_planner.dart';
import '../../services/service_locator.dart';
import '../../ui_components/task_tile.dart';
import 'widgets.dart';

// ============================================================================
// Side hustle tab — Farm or App Dev
// ============================================================================

class SideHustleTab extends StatefulWidget {
  final GoalType goalType;
  final TaskCategory taskCategory;
  final List<Goal> goals;
  final Map<String, int> planCounts;
  final DayPlanner? todayPlanner;
  final Future<void> Function() onRefresh;
  final VoidCallback onGoalsTabTap;

  const SideHustleTab({
    super.key,
    required this.goalType,
    required this.taskCategory,
    required this.goals,
    required this.planCounts,
    required this.todayPlanner,
    required this.onRefresh,
    required this.onGoalsTabTap,
  });

  @override
  State<SideHustleTab> createState() => _SideHustleTabState();
}

class _SideHustleTabState extends State<SideHustleTab>
    with AutomaticKeepAliveClientMixin {
  final _plannerRepository = ServiceLocator.planners;

  @override
  bool get wantKeepAlive => true;

  Future<void> _toggleTask(Task task) async {
    await _plannerRepository.updateTask(DateTime.now(), task.toggleCompleted());
    widget.onRefresh();
  }

  Future<void> _deleteTask(Task task) async {
    await _plannerRepository.removeTask(DateTime.now(), task.id);
    widget.onRefresh();
  }

  Future<void> _addTask() async {
    await Navigator.pushNamed(
      context,
      AppRouter.taskForm,
      arguments: {
        'date': DateTime.now(),
        'taskCategory': widget.taskCategory,
      },
    );
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final tasks = (widget.todayPlanner?.tasks ?? [])
        .where((t) => t.effectiveCategory == widget.taskCategory)
        .toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          GoalsRow(
            goals: widget.goals,
            planCounts: widget.planCounts,
            onViewAll: widget.onGoalsTabTap,
            onGoalTap: (goal) async {
              await Navigator.pushNamed(
                context,
                AppRouter.goalDetail,
                arguments: goal,
              );
              widget.onRefresh();
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Tasks",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${tasks.where((t) => t.completed).length}/${tasks.length} done',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 40,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No tasks for today',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...tasks.map(
              (task) => TaskTile(
                task: task,
                onCompletedChanged: (_) => _toggleTask(task),
                onDelete: () => _deleteTask(task),
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRouter.taskForm,
                    arguments: {'task': task, 'date': DateTime.now()},
                  );
                  widget.onRefresh();
                },
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addTask,
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }
}
