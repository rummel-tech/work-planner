import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../planners/day_planner.dart';
import '../../ui_components/task_tile.dart';
import '../../ui_components/completion_indicator.dart';
import '../../navigation/app_router.dart';

class DayPlannerScreen extends StatefulWidget {
  final DateTime date;

  const DayPlannerScreen({super.key, required this.date});

  @override
  State<DayPlannerScreen> createState() => _DayPlannerScreenState();
}

class _DayPlannerScreenState extends State<DayPlannerScreen> {
  final _plannerRepository = ServiceLocator.planners;
  DayPlanner? _planner;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlanner();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPlanner() async {
    final planner = await _plannerRepository.getOrCreateDayPlanner(widget.date);
    setState(() {
      _planner = planner;
      _notesController.text = planner.notes ?? '';
    });
  }

  Future<void> _toggleTaskCompleted(Task task) async {
    if (_planner == null) return;

    final updatedTask = task.toggleCompleted();
    await _plannerRepository.updateTask(widget.date, updatedTask);
    _loadPlanner();
  }

  Future<void> _deleteTask(Task task) async {
    if (_planner == null) return;

    await _plannerRepository.removeTask(widget.date, task.id);
    _loadPlanner();
  }

  Future<void> _saveNotes() async {
    if (_planner == null) return;

    await _plannerRepository.updateDayPlannerNotes(widget.date, _notesController.text);
  }

  String _formatDate() {
    final weekday = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][widget.date.weekday - 1];
    return '$weekday, ${widget.date.month}/${widget.date.day}/${widget.date.year}';
  }

  bool get _isToday {
    final now = DateTime.now();
    return widget.date.day == now.day &&
        widget.date.month == now.month &&
        widget.date.year == now.year;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = _planner?.tasks ?? [];
    final completedCount = _planner?.completedTasks.length ?? 0;
    final completionRate = _planner?.completionRate ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isToday ? 'Today' : _formatDate()),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CompletionIndicator(
                  rate: completionRate,
                  size: 56,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tasks.isEmpty
                            ? 'No tasks'
                            : '$completedCount of ${tasks.length} tasks completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks for this day',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the button below to add a task',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPlanner,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        ...tasks.map((task) => TaskTile(
                              task: task,
                              onCompletedChanged: (_) =>
                                  _toggleTaskCompleted(task),
                              onDelete: () => _deleteTask(task),
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRouter.taskForm,
                                  arguments: {
                                    'task': task,
                                    'date': widget.date,
                                  },
                                );
                                _loadPlanner();
                              },
                            )),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notes',
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _notesController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add notes for this day...',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                  onChanged: (_) => _saveNotes(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(
            context,
            AppRouter.taskForm,
            arguments: {'date': widget.date},
          );
          _loadPlanner();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
