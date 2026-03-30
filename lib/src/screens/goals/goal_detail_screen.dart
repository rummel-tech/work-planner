import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../models/plan.dart';
import '../../ui_components/plan_card.dart';
import '../../ui_components/status_chip.dart';
import '../../navigation/app_router.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final _goalRepository = ServiceLocator.goals;
  final _planRepository = ServiceLocator.plans;
  late Goal _goal;
  List<Plan> _plans = [];

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await _planRepository.getByGoalId(_goal.id);
    setState(() {
      _plans = plans;
    });
  }

  Future<void> _refreshGoal() async {
    final goal = await _goalRepository.getById(_goal.id);
    if (goal != null) {
      setState(() {
        _goal = goal;
      });
    }
  }

  Future<void> _updateStatus(GoalStatus status) async {
    final updated = _goal.copyWith(status: status);
    await _goalRepository.save(updated);
    setState(() {
      _goal = updated;
    });
  }

  Future<void> _deleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text(
          'Are you sure you want to delete this goal? All associated plans will also be deleted.',
        ),
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
      await _planRepository.deleteByGoalId(_goal.id);
      await _goalRepository.delete(_goal.id);
      Navigator.pop(context);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No target date';
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData get _typeIcon {
    switch (_goal.type) {
      case GoalType.corporate:
        return Icons.business;
      case GoalType.entrepreneurial:
        return Icons.lightbulb_outline;
    }
  }

  String get _typeLabel {
    switch (_goal.type) {
      case GoalType.corporate:
        return 'Corporate';
      case GoalType.entrepreneurial:
        return 'Entrepreneurial';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                AppRouter.goalForm,
                arguments: _goal,
              );
              _refreshGoal();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteGoal,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshGoal();
          await _loadPlans();
        },
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
                          Icon(_typeIcon, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            _typeLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          GoalStatusChip(status: _goal.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _goal.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _goal.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target: ${_formatDate(_goal.targetDate)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Created: ${_formatDate(_goal.createdAt)}',
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
              Text(
                'Status',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: GoalStatus.values.map((status) {
                  final isSelected = _goal.status == status;
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
                  Text(
                    'Plans',
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRouter.planForm,
                        arguments: {'goalId': _goal.id},
                      );
                      _loadPlans();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Plan'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_plans.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.list_alt_outlined,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No plans yet',
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
                ..._plans.map((plan) => PlanCard(
                      plan: plan,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRouter.planDetail,
                          arguments: plan,
                        );
                        _loadPlans();
                      },
                    )),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(GoalStatus status) {
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
}
