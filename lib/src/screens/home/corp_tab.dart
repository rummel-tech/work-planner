import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../navigation/app_router.dart';
import '../../planners/day_planner.dart';
import '../../services/service_locator.dart';
import '../../ui_components/task_tile.dart';
import 'widgets.dart';

// ============================================================================
// Pomodoro block card
// ============================================================================

class PomodoroBlockCard extends StatelessWidget {
  final int block;
  final List<Task> tasks;
  final VoidCallback onAddTask;
  final Future<void> Function(Task) onToggleTask;
  final Future<void> Function(Task) onEditTask;

  const PomodoroBlockCard({
    super.key,
    required this.block,
    required this.tasks,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onEditTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = tasks.where((t) => t.completed).length;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: const Text('🍅', style: TextStyle(fontSize: 18)),
            title: Text(
              'Block $block',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: tasks.isEmpty
                ? null
                : Text(
                    '$done/${tasks.length} done',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add task to block $block',
              onPressed: onAddTask,
            ),
          ),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'No tasks assigned — tap + to add',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...tasks.map(
              (task) => TaskTile(
                task: task,
                onCompletedChanged: (_) => onToggleTask(task),
                onTap: () => onEditTask(task),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ============================================================================
// Corp tab — pomodoro blocks + corporate goals
// ============================================================================

class CorpTab extends StatefulWidget {
  final List<Goal> goals;
  final Map<String, int> planCounts;
  final DayPlanner? todayPlanner;
  final Future<void> Function() onRefresh;
  final VoidCallback onGoalsTabTap;

  const CorpTab({
    super.key,
    required this.goals,
    required this.planCounts,
    required this.todayPlanner,
    required this.onRefresh,
    required this.onGoalsTabTap,
  });

  @override
  State<CorpTab> createState() => _CorpTabState();
}

class _CorpTabState extends State<CorpTab>
    with AutomaticKeepAliveClientMixin {
  final _plannerRepository = ServiceLocator.planners;

  @override
  bool get wantKeepAlive => true;

  Future<void> _toggleTask(Task task) async {
    await _plannerRepository.updateTask(DateTime.now(), task.toggleCompleted());
    widget.onRefresh();
  }

  Future<void> _addTaskToBlock(int block) async {
    await Navigator.pushNamed(
      context,
      AppRouter.taskForm,
      arguments: {
        'date': DateTime.now(),
        'pomodoroBlock': block,
        'taskCategory': TaskCategory.corporate,
      },
    );
    widget.onRefresh();
  }

  Future<void> _editTask(Task task) async {
    await Navigator.pushNamed(
      context,
      AppRouter.taskForm,
      arguments: {'task': task, 'date': DateTime.now()},
    );
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final corpTasks = (widget.todayPlanner?.tasks ?? [])
        .where((t) => t.effectiveCategory == TaskCategory.corporate)
        .toList();
    final done = corpTasks.where((t) => t.completed).length;

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
                "Today's Pomodoros",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$done/${corpTasks.length} done',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int block = 1; block <= 4; block++) ...[
            PomodoroBlockCard(
              block: block,
              tasks: corpTasks
                  .where((t) => t.pomodoroBlock == block)
                  .toList(),
              onAddTask: () => _addTaskToBlock(block),
              onToggleTask: _toggleTask,
              onEditTask: _editTask,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
