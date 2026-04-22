import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../models/plan.dart';
import '../../planners/day_planner.dart';
import '../../ui_components/status_chip.dart';
import '../../ui_components/task_tile.dart';
import '../../navigation/app_router.dart';
import '../../utils/enum_labels.dart';
import '../../utils/format_helpers.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  final _planRepository = ServiceLocator.plans;
  final _plannerRepository = ServiceLocator.planners;
  late Plan _plan;
  List<Task> _linkedTasks = [];
  final _stepController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _loadLinkedTasks();
  }

  Future<void> _loadLinkedTasks() async {
    final tasks = await _plannerRepository.getTasksForPlan(_plan.id);
    setState(() {
      _linkedTasks = tasks;
    });
  }

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  Future<void> _refreshPlan() async {
    final plan = await _planRepository.getById(_plan.id);
    if (plan != null) {
      setState(() {
        _plan = plan;
      });
    }
    await _loadLinkedTasks();
  }

  Future<void> _updateStatus(PlanStatus status) async {
    final updated = _plan.copyWith(status: status);
    await _planRepository.save(updated);
    setState(() {
      _plan = updated;
    });
  }

  Future<void> _addStep() async {
    final step = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Step'),
        content: TextField(
          controller: _stepController,
          decoration: const InputDecoration(
            hintText: 'Enter step description',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = _stepController.text.trim();
              _stepController.clear();
              Navigator.pop(context, text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (step != null && step.isNotEmpty) {
      final updated = _plan.addStep(step);
      await _planRepository.save(updated);
      setState(() {
        _plan = updated;
      });
    }
  }

  Future<void> _removeStepAt(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Step'),
        content: const Text('Are you sure you want to remove this step?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updated = _plan.removeStepAt(index);
      await _planRepository.save(updated);
      setState(() {
        _plan = updated;
      });
    }
  }

  Future<void> _deletePlan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text('Are you sure you want to delete this plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _planRepository.delete(_plan.id);
      Navigator.pop(context);
    }
  }

  Future<void> _addTask() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2000),
      lastDate: today.add(const Duration(days: 365 * 5)),
      helpText: 'Select task date',
    );
    if (date == null || !mounted) return;
    await Navigator.pushNamed(
      context,
      AppRouter.taskForm,
      arguments: {'date': date, 'planId': _plan.id},
    );
    _loadLinkedTasks();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                AppRouter.planForm,
                arguments: {'plan': _plan},
              );
              _refreshPlan();
            },
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deletePlan),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPlan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _plan.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          PlanStatusChip(status: _plan.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _plan.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.play_arrow,
                            size: 16,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Start: ${formatDate(_plan.startDate)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.stop,
                            size: 16,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'End: ${formatDate(_plan.endDate)}',
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
              const SizedBox(height: 16),
              Text('Status', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PlanStatus.values.map((status) {
                  final isSelected = _plan.status == status;
                  return ChoiceChip(
                    label: Text(_statusLabel(status)),
                    selected: isSelected,
                    onSelected: (_) => _updateStatus(status),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Steps', style: theme.textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _addStep,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Step'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_plan.steps.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.checklist_outlined,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No steps yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _plan.steps.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final steps = List<String>.from(_plan.steps);
                    final item = steps.removeAt(oldIndex);
                    steps.insert(newIndex, item);
                    final updated = _plan.copyWith(steps: steps);
                    await _planRepository.save(updated);
                    setState(() {
                      _plan = updated;
                    });
                  },
                  itemBuilder: (context, index) {
                    final step = _plan.steps[index];
                    return Card(
                      key: ValueKey('step_$index'),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(step),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeStepAt(index),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Linked Tasks (${_linkedTasks.length})',
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_linkedTasks.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No tasks linked to this plan yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ..._linkedTasks.map((task) => TaskTile(task: task)),
            ],
          ),
        ),
      ),
    );
  }

}
