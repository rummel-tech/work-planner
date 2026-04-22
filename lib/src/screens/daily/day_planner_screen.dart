import 'dart:async';
import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../planners/day_planner.dart';
import '../../ui_components/task_tile.dart';
import '../../ui_components/completion_indicator.dart';
import '../../navigation/app_router.dart';

class DayPlannerScreen extends StatefulWidget {
  final DateTime date;

  /// When true, suppresses Scaffold/AppBar/FAB for embedding in a parent shell.
  final bool embedded;

  const DayPlannerScreen({
    super.key,
    required this.date,
    this.embedded = false,
  });

  @override
  State<DayPlannerScreen> createState() => _DayPlannerScreenState();
}

class _DayPlannerScreenState extends State<DayPlannerScreen> {
  final _plannerRepository = ServiceLocator.planners;
  DayPlanner? _planner;
  final _notesController = TextEditingController();
  Timer? _notesDebounce;

  @override
  void initState() {
    super.initState();
    _loadPlanner();
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
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

  void _onNotesChanged(String value) {
    if (_notesDebounce?.isActive ?? false) _notesDebounce!.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 500), () {
      _saveNotes();
    });
  }

  Future<void> _saveNotes() async {
    if (_planner == null) return;
    await _plannerRepository.updateDayPlannerNotes(
      widget.date,
      _notesController.text,
    );
  }

  Future<void> _addTaskToBlock(int? block) async {
    await Navigator.pushNamed(
      context,
      AppRouter.taskForm,
      arguments: {'date': widget.date, 'pomodoroBlock': block},
    );
    _loadPlanner();
  }

  Future<void> _editTask(Task task) async {
    await Navigator.pushNamed(
      context,
      AppRouter.taskForm,
      arguments: {'task': task, 'date': widget.date},
    );
    _loadPlanner();
  }

  String _formatDate() {
    final weekday = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
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

    final content = RefreshIndicator(
      onRefresh: _loadPlanner,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                CompletionIndicator(rate: completionRate, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatDate(), style: theme.textTheme.titleMedium),
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
          for (int block = 1; block <= 4; block++)
            _buildBlock(
              block,
              tasks.where((t) => t.pomodoroBlock == block).toList(),
              theme,
            ),
          _buildUnassignedBlock(
            tasks.where((t) => t.pomodoroBlock == null).toList(),
            theme,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Add notes for this day...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: _onNotesChanged,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Embedded mode: no Scaffold/AppBar/FAB — inline add button at bottom.
    if (widget.embedded) {
      return Column(
        children: [
          Expanded(child: content),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _addTaskToBlock(null),
                icon: const Icon(Icons.add),
                label: const Text('Add Task'),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isToday ? 'Today' : _formatDate())),
      body: content,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTaskToBlock(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBlock(int block, List<Task> blockTasks, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () => _addTaskToBlock(block),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$block',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Block $block',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (blockTasks.isNotEmpty)
                    Text(
                      '${blockTasks.where((t) => t.completed).length}/${blockTasks.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _addTaskToBlock(block),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Add task to Block $block',
                  ),
                ],
              ),
            ),
          ),
          if (blockTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'No tasks — tap + to add',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          else
            ...blockTasks.map(
              (task) => TaskTile(
                task: task,
                onCompletedChanged: (_) => _toggleTaskCompleted(task),
                onDelete: () => _deleteTask(task),
                onTap: () => _editTask(task),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnassignedBlock(List<Task> unassigned, ThemeData theme) {
    if (unassigned.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Unassigned', style: theme.textTheme.titleSmall),
                ),
                Text(
                  '${unassigned.where((t) => t.completed).length}/${unassigned.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          ...unassigned.map(
            (task) => TaskTile(
              task: task,
              onCompletedChanged: (_) => _toggleTaskCompleted(task),
              onDelete: () => _deleteTask(task),
              onTap: () => _editTask(task),
            ),
          ),
        ],
      ),
    );
  }
}
