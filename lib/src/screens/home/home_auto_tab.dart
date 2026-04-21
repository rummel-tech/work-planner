import 'package:flutter/material.dart';

import '../../models/external_task.dart';
import '../../models/goal.dart';
import '../../navigation/app_router.dart';
import '../../services/service_locator.dart';
import '../../utils/format_helpers.dart';
import 'widgets.dart';

// ============================================================================
// Home & Auto tab — external tasks + homeAuto goals
// ============================================================================

class HomeAutoTab extends StatefulWidget {
  final List<Goal> goals;
  final Map<String, int> planCounts;
  final Future<void> Function() onRefresh;
  final VoidCallback onGoalsTabTap;

  const HomeAutoTab({
    super.key,
    required this.goals,
    required this.planCounts,
    required this.onRefresh,
    required this.onGoalsTabTap,
  });

  @override
  State<HomeAutoTab> createState() => _HomeAutoTabState();
}

class _HomeAutoTabState extends State<HomeAutoTab>
    with AutomaticKeepAliveClientMixin {
  final _externalTaskService = ServiceLocator.externalTasks;

  List<ExternalTask> _homeTasks = [];
  List<ExternalTask> _vehicleTasks = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadExternalTasks();
  }

  Future<void> _loadExternalTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _externalTaskService.getHomeManagerTasks(),
        _externalTaskService.getVehicleManagerTasks(),
      ]);
      if (!mounted) return;
      setState(() {
        _homeTasks = results[0];
        _vehicleTasks = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadExternalTasks(), widget.onRefresh()]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _refresh,
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
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Could not reach external services. Pull down to retry.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _ExternalTaskSection(
              title: 'Home',
              icon: Icons.home,
              color: Colors.purple.shade600,
              tasks: _homeTasks,
            ),
            const SizedBox(height: 12),
            _ExternalTaskSection(
              title: 'Vehicle',
              icon: Icons.directions_car,
              color: Colors.teal.shade600,
              tasks: _vehicleTasks,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// External task section (Home or Vehicle)
// ============================================================================

class _ExternalTaskSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<ExternalTask> tasks;

  const _ExternalTaskSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
  });

  Color _priorityColor(ExternalTaskPriority priority) {
    switch (priority) {
      case ExternalTaskPriority.urgent:
        return Colors.red;
      case ExternalTaskPriority.high:
        return Colors.orange;
      case ExternalTaskPriority.medium:
        return Colors.amber;
      case ExternalTaskPriority.low:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            Text(
              '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (tasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(
                'No pending tasks',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ...tasks.map((task) {
            final overdue = task.isOverdue;
            return Card(
              child: ListTile(
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  task.title,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: task.dueDate != null
                    ? Text(
                        overdue
                            ? 'Overdue: ${formatDate(task.dueDate)}'
                            : 'Due: ${formatDate(task.dueDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: overdue ? Colors.red : theme.colorScheme.outline,
                        ),
                      )
                    : null,
                trailing: Chip(
                  label: Text(task.category),
                  labelStyle: theme.textTheme.labelSmall,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            );
          }),
      ],
    );
  }
}
