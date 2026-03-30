import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../planners/day_planner.dart';
import '../../models/plan.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final DateTime date;
  final String? initialPlanId;
  final int? initialPomodoroBlock;

  const TaskFormScreen({super.key, this.task, required this.date, this.initialPlanId, this.initialPomodoroBlock});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plannerRepository = ServiceLocator.planners;
  final _planRepository = ServiceLocator.plans;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  TimeOfDay? _scheduledTime;
  int? _durationMinutes;
  String? _planId;
  int? _pomodoroBlock;
  List<Plan> _availablePlans = [];

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _planId = widget.initialPlanId;
    _pomodoroBlock = widget.initialPomodoroBlock;
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _priority = widget.task!.priority;
      _planId = widget.task!.planId ?? widget.initialPlanId;
      _durationMinutes = widget.task!.durationMinutes;
      _pomodoroBlock = widget.task!.pomodoroBlock ?? widget.initialPomodoroBlock;
      if (widget.task!.scheduledTime != null) {
        _scheduledTime = TimeOfDay(
          hour: widget.task!.scheduledTime!.hour,
          minute: widget.task!.scheduledTime!.minute,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    final plans = await _planRepository.getActive();
    setState(() {
      _availablePlans = plans;
    });
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _scheduledTime = time;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    DateTime? scheduledDateTime;
    if (_scheduledTime != null) {
      scheduledDateTime = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );
    }

    if (_isEditing) {
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _priority,
        scheduledTime: scheduledDateTime,
        durationMinutes: _durationMinutes,
        planId: _planId,
        pomodoroBlock: _pomodoroBlock,
        clearPomodoroBlock: _pomodoroBlock == null,
      );
      await _plannerRepository.updateTask(widget.date, updatedTask);
    } else {
      final newTask = Task.create(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _priority,
        scheduledTime: scheduledDateTime,
        durationMinutes: _durationMinutes,
        planId: _planId,
        pomodoroBlock: _pomodoroBlock,
      );
      await _plannerRepository.addTask(widget.date, newTask);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter task description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Text(
                'Priority',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: const [
                  ButtonSegment(
                    value: TaskPriority.low,
                    label: Text('Low'),
                  ),
                  ButtonSegment(
                    value: TaskPriority.medium,
                    label: Text('Medium'),
                  ),
                  ButtonSegment(
                    value: TaskPriority.high,
                    label: Text('High'),
                  ),
                  ButtonSegment(
                    value: TaskPriority.urgent,
                    label: Text('Urgent'),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (selection) {
                  setState(() {
                    _priority = selection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Schedule',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: _selectTime,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _scheduledTime != null
                                        ? _formatTime(_scheduledTime!)
                                        : 'Select',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButton<int?>(
                              value: _durationMinutes,
                              isExpanded: true,
                              underline: const SizedBox(),
                              hint: const Text('Select'),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('None'),
                                ),
                                DropdownMenuItem(
                                  value: 15,
                                  child: Text('15 min'),
                                ),
                                DropdownMenuItem(
                                  value: 30,
                                  child: Text('30 min'),
                                ),
                                DropdownMenuItem(
                                  value: 45,
                                  child: Text('45 min'),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text('1 hour'),
                                ),
                                DropdownMenuItem(
                                  value: 90,
                                  child: Text('1.5 hours'),
                                ),
                                DropdownMenuItem(
                                  value: 120,
                                  child: Text('2 hours'),
                                ),
                                DropdownMenuItem(
                                  value: 180,
                                  child: Text('3 hours'),
                                ),
                                DropdownMenuItem(
                                  value: 240,
                                  child: Text('4 hours'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _durationMinutes = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_scheduledTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _scheduledTime = null;
                      });
                    },
                    child: const Text('Clear Time'),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Pomodoro Block (optional)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('None'),
                    selected: _pomodoroBlock == null,
                    onSelected: (_) => setState(() => _pomodoroBlock = null),
                  ),
                  for (int i = 1; i <= 4; i++)
                    ChoiceChip(
                      label: Text('Block $i'),
                      selected: _pomodoroBlock == i,
                      onSelected: (_) => setState(() => _pomodoroBlock = i),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Link to Plan (optional)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _planId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a plan',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._availablePlans.map((plan) => DropdownMenuItem(
                        value: plan.id,
                        child: Text(plan.title),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _planId = value;
                  });
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveTask,
                  child: Text(_isEditing ? 'Save Changes' : 'Create Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
